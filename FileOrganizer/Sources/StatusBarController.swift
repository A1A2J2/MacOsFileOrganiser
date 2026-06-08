import AppKit
import UserNotifications

class StatusBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var settingsWindowController: SettingsWindowController?
    private var historyMenuItem: NSMenuItem!
    
    // Store references to items we want to update
    private var scanItem: NSMenuItem!
    private var openFolderItem: NSMenuItem!
    
    override init() {
        super.init()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use a built-in folder icon provided by SF Symbols
            button.image = NSImage(systemSymbolName: "folder", accessibilityDescription: "File Organizer")
        }
        
        setupMenu()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateHistoryMenu), name: NSNotification.Name("HistoryUpdated"), object: nil)
    }
    
    private func setupMenu() {
        menu = NSMenu()
        menu.delegate = self
        
        scanItem = NSMenuItem(title: "Organize Files", action: #selector(scanNow), keyEquivalent: "")
        scanItem.target = self
        menu.addItem(scanItem)
        
        openFolderItem = NSMenuItem(title: "Open Organization Folder", action: #selector(openOrganizationFolder), keyEquivalent: "")
        openFolderItem.target = self
        menu.addItem(openFolderItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // History Submenu
        historyMenuItem = NSMenuItem(title: "History", action: nil, keyEquivalent: "")
        let historyMenu = NSMenu()
        historyMenuItem.submenu = historyMenu
        menu.addItem(historyMenuItem)
        updateHistoryMenu()
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        let aboutItem = NSMenuItem(title: "About File Organizer", action: #selector(showInfo), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        let modifierMap: [NSEvent.ModifierFlags] = [
            .command,
            [.command, .shift],
            [.command, .option],
            .control,
            [.control, .option],
            [.control, .shift]
        ]
        
        // Scan shortcut
        let scanKey = (UserDefaults.standard.string(forKey: "scanShortcutKey") ?? "b").lowercased()
        let scanModIndex = UserDefaults.standard.integer(forKey: "scanShortcutModIndex")
        scanItem.keyEquivalent = scanKey
        if scanModIndex < modifierMap.count {
            scanItem.keyEquivalentModifierMask = modifierMap[scanModIndex]
        }
        
        // Open folder shortcut
        let openKey = (UserDefaults.standard.string(forKey: "openShortcutKey") ?? "o").lowercased()
        let openModIndex = UserDefaults.standard.integer(forKey: "openShortcutModIndex")
        openFolderItem.keyEquivalent = openKey
        if openModIndex < modifierMap.count {
            openFolderItem.keyEquivalentModifierMask = modifierMap[openModIndex]
        }
    }
    
    @objc private func updateHistoryMenu() {
        guard let submenu = historyMenuItem.submenu else { return }
        submenu.removeAllItems()
        
        let history = HistoryManager.shared.history
        if history.isEmpty {
            let emptyItem = NSMenuItem(title: "No Recent Scans", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            submenu.addItem(emptyItem)
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .short
            
            for event in history {
                let timeStr = formatter.string(from: event.timestamp)
                let title = "Revert \(event.moves.count) files (\(timeStr))"
                let item = NSMenuItem(title: title, action: #selector(revertScan(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = event.id.uuidString
                submenu.addItem(item)
            }
        }
    }
    
    @objc private func revertScan(_ sender: NSMenuItem) {
        if let idString = sender.representedObject as? String, let id = UUID(uuidString: idString) {
            HistoryManager.shared.revert(eventID: id)
            
            let content = UNMutableNotificationContent()
            content.title = "Revert Complete"
            content.body = "Files have been restored to their original locations."
            content.sound = .default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error showing notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func scanNow() {
        FolderMonitor.shared.performScan()
    }
    
    @objc private func openOrganizationFolder() {
        guard let outputPath = UserDefaults.standard.string(forKey: "outputFolder"), !outputPath.isEmpty else {
            showSettings()
            return
        }
        
        let organizationFolder = URL(fileURLWithPath: outputPath).appendingPathComponent("Organization")
        
        // Create if it doesn't exist so we can open it
        if !FileManager.default.fileExists(atPath: organizationFolder.path) {
            try? FileManager.default.createDirectory(at: organizationFolder, withIntermediateDirectories: true)
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [organizationFolder.path]
        try? process.run()
    }
    
    @objc private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true) // Bring to front
    }
    
    @objc private func showInfo() {
        if infoWindowController == nil {
            infoWindowController = InfoWindowController()
        }
        infoWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(self)
    }
}
