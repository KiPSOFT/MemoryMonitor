import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var timer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        startMonitoring()
    }
    
    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            button.title = "Loading..."
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshStats), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusBarItem.menu = menu
    }
    
    func startMonitoring() {
        // Update immediately
        refreshStats()
        
        // Then update every 5 seconds
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(refreshStats), userInfo: nil, repeats: true)
    }
    
    @objc func refreshStats() {
        let memoryInfo = getMemoryInfo()
        let swapInfo = getSwapInfo()
        
        if let button = statusBarItem.button {
            button.title = "Memory: \(memoryInfo.usedPercentage)% | Swap: \(swapInfo.usedPercentage)%"
        }
    }
    
    func getMemoryInfo() -> (total: UInt64, used: UInt64, usedPercentage: Int) {
        var stats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()
        let kerr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &size)
            }
        }
        
        if kerr != KERN_SUCCESS {
            return (0, 0, 0)
        }
        
        let pageSize = vm_kernel_page_size
        
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let freeMemory = UInt64(stats.free_count) * UInt64(pageSize)
        let _ = UInt64(stats.active_count) * UInt64(pageSize)
        let _ = UInt64(stats.inactive_count) * UInt64(pageSize)
        let _ = UInt64(stats.wire_count) * UInt64(pageSize)
        
        let usedMemory = totalMemory - freeMemory
        
        let usedPercentage = Int((Double(usedMemory) / Double(totalMemory)) * 100)
        
        return (totalMemory, usedMemory, usedPercentage)
    }
    
    func getSwapInfo() -> (total: UInt64, used: UInt64, usedPercentage: Int) {
        var totalSwap: UInt64 = 0
        var usedSwap: UInt64 = 0
        
        let task = Process()
        task.launchPath = "/usr/sbin/sysctl"
        task.arguments = ["-n", "vm.swapusage"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return (0, 0, 0)
            }
            
            // Parse output like: "total = 2048.00M used = 1024.00M free = 1024.00M"
            let components = output.components(separatedBy: " ")
            
            if components.count > 2 {
                let totalStr = components[2].replacingOccurrences(of: "M", with: "")
                if let total = Double(totalStr) {
                    totalSwap = UInt64(total * 1024 * 1024)
                }
            }
            
            if components.count > 5 {
                let usedStr = components[5].replacingOccurrences(of: "M", with: "")
                if let used = Double(usedStr) {
                    usedSwap = UInt64(used * 1024 * 1024)
                }
            }
        } catch {
            return (0, 0, 0)
        }
        
        let usedPercentage = totalSwap > 0 ? Int((Double(usedSwap) / Double(totalSwap)) * 100) : 0
        
        return (totalSwap, usedSwap, usedPercentage)
    }
}

// Main başlatma noktasını ekleyelim
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv) 