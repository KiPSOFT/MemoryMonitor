# Memory Monitor

A simple macOS menu bar application that displays memory and swap usage.

## Features

- Shows memory usage percentage in the menu bar
- Shows swap usage percentage in the menu bar
- Sends notification when swap usage begins
- Updates automatically every 5 seconds
- Option to manually refresh statistics
- Can run as a daemon at system startup
- Visualization option similar to macOS Activity Monitor
- Lightweight with minimal system impact

## Requirements

- macOS 10.15 or later
- Xcode 12 or later (for building)

## Versions

1. **Standard Version**: Basic memory and swap monitoring in the menu bar
2. **Advanced Version**: Adds notifications and detailed memory breakdown  
3. **Visual Version**: Adds SwiftUI interface with Activity Monitor style visualization

## Building from Source

1. Open Terminal
2. Navigate to the project directory
3. Build the application using Swift:

```bash
# For standard version
./build.sh

# For advanced version (with notifications and more features)
./build.sh advanced

# For visual version (with Activity Monitor style UI)
./build.sh visual
```

## Running the Application

After building the application, you can run it by:

```bash
./MemoryMonitor
```

## Using the Visual Version

The visual version displays memory usage similar to Activity Monitor:

- Click on the menu bar icon to see a detailed visualization
- The memory bar changes color based on memory pressure (green-yellow-red)
- Shows separate breakdowns for App Memory, Wired Memory, Compressed Memory, and Cached Files
- Updates in real-time with your selected refresh interval 

## Installing as a Daemon

To install the application as a daemon that runs at startup:

```bash
./install_daemon.sh
```

This will:
- Build the visual version of the application (with Activity Monitor style UI)
- Install a LaunchAgent to run the application at login
- Start the application immediately

## Uninstalling

To completely remove Memory Monitor from your system:

```bash
./uninstall.sh
```

This will:
- Terminate any running instances of Memory Monitor
- Unload and remove the LaunchAgent if installed
- Give you the option to delete the executable
- Clean up temporary log files

Alternatively, to manually uninstall just the daemon:

```bash
launchctl unload ~/Library/LaunchAgents/com.memory.monitor.plist
rm ~/Library/LaunchAgents/com.memory.monitor.plist
```

## License

This software is provided under the MIT License. 