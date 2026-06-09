#!/bin/bash
# Build AppImage for AI Image Studio
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Building AppImage for AI Image Studio..."

# Install appimagetool if not present
if ! command -v appimagetool &> /dev/null; then
    echo "Downloading appimagetool..."
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O /tmp/appimagetool
    chmod +x /tmp/appimagetool
    APPIMAGETOOL="/tmp/appimagetool"
else
    APPIMAGETOOL="appimagetool"
fi

# Create AppDir structure
APPDIR="${SCRIPT_DIR}/AppDir"
mkdir -p "${APPDIR}/usr/bin"
mkdir -p "${APPDIR}/usr/share/applications"
mkdir -p "${APPDIR}/usr/share/icons/hicolor/256x256/apps"

# Copy Flutter bundle
FLUTTER_BUNDLE="${PROJECT_DIR}/build/linux/x64/release/bundle"
if [ -d "$FLUTTER_BUNDLE" ]; then
    cp -r "$FLUTTER_BUNDLE"/* "${APPDIR}/usr/bin/"
else
    echo "Flutter build not found at $FLUTTER_BUNDLE"
    echo "Run 'flutter build linux --release' first"
    exit 1
fi

# Create desktop entry
cat > "${APPDIR}/usr/share/applications/ai-image-studio.desktop" << EOF
[Desktop Entry]
Name=AI Image Studio
Comment=AI-powered image editor and video maker
Exec=ai_image_editor
Icon=ai-image-studio
Terminal=false
Type=Application
Categories=Graphics;2DGraphics;Photography;
StartupNotify=true
EOF

# Create app icon (placeholder text icon)
convert -size 256x256 xc:'#7C6FFF' -fill white -gravity center \
    -pointsize 120 -font Helvetica -annotate 0 "AI" \
    "${APPDIR}/usr/share/icons/hicolor/256x256/apps/ai-image-studio.png" 2>/dev/null || \
    python3 -c "
from PIL import Image, ImageDraw, ImageFont
img = Image.new('RGB', (256, 256), '#7C6FFF')
draw = ImageDraw.Draw(img)
draw.text((128, 128), 'AI', fill='white', anchor='mm')
img.save('${APPDIR}/usr/share/icons/hicolor/256x256/apps/ai-image-studio.png')
" 2>/dev/null || true

# Create AppRun
cat > "${APPDIR}/AppRun" << 'APPRUN'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/ai_image_editor" "$@"
APPRUN
chmod +x "${APPDIR}/AppRun"

# Build AppImage
VERSION="2.0.0"
ARCH="x86_64"
OUTPUT="${PROJECT_DIR}/dist/AI-Image-Studio-${VERSION}-${ARCH}.AppImage"
mkdir -p "${PROJECT_DIR}/dist"

$APPIMAGETOOL "${APPDIR}" "${OUTPUT}"
chmod +x "${OUTPUT}"

echo "✓ AppImage built: ${OUTPUT}"
ls -lh "${OUTPUT}"
