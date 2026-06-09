#!/bin/bash
set -e

echo "╔════════════════════════════════════════╗"
echo "║     AI Image Studio - Installer        ║"
echo "╚════════════════════════════════════════╝"
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="${HOME}/.ai-image-studio"
SYSTEMD_DIR="${HOME}/.config/systemd/user"

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

echo -e "${BLUE}OS: ${OS}${NC}"
echo -e "${BLUE}Arch: ${ARCH}${NC}"
echo -e "${BLUE}Install dir: ${INSTALL_DIR}${NC}"
echo ""

install_backend() {
    echo -e "${YELLOW}Installing Python backend...${NC}"

    mkdir -p "$INSTALL_DIR"
    cp -r ./* "$INSTALL_DIR/"
    cd "$INSTALL_DIR"

    # Create virtual environment
    $PYTHON -m venv venv
    source venv/bin/activate

    # Install dependencies
    pip install --upgrade pip -q
    pip install -r requirements.txt

    # Download models
    echo -e "${YELLOW}Downloading AI models (this may take a while)...${NC}"
    python ai_models/model_downloader.py download --sequential 2>/dev/null || true

    echo -e "${GREEN}✓ Backend installed to ${INSTALL_DIR}${NC}"
}

install_systemd_service() {
    echo -e "${YELLOW}Installing systemd user service...${NC}"

    mkdir -p "$SYSTEMD_DIR"

    cat > "$SYSTEMD_DIR/ai-image-studio.service" << EOF
[Unit]
Description=AI Image Studio Backend
After=network.target

[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
Environment=PATH=${INSTALL_DIR}/venv/bin:/usr/bin
ExecStart=${INSTALL_DIR}/venv/bin/python ${INSTALL_DIR}/main.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

    cat > "$SYSTEMD_DIR/ai-image-studio-ws.service" << EOF
[Unit]
Description=AI Image Studio WebSocket Server
After=network.target

[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
Environment=PATH=${INSTALL_DIR}/venv/bin:/usr/bin
ExecStart=${INSTALL_DIR}/venv/bin/python ${INSTALL_DIR}/ws_server.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    echo -e "${GREEN}✓ Systemd services installed${NC}"

    echo -e "${YELLOW}Enable services to start on boot? (y/N)${NC}"
    read -r enable
    if [ "$enable" = "y" ] || [ "$enable" = "Y" ]; then
        systemctl --user enable ai-image-studio.service
        systemctl --user enable ai-image-studio-ws.service
        echo -e "${GREEN}✓ Services enabled${NC}"
    fi

    echo -e "${YELLOW}Start services now? (y/N)${NC}"
    read -r start
    if [ "$start" = "y" ] || [ "$start" = "Y" ]; then
        systemctl --user start ai-image-studio.service
        systemctl --user start ai-image-studio-ws.service
        echo -e "${GREEN}✓ Services started${NC}"
    fi
}

install_desktop_entry() {
    echo -e "${YELLOW}Creating desktop entry...${NC}"

    mkdir -p "${HOME}/.local/share/applications"

    cat > "${HOME}/.local/share/applications/ai-image-studio.desktop" << EOF
[Desktop Entry]
Name=AI Image Studio
Comment=AI-powered image editor and video maker
Exec=${INSTALL_DIR}/start.sh
Terminal=true
Type=Application
Categories=Graphics;AudioVideo;
Icon=${INSTALL_DIR}/icon.png
EOF

    echo -e "${GREEN}✓ Desktop entry created${NC}"
}

install_flutter_app() {
    echo -e "${YELLOW}Building Flutter app...${NC}"

    cd "$(dirname "$0")/.."

    if command -v flutter &> /dev/null; then
        flutter pub get
        flutter build linux --release

        echo -e "${YELLOW}Installing Flutter app...${NC}"
        mkdir -p "${HOME}/.local/bin"
        cp -r build/linux/x64/release/bundle/* "${HOME}/.local/bin/ai-image-studio/"

        echo -e "${GREEN}✓ Flutter app installed to ~/.local/bin/ai-image-studio/${NC}"
    else
        echo -e "${RED}✗ Flutter SDK not found. Skipping Flutter app build.${NC}"
        echo "  Install Flutter from https://flutter.dev and run:"
        echo "    cd .. && flutter build linux --release"
    fi
}

# Main installation flow
echo -e "${BLUE}Select installation options:${NC}"
echo "1) Install Python backend only"
echo "2) Install backend + systemd services"
echo "3) Full installation (backend + systemd + Flutter app)"
echo "4) Install backend + desktop entry"
echo ""
echo -n "Choice [1-4]: "
read -r choice

case $choice in
    1)
        install_backend
        ;;
    2)
        install_backend
        install_systemd_service
        ;;
    3)
        install_backend
        install_systemd_service
        install_flutter_app
        ;;
    4)
        install_backend
        install_desktop_entry
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Installation complete!                 ║${NC}"
echo -e "${GREEN}║                                         ║${NC}"
echo -e "${GREEN}║  Start backend:                         ║${NC}"
echo -e "${GREEN}║    cd ${INSTALL_DIR}              ║${NC}"
echo -e "${GREEN}║    ./start.sh                           ║${NC}"
echo -e "${GREEN}║                                         ║${NC}"
echo -e "${GREEN}║  Or via systemd:                        ║${NC}"
echo -e "${GREEN}║    systemctl --user start ai-image-studio${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
