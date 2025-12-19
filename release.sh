#!/bin/bash
# VoxelEngine Release Script
# Builds Windows and Linux binaries, packages them with assets

set -e  # Exit on error

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build"
RELEASE_DIR="$PROJECT_ROOT/releases"
VERSION="${1:-dev}"

echo "=== minecraft.cpp Release Builder ==="
echo "Version: $VERSION"
echo ""

# Clean previous builds
rm -rf "$BUILD_DIR"
rm -rf "$RELEASE_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

# =============================================================================
# Build Windows (MinGW cross-compile)
# =============================================================================
echo "[1/4] Building Windows executable..."
mkdir -p "$BUILD_DIR/windows"
cd "$BUILD_DIR/windows"

cmake "$PROJECT_ROOT" \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres \
    -DCMAKE_BUILD_TYPE=Release \
    > /dev/null 2>&1

make -j$(nproc) > /dev/null 2>&1

echo "    Windows build complete"

# =============================================================================
# Build Linux
# =============================================================================
echo "[2/4] Building Linux executable..."
mkdir -p "$BUILD_DIR/linux"
cd "$BUILD_DIR/linux"

cmake "$PROJECT_ROOT" \
    -DCMAKE_BUILD_TYPE=Release \
    > /dev/null 2>&1

make -j$(nproc) > /dev/null 2>&1

echo "    Linux build complete"

# =============================================================================
# Package Windows release
# =============================================================================
echo "[3/4] Packaging Windows release..."
WINDOWS_PKG="$RELEASE_DIR/minecraft.cpp-$VERSION-windows"
mkdir -p "$WINDOWS_PKG"

cp "$BUILD_DIR/windows/bin/MinecraftClone.exe" "$WINDOWS_PKG/"
cp -r "$BUILD_DIR/windows/bin/assets" "$WINDOWS_PKG/"

# Create zip
cd "$RELEASE_DIR"
zip -r "minecraft.cpp-$VERSION-windows.zip" "minecraft.cpp-$VERSION-windows" > /dev/null
rm -rf "$WINDOWS_PKG"

echo "    Created: releases/minecraft.cpp-$VERSION-windows.zip"

# =============================================================================
# Package Linux release
# =============================================================================
echo "[4/4] Packaging Linux release..."
LINUX_PKG="$RELEASE_DIR/minecraft.cpp-$VERSION-linux"
mkdir -p "$LINUX_PKG"

cp "$BUILD_DIR/linux/bin/MinecraftClone" "$LINUX_PKG/"
cp -r "$BUILD_DIR/linux/bin/assets" "$LINUX_PKG/"

# Create tarball
cd "$RELEASE_DIR"
tar -czf "minecraft.cpp-$VERSION-linux.tar.gz" "minecraft.cpp-$VERSION-linux"
rm -rf "$LINUX_PKG"

echo "    Created: releases/minecraft.cpp-$VERSION-linux.tar.gz"

# =============================================================================
# Cleanup
# =============================================================================
rm -rf "$BUILD_DIR"

echo ""
echo "=== Release Complete ==="
echo "Artifacts in: $RELEASE_DIR/"
ls -lh "$RELEASE_DIR/"
