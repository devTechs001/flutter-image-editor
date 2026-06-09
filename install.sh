#!/bin/bash
# Streamlined one-line install: curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
set -e

echo "Installing AI Image Studio..."

REPO="https://github.com/devTechs001/flutter-image-editor.git"
INSTALL_DIR="${HOME}/.local/share/ai-image-studio"
BIN_DIR="${HOME}/.local/bin"

# Clone or update
if [ -d "$INSTALL_DIR" ]; then
    echo "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull
else
    git clone --depth 1 "$REPO" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Setup backend
echo "Setting up Python backend..."
cd python_backend
python3 -m venv venv 2>/dev/null || python -m venv venv
source venv/bin/activate
pip install -r requirements.txt -q

# Download models
python ai_models/model_downloader.py download --sequential 2>/dev/null || true

# Create launcher script
mkdir -p "$BIN_DIR"
cat > "${BIN_DIR}/ai-image-studio" << 'LAUNCHER'
#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"
cd "${DIR}/../share/ai-image-studio/python_backend"
source venv/bin/activate
python main.py &
python ws_server.py &
wait
LAUNCHER
chmod +x "${BIN_DIR}/ai-image-studio"

echo ""
echo "✓ Installation complete!"
echo ""
echo "Start the backend:  ai-image-studio"
echo "Start the Flutter app: cd ${INSTALL_DIR} && flutter run -d linux"
echo ""
echo "Add ${BIN_DIR} to your PATH if not already."
