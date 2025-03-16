#!/bin/bash

# Memory Monitor DMG Creation Script

echo "Creating DMG for Memory Monitor..."

# Build the visual version
./build.sh visual

if [ $? -ne 0 ]; then
    echo "Build failed. Cannot create DMG."
    exit 1
fi

# Create the directory structure
TEMP_DIR="MemoryMonitor_build"
APP_DIR="$TEMP_DIR/MemoryMonitor.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Creating directory structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy the executable
echo "Copying executable..."
cp MemoryMonitor "$MACOS_DIR/"

# Copy the Info.plist
echo "Copying Info.plist..."
cp Info.plist "$CONTENTS_DIR/"

# Create a basic icon (alternatively, you could use a real icon)
echo "Creating icon..."
ICON_PATH="$RESOURCES_DIR/AppIcon.icns"
if [ ! -f "$ICON_PATH" ]; then
    # This is a placeholder - ideally you'd have a proper icon file
    touch "$ICON_PATH"
fi

# Create the DMG
DMG_NAME="MemoryMonitor-$(date +%Y%m%d).dmg"
echo "Creating DMG: $DMG_NAME..."

# Check if create-dmg command is available, if not use hdiutil directly
if command -v create-dmg &> /dev/null; then
    create-dmg \
        --volname "Memory Monitor" \
        --volicon "$ICON_PATH" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "MemoryMonitor.app" 175 190 \
        --hide-extension "MemoryMonitor.app" \
        --app-drop-link 425 190 \
        "$DMG_NAME" \
        "$TEMP_DIR"
else
    # Create a temporary DMG
    TEMP_DMG="temp.dmg"
    hdiutil create -size 10m -fs HFS+ -volname "Memory Monitor" "$TEMP_DMG"
    
    # Mount the DMG
    MOUNT_POINT="/Volumes/Memory Monitor"
    hdiutil attach "$TEMP_DMG"
    
    # Copy the app to the DMG
    cp -R "$APP_DIR" "$MOUNT_POINT/"
    
    # Create a symlink to Applications
    ln -s /Applications "$MOUNT_POINT/Applications"
    
    # Unmount the DMG
    hdiutil detach "$MOUNT_POINT"
    
    # Convert the DMG to compressed format
    hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_NAME"
    
    # Clean up
    rm "$TEMP_DMG"
fi

# Clean up the build directory
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "DMG creation complete: $DMG_NAME"
echo "You can now distribute this DMG file or create a GitHub release with it." 