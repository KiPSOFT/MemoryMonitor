#!/bin/bash

# Memory Monitor Uninstall Script

echo "Uninstalling Memory Monitor..."

# Terminate any running instance of the application
echo "Terminating running instances..."
pkill -f MemoryMonitor

# Unload and remove LaunchAgent if it exists
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.memory.monitor.plist"
if [ -f "$LAUNCHD_PLIST" ]; then
    echo "Unloading daemon configuration..."
    launchctl unload "$LAUNCHD_PLIST"
    echo "Removing daemon configuration file..."
    rm "$LAUNCHD_PLIST"
else
    echo "No LaunchAgent configuration found."
fi

# Optionally remove the executable (uncomment if desired)
CURRENT_DIR=$(pwd)
APP_PATH="$CURRENT_DIR/MemoryMonitor"
if [ -f "$APP_PATH" ]; then
    read -p "Do you want to delete the MemoryMonitor executable? (y/n): " CONFIRM
    if [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]]; then
        echo "Removing MemoryMonitor executable..."
        rm "$APP_PATH"
        echo "MemoryMonitor executable removed."
    else
        echo "Keeping MemoryMonitor executable."
    fi
else
    echo "MemoryMonitor executable not found at $APP_PATH"
fi

# Remove any log or temp files
echo "Cleaning up log files..."
rm -f /tmp/memorymonitor.out /tmp/memorymonitor.err

echo "Uninstall complete!"
echo "Memory Monitor has been removed from your system." 