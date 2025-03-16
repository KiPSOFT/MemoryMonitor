#!/bin/bash

# Memory Monitor build script

echo "Building Memory Monitor..."

# Determine which version to build
if [ "$1" == "advanced" ]; then
    echo "Building advanced version..."
    swiftc -o MemoryMonitor MemoryMonitorAdvanced.swift -framework Cocoa -framework CoreFoundation -framework UserNotifications
else
    echo "Building standard version..."
    swiftc -o MemoryMonitor MemoryMonitor.swift -framework Cocoa -framework CoreFoundation
fi

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Run the application with: ./MemoryMonitor"
else
    echo "Build failed."
fi 