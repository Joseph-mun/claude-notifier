#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
BUILD_DIR="$SCRIPT_DIR/build"
APP_NAME="ClaudeNotifier"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
INSTALL_DIR="$HOME/.claude/notifier"

echo "=== ClaudeNotifier Build ==="

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Compile
echo "Compiling..."
swiftc -O \
  -o "$BUILD_DIR/$APP_NAME" \
  -framework Cocoa \
  -framework UserNotifications \
  -target arm64-apple-macos14.0 \
  "$SRC_DIR/main.swift"

# Create app bundle
echo "Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$SRC_DIR/Info.plist" "$APP_BUNDLE/Contents/"

# Copy app icon (VS Code icon)
VSCODE_ICON="/Applications/Visual Studio Code.app/Contents/Resources/Code.icns"
if [ -f "$VSCODE_ICON" ]; then
  cp "$VSCODE_ICON" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
  echo "App icon copied"
else
  echo "Warning: VS Code icon not found, skipping"
fi

# Code sign (ad-hoc)
echo "Code signing..."
codesign --force --sign - "$APP_BUNDLE"

# Install
echo "Installing..."
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$APP_BUNDLE" "$INSTALL_DIR/"

# Convenience symlink
ln -sf "$INSTALL_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME" "$HOME/bin/claude-notifier"

echo ""
echo "=== Installed ==="
echo "App:     $INSTALL_DIR/$APP_NAME.app"
echo "CLI:     ~/bin/claude-notifier"
echo ""
echo "Run 'claude-notifier setup' to request notification permissions"
