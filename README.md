# Memory Monitor

A simple macOS menu bar application that displays memory and swap usage.

## Features

- Shows memory usage percentage in the menu bar
- Shows swap usage percentage in the menu bar
- Sends notification when swap usage begins
- Updates automatically every 5 seconds
- Option to manually refresh statistics
- Can run as a daemon at system startup
- Lightweight with minimal system impact

## Requirements

- macOS 10.15 or later
- Xcode 12 or later (for building)

## Building from Source

1. Open Terminal
2. Navigate to the project directory
3. Build the application using Swift:

```bash
# For standard version
./build.sh

# For advanced version (with notifications and more features)
./build.sh advanced
```

## Running the Application

After building the application, you can run it by:

```bash
./MemoryMonitor
```

## Installing as a Daemon

To install the application as a daemon that runs at startup:

```bash
./install_daemon.sh
```

This will:
- Build the advanced version of the application
- Install a LaunchAgent to run the application at login
- Start the application immediately

To uninstall the daemon:

```bash
launchctl unload ~/Library/LaunchAgents/com.memory.monitor.plist
rm ~/Library/LaunchAgents/com.memory.monitor.plist
```

## License

This software is provided under the MIT License. 