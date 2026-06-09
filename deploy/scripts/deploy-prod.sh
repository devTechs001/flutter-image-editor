#!/bin/bash
# Production deployment script for AI Image Studio
set -e

echo "AI Image Studio - Production Deployment"
echo "========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DEPLOY_DIR="/opt/ai-image-studio"
BACKUP_DIR="/opt/ai-image-studio-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Create user if not exists
if ! id -u ai-image-studio &>/dev/null; then
    echo -e "${YELLOW}Creating ai-image-studio user...${NC}"
    useradd -r -s /bin/false ai-image-studio
fi

# Backup existing installation
if [ -d "$DEPLOY_DIR" ]; then
    echo -e "${YELLOW}Backing up existing installation...${NC}"
    mkdir -p "$BACKUP_DIR"
    cp -r "$DEPLOY_DIR" "${BACKUP_DIR}/ai-image-studio-${TIMESTAMP}"
    echo -e "${GREEN}✓ Backed up to ${BACKUP_DIR}/ai-image-studio-${TIMESTAMP}${NC}"
fi

# Create deploy directory
mkdir -p "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/python_backend"
mkdir -p "$DEPLOY_DIR/python_backend/uploads"
mkdir -p "$DEPLOY_DIR/python_backend/outputs"
mkdir -p "$DEPLOY_DIR/python_backend/temp_video"
mkdir -p "$DEPLOY_DIR/python_backend/models"
mkdir -p "$DEPLOY_DIR/logs"

# Copy backend files
echo -e "${YELLOW}Copying backend files...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cp -r "${PROJECT_DIR}/python_backend/"*.py "$DEPLOY_DIR/python_backend/"
cp -r "${PROJECT_DIR}/python_backend/ai_models" "$DEPLOY_DIR/python_backend/"
cp -r "${PROJECT_DIR}/python_backend/utils" "$DEPLOY_DIR/python_backend/"
cp "${PROJECT_DIR}/python_backend/requirements.txt" "$DEPLOY_DIR/python_backend/"

# Setup Python virtual environment
echo -e "${YELLOW}Setting up Python virtual environment...${NC}"
cd "$DEPLOY_DIR/python_backend"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo -e "${GREEN}✓ Python environment ready${NC}"

# Install systemd services
echo -e "${YELLOW}Installing systemd services...${NC}"
cp "${PROJECT_DIR}/deploy/scripts/ai-image-studio-backend.service" /etc/systemd/system/
cp "${PROJECT_DIR}/deploy/scripts/ai-image-studio-ws.service" /etc/systemd/system/

# Update paths in service files
sed -i "s|/opt/ai-image-studio|${DEPLOY_DIR}|g" /etc/systemd/system/ai-image-studio-backend.service
sed -i "s|/opt/ai-image-studio|${DEPLOY_DIR}|g" /etc/systemd/system/ai-image-studio-ws.service

systemctl daemon-reload

# Set permissions
chown -R ai-image-studio:ai-image-studio "$DEPLOY_DIR"
chmod -R 755 "$DEPLOY_DIR"
chmod -R 775 "$DEPLOY_DIR/python_backend/uploads"
chmod -R 775 "$DEPLOY_DIR/python_backend/outputs"
chmod -R 775 "$DEPLOY_DIR/python_backend/temp_video"

# Start services
echo -e "${YELLOW}Starting services...${NC}"
systemctl enable ai-image-studio-backend.service
systemctl enable ai-image-studio-ws.service
systemctl start ai-image-studio-backend.service
systemctl start ai-image-studio-ws.service

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Deployment complete!                   ║${NC}"
echo -e "${GREEN}║                                         ║${NC}"
echo -e "${GREEN}║  API:      http://localhost:5000         ║${NC}"
echo -e "${GREEN}║  WebSocket: ws://localhost:5001          ║${NC}"
echo -e "${GREEN}║  Logs:     journalctl -u ai-image-studio${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

# Check service status
sleep 2
systemctl status ai-image-studio-backend.service --no-pager
