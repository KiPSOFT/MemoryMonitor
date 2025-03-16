import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var timer: Timer?
    var memoryInfo: MemoryInfo = MemoryInfo()
    var swapInfo: SwapInfo = SwapInfo()
    var notifiedAboutSwap: Bool = false
    var popover: NSPopover!
    var memoryInfoWrapper: ObservableMemoryInfo!
    var swapInfoWrapper: ObservableSwapInfo!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request permission for notifications
        requestNotificationPermission()
        
        // Create wrappers for bindings
        memoryInfoWrapper = ObservableMemoryInfo(memoryInfo: memoryInfo)
        swapInfoWrapper = ObservableSwapInfo(swapInfo: swapInfo)
        
        setupPopover()
        setupStatusBar()
        startMonitoring()
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 140)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MemoryVisualizationView(memoryInfoWrapper: memoryInfoWrapper, swapInfoWrapper: swapInfoWrapper))
    }
    
    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            button.title = "Loading..."
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create the menu
        let menu = NSMenu()
        
        // Details menu item
        let detailsItem = NSMenuItem(title: "Memory Details", action: #selector(togglePopover), keyEquivalent: "d")
        detailsItem.target = self
        menu.addItem(detailsItem)
        
        // Add a separator
        menu.addItem(NSMenuItem.separator())
        
        // Update interval submenu
        let updateItem = NSMenuItem(title: "Update Interval", action: nil, keyEquivalent: "")
        let updateMenu = NSMenu()
        
        updateMenu.addItem(NSMenuItem(title: "1 second", action: #selector(setUpdateInterval(_:)), keyEquivalent: "1"))
        updateMenu.addItem(NSMenuItem(title: "3 seconds", action: #selector(setUpdateInterval(_:)), keyEquivalent: "3"))
        updateMenu.addItem(NSMenuItem(title: "5 seconds", action: #selector(setUpdateInterval(_:)), keyEquivalent: "5"))
        updateMenu.addItem(NSMenuItem(title: "10 seconds", action: #selector(setUpdateInterval(_:)), keyEquivalent: "0"))
        
        updateItem.submenu = updateMenu
        menu.addItem(updateItem)
        
        // Refresh and quit
        menu.addItem(NSMenuItem(title: "Refresh Now", action: #selector(refreshStats), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
    }
    
    @objc func togglePopover() {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Update the view before showing
                popover.contentViewController = NSHostingController(rootView: MemoryVisualizationView(memoryInfoWrapper: memoryInfoWrapper, swapInfoWrapper: swapInfoWrapper))
            }
        }
    }
    
    func sendSwapNotification() {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Swap Kullanımı Başladı"
        content.body = "Sistem swap alanını kullanmaya başladı. Mevcut swap kullanımı: \(formatBytes(swapInfo.used)) (\(swapInfo.usedPercentage)%)"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: "swapNotification", content: content, trigger: nil)
        
        center.add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    func startMonitoring() {
        // Update immediately
        refreshStats()
        
        // Then update every 5 seconds by default
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(refreshStats), userInfo: nil, repeats: true)
    }
    
    @objc func setUpdateInterval(_ sender: NSMenuItem) {
        timer?.invalidate()
        
        var interval: TimeInterval = 5.0
        
        switch sender.keyEquivalent {
        case "1":
            interval = 1.0
        case "3":
            interval = 3.0
        case "5":
            interval = 5.0
        case "0":
            interval = 10.0
        default:
            interval = 5.0
        }
        
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(refreshStats), userInfo: nil, repeats: true)
    }
    
    @objc func refreshStats() {
        // Get previous swap usage to compare
        let previousSwapUsed = swapInfo.used
        
        // Get memory and swap information
        memoryInfo = getMemoryInfo()
        swapInfo = getSwapInfo()
        
        // Update our observable wrappers
        memoryInfoWrapper.updateMemoryInfo(memoryInfo)
        swapInfoWrapper.updateSwapInfo(swapInfo)
        
        // Check for swap usage
        if swapInfo.used > 0 && previousSwapUsed == 0 && !notifiedAboutSwap {
            sendSwapNotification()
            notifiedAboutSwap = true
        } else if swapInfo.used == 0 && previousSwapUsed > 0 {
            // Reset notification flag when swap usage returns to zero
            notifiedAboutSwap = false
        }
        
        // Update the status bar with App Memory + Wired percentage
        if let button = statusBarItem.button {
            let appAndWiredPercentage = Int(Double(memoryInfo.app + memoryInfo.wired) / Double(memoryInfo.total) * 100)
            button.title = "RAM: \(appAndWiredPercentage)% | Swap: \(formatBytesShort(swapInfo.used))"
        }
        
        // Update the popover if it's shown
        if popover.isShown {
            // The popover view will automatically refresh due to the ObservableObject
        }
    }
    
    func formatBytesShort(_ bytes: UInt64) -> String {
        if bytes == 0 {
            return "0 B"
        }
        
        let units = ["B", "KB", "MB", "GB", "TB"]
        let digitGroups = Int(log10(Double(bytes)) / log10(1024.0))
        let value = Double(bytes) / pow(1024.0, Double(digitGroups))
        
        return String(format: "%.1f %@", value, units[digitGroups])
    }
    
    func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    struct MemoryInfo {
        var total: UInt64 = 0
        var free: UInt64 = 0
        var active: UInt64 = 0
        var inactive: UInt64 = 0
        var wired: UInt64 = 0
        var compressed: UInt64 = 0
        var app: UInt64 = 0
        var cached: UInt64 = 0
        var used: UInt64 = 0
        var usedPercentage: Int = 0
    }
    
    struct SwapInfo {
        var total: UInt64 = 0
        var used: UInt64 = 0
        var free: UInt64 = 0
        var usedPercentage: Int = 0
    }
    
    func getMemoryInfo() -> MemoryInfo {
        var memoryInfo = MemoryInfo()
        
        var stats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()
        let kerr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &size)
            }
        }
        
        if kerr != KERN_SUCCESS {
            return memoryInfo
        }
        
        let pageSize = vm_kernel_page_size
        
        memoryInfo.total = ProcessInfo.processInfo.physicalMemory
        memoryInfo.free = UInt64(stats.free_count) * UInt64(pageSize)
        memoryInfo.active = UInt64(stats.active_count) * UInt64(pageSize)
        memoryInfo.inactive = UInt64(stats.inactive_count) * UInt64(pageSize)
        memoryInfo.wired = UInt64(stats.wire_count) * UInt64(pageSize)
        memoryInfo.compressed = UInt64(stats.compressor_page_count) * UInt64(pageSize)
        
        // Calculate app memory and cached files more accurately
        memoryInfo.cached = UInt64(stats.external_page_count) * UInt64(pageSize) + memoryInfo.inactive
        memoryInfo.app = memoryInfo.active - (memoryInfo.cached / 2)  // Approximating app memory
        
        // Total used memory calculation, similar to Activity Monitor
        memoryInfo.used = memoryInfo.app + memoryInfo.wired + memoryInfo.compressed
        
        // Overall percentage is now based on used memory (app+wired+compressed) divided by total
        memoryInfo.usedPercentage = Int((Double(memoryInfo.used) / Double(memoryInfo.total)) * 100)
        
        return memoryInfo
    }
    
    func getSwapInfo() -> SwapInfo {
        var swapInfo = SwapInfo()
        
        let task = Process()
        task.launchPath = "/usr/sbin/sysctl"
        task.arguments = ["-n", "vm.swapusage"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return swapInfo
            }
            
            // Parse output like: "total = 2048.00M used = 1024.00M free = 1024.00M"
            let components = output.components(separatedBy: " ")
            
            if components.count > 2 {
                let totalStr = components[2].replacingOccurrences(of: "M", with: "")
                if let total = Double(totalStr) {
                    swapInfo.total = UInt64(total * 1024 * 1024)
                }
            }
            
            if components.count > 5 {
                let usedStr = components[5].replacingOccurrences(of: "M", with: "")
                if let used = Double(usedStr) {
                    swapInfo.used = UInt64(used * 1024 * 1024)
                }
            }
            
            if components.count > 8 {
                let freeStr = components[8].replacingOccurrences(of: "M", with: "")
                if let free = Double(freeStr) {
                    swapInfo.free = UInt64(free * 1024 * 1024)
                }
            }
            
            swapInfo.usedPercentage = swapInfo.total > 0 ? Int((Double(swapInfo.used) / Double(swapInfo.total)) * 100) : 0
            
        } catch {
            return swapInfo
        }
        
        return swapInfo
    }
}

// MARK: - SwiftUI Memory Visualization

class ObservableMemoryInfo: ObservableObject {
    @Published var memoryInfo: AppDelegate.MemoryInfo
    
    var total: UInt64 { memoryInfo.total }
    var free: UInt64 { memoryInfo.free }
    var active: UInt64 { memoryInfo.active }
    var inactive: UInt64 { memoryInfo.inactive }
    var wired: UInt64 { memoryInfo.wired }
    var compressed: UInt64 { memoryInfo.compressed }
    var app: UInt64 { memoryInfo.app }
    var cached: UInt64 { memoryInfo.cached }
    var used: UInt64 { memoryInfo.used }
    var usedPercentage: Int { memoryInfo.usedPercentage }
    
    init(memoryInfo: AppDelegate.MemoryInfo) {
        self.memoryInfo = memoryInfo
    }
    
    func updateMemoryInfo(_ info: AppDelegate.MemoryInfo) {
        self.memoryInfo = info
        self.objectWillChange.send()
    }
}

class ObservableSwapInfo: ObservableObject {
    @Published var swapInfo: AppDelegate.SwapInfo
    
    var total: UInt64 { swapInfo.total }
    var used: UInt64 { swapInfo.used }
    var free: UInt64 { swapInfo.free }
    var usedPercentage: Int { swapInfo.usedPercentage }
    
    init(swapInfo: AppDelegate.SwapInfo) {
        self.swapInfo = swapInfo
    }
    
    func updateSwapInfo(_ info: AppDelegate.SwapInfo) {
        self.swapInfo = info
        self.objectWillChange.send()
    }
}

struct MemoryVisualizationView: View {
    @ObservedObject var memoryInfoWrapper: ObservableMemoryInfo
    @ObservedObject var swapInfoWrapper: ObservableSwapInfo
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("MEMORY PRESSURE")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.bottom, 5)
            
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 15)
                    .foregroundColor(Color(.systemGray))
                
                // Memory usage bar
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: getBarWidth(percent: memoryInfoWrapper.usedPercentage), height: 15)
                    .foregroundColor(getMemoryBarColor(percent: memoryInfoWrapper.usedPercentage))
            }
            .padding(.bottom, 10)
            
            HStack(alignment: .top) {
                // Left column
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Physical Memory:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatBytes(memoryInfoWrapper.total))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Memory Used:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatBytes(memoryInfoWrapper.used))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Cached Files:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatBytes(memoryInfoWrapper.cached))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Swap Used:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(swapInfoWrapper.used > 0 ? formatBytes(swapInfoWrapper.used) : "0 bytes")
                            .fontWeight(.medium)
                    }
                }
                .frame(width: 200)
                
                Spacer()
                
                // Right column
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("App Memory:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatBytes(memoryInfoWrapper.app))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Wired Memory:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatBytes(memoryInfoWrapper.wired))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Compressed:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatBytes(memoryInfoWrapper.compressed))
                            .fontWeight(.medium)
                    }
                }
                .frame(width: 170)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    private func getBarWidth(percent: Int) -> CGFloat {
        return CGFloat(percent) / 100.0 * 380.0
    }
    
    private func getMemoryBarColor(percent: Int) -> Color {
        if percent < 60 {
            return Color.green
        } else if percent < 80 {
            return Color.yellow
        } else {
            return Color.red
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// Main başlatma noktasını ekleyelim
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv) 