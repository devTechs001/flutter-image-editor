#!/bin/bash
set -e

echo "╔════════════════════════════════════════╗"
echo "║     AI Image Studio - Backend          ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check Python
PYTHON=""
for cmd in python3 python; do
    if command -v $cmd &> /dev/null; then
        PYTHON=$cmd
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo -e "${RED}✗ Python not found. Please install Python 3.10+${NC}"
    exit 1
fi

echo -e "${BLUE}Using Python: $($PYTHON --version)${NC}"

# Check/Create virtual environment
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    $PYTHON -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
fi

source venv/bin/activate

# Install requirements
if [ ! -f "venv/.installed" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pip install --upgrade pip -q
    pip install -r requirements.txt -q
    touch venv/.installed
    echo -e "${GREEN}✓ Dependencies installed${NC}"
fi

# Create directories
mkdir -p uploads outputs temp_video models

# Download models (optional, background)
echo -e "${YELLOW}Checking AI models...${NC}"
$PYTHON -c "from ai_models.model_downloader import get_model_status; s=get_model_status(); [print(f'  {\"✓\" if v[\"downloaded\"] else \"✗\"} {k}: {v[\"description\"]}') for k,v in s.items()]" 2>/dev/null || true

# Kill any existing processes on ports 5000 and 5001
for port in 5000 5001; do
    pid=$(lsof -ti:$port 2>/dev/null || true)
    if [ -n "$pid" ]; then
        echo -e "${YELLOW}Killing existing process on port $port (PID: $pid)${NC}"
        kill -9 $pid 2>/dev/null || true
    fi
done

# Start services
echo ""
echo -e "${GREEN}Starting services...${NC}"
echo ""

# Start Flask API
echo -e "${BLUE}[1/2] Starting Flask API on port 5000...${NC}"
FLASK_ENV=development $PYTHON main.py &
FLASK_PID=$!
echo -e "${GREEN}  ✓ Flask API started (PID: $FLASK_PID)${NC}"

# Start WebSocket server
echo -e "${BLUE}[2/2] Starting WebSocket server on port 5001...${NC}"
$PYTHON ws_server.py &
WS_PID=$!
echo -e "${GREEN}  ✓ WebSocket server started (PID: $WS_PID)${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    Backend running!                     ║${NC}"
echo -e "${GREEN}║    API:      http://localhost:5000       ║${NC}"
echo -e "${GREEN}║    WebSocket: ws://localhost:5001        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Press Ctrl+C to stop all services."

# Trap to clean up
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down...${NC}"
    kill $FLASK_PID 2>/dev/null || true
    kill $WS_PID 2>/dev/null || true
    wait $FLASK_PID 2>/dev/null || true
    wait $WS_PID 2>/dev/null || true
    echo -e "${GREEN}✓ All services stopped${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Wait for processes
wait
