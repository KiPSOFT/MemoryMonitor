import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var timer: Timer?
    var memoryInfo: MemoryInfo = MemoryInfo()
    var swapInfo: SwapInfo = SwapInfo()
    var notifiedAboutSwap: Bool = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request permission for notifications
        requestNotificationPermission()
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
    
    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            button.title = "Loading..."
        }
        
        // Create the menu
        let menu = NSMenu()
        
        // Details menu item
        let detailsItem = NSMenuItem(title: "Details", action: nil, keyEquivalent: "")
        menu.addItem(detailsItem)
        
        // Submenu for details
        let detailsMenu = NSMenu()
        
        // Memory details
        let memPhysicalItem = NSMenuItem(title: "Physical Memory: Loading...", action: nil, keyEquivalent: "")
        detailsMenu.addItem(memPhysicalItem)
        
        let memActiveItem = NSMenuItem(title: "Active Memory: Loading...", action: nil, keyEquivalent: "")
        detailsMenu.addItem(memActiveItem)
        
        let memInactiveItem = NSMenuItem(title: "Inactive Memory: Loading...", action: nil, keyEquivalent: "")
        detailsMenu.addItem(memInactiveItem)
        
        let memWiredItem = NSMenuItem(title: "Wired Memory: Loading...", action: nil, keyEquivalent: "")
        detailsMenu.addItem(memWiredItem)
        
        let memFreeItem = NSMenuItem(title: "Free Memory: Loading...", action: nil, keyEquivalent: "")
        detailsMenu.addItem(memFreeItem)
        
        // Separator
        detailsMenu.addItem(NSMenuItem.separator())
        
        // Swap details
        let swapTotalItem = NSMenuItem(title: "Swap Total: Loading...", action: nil, keyEquivalent: "")
        detailsMenu.addItem(swapTotalItem)
        
        let swapUsedItem = NSMenuItem(title: "Swap Used: Loading...", action: nil, keyEquivalent: "")
        detailsMenu.addItem(swapUsedItem)
        
        let swapFreeItem = NSMenuItem(title: "Swap Free: Loading...", action: nil, keyEquivalent: "")
        detailsMenu.addItem(swapFreeItem)
        
        detailsItem.submenu = detailsMenu
        
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
        
        // Check for swap usage
        if swapInfo.used > 0 && previousSwapUsed == 0 && !notifiedAboutSwap {
            sendSwapNotification()
            notifiedAboutSwap = true
        } else if swapInfo.used == 0 && previousSwapUsed > 0 {
            // Reset notification flag when swap usage returns to zero
            notifiedAboutSwap = false
        }
        
        // Update the status bar
        if let button = statusBarItem.button {
            button.title = "RAM: \(memoryInfo.usedPercentage)% | Swap: \(swapInfo.usedPercentage)%"
        }
        
        // Update the menu items
        if let menu = statusBarItem.menu {
            if let detailsMenu = menu.item(at: 0)?.submenu {
                // Update memory details
                detailsMenu.item(at: 0)?.title = "Physical Memory: \(formatBytes(memoryInfo.total))"
                detailsMenu.item(at: 1)?.title = "Active Memory: \(formatBytes(memoryInfo.active))"
                detailsMenu.item(at: 2)?.title = "Inactive Memory: \(formatBytes(memoryInfo.inactive))"
                detailsMenu.item(at: 3)?.title = "Wired Memory: \(formatBytes(memoryInfo.wired))"
                detailsMenu.item(at: 4)?.title = "Free Memory: \(formatBytes(memoryInfo.free))"
                
                // Update swap details
                detailsMenu.item(at: 6)?.title = "Swap Total: \(formatBytes(swapInfo.total))"
                detailsMenu.item(at: 7)?.title = "Swap Used: \(formatBytes(swapInfo.used))"
                detailsMenu.item(at: 8)?.title = "Swap Free: \(formatBytes(swapInfo.free))"
            }
        }
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
        
        memoryInfo.used = memoryInfo.total - memoryInfo.free
        
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

// Main başlatma noktasını ekleyelim
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv) 