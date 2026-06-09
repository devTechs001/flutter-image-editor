#!/bin/bash
# Build Debian package for AI Image Studio
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PACKAGE_NAME="ai-image-studio"
VERSION="2.0.0"
ARCH="amd64"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "Building Debian package for ${PACKAGE_NAME} ${VERSION}..."

# Clean build dir
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/DEBIAN"
mkdir -p "${BUILD_DIR}/usr/bin"
mkdir -p "${BUILD_DIR}/usr/share/applications"
mkdir -p "${BUILD_DIR}/usr/share/icons/hicolor/256x256/apps"
mkdir -p "${BUILD_DIR}/usr/share/${PACKAGE_NAME}"

# Control file
cat > "${BUILD_DIR}/DEBIAN/control" << EOF
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Section: graphics
Priority: optional
Architecture: ${ARCH}
Maintainer: AI Image Studio Team
Description: AI-powered image editor and video maker
 Combines AI-powered image editing, text/image recognition,
 and video generation from prompts.
Depends: libgtk-3-0, liblzma5, libstdc++6, libc6
EOF

# Copy Flutter build
FLUTTER_BUNDLE="${PROJECT_DIR}/build/linux/x64/release/bundle"
if [ -d "$FLUTTER_BUNDLE" ]; then
    cp -r "${FLUTTER_BUNDLE}"/* "${BUILD_DIR}/usr/share/${PACKAGE_NAME}/"
    cat > "${BUILD_DIR}/usr/bin/${PACKAGE_NAME}" << 'EXEC'
#!/bin/bash
exec /usr/share/ai-image-studio/ai_image_editor "$@"
EXEC
    chmod +x "${BUILD_DIR}/usr/bin/${PACKAGE_NAME}"
fi

# Desktop entry
cat > "${BUILD_DIR}/usr/share/applications/ai-image-studio.desktop" << EOF
[Desktop Entry]
Name=AI Image Studio
Comment=AI-powered image editor and video maker
Exec=${PACKAGE_NAME}
Icon=ai-image-studio
Terminal=false
Type=Application
Categories=Graphics;2DGraphics;Photography;
StartupNotify=true
EOF

# Build package
dpkg-deb --build "${BUILD_DIR}" "${PROJECT_DIR}/dist/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

echo "✓ Debian package built: ${PROJECT_DIR}/dist/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
