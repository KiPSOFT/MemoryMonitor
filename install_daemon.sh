#!/bin/bash

# Memory Monitor daemon installer script

echo "Building and installing Memory Monitor as a daemon..."

# Build the advanced version
./build.sh advanced

if [ $? -ne 0 ]; then
    echo "Build failed. Cannot install daemon."
    exit 1
fi

# Get the current user's home directory
USER_HOME=$HOME
LAUNCHD_DIR="$USER_HOME/Library/LaunchAgents"

# Create the directory if it doesn't exist
mkdir -p "$LAUNCHD_DIR"

# Copy the plist file to the LaunchAgents directory
CURRENT_DIR=$(pwd)
PLIST_SRC="$CURRENT_DIR/com.memory.monitor.plist"
PLIST_DEST="$LAUNCHD_DIR/com.memory.monitor.plist"

# Update plist with correct path
sed "s|/Users/serkankocaman/Serkan/Depo/Test/memoryMonitor/MemoryMonitor|$CURRENT_DIR/MemoryMonitor|g" "$PLIST_SRC" > "$PLIST_DEST"

echo "Installed plist to $PLIST_DEST"

# Load the daemon
launchctl load "$PLIST_DEST"

if [ $? -eq 0 ]; then
    echo "Memory Monitor daemon installed and started successfully!"
    echo "The application will now run at startup and monitor memory usage."
    echo "To uninstall, run: launchctl unload $PLIST_DEST"
else
    echo "Failed to load daemon."
fi 