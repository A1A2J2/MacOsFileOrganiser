import AppKit
import UserNotifications

class ShortcutManager {
    static let shared = ShortcutManager()
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    // 0: Cmd, 1: Cmd+Shift, 2: Cmd+Opt, 3: Ctrl, 4: Ctrl+Opt, 5: Ctrl+Shift
    private let modifierOptions: [NSEvent.ModifierFlags] = [
        .command,
        [.command, .shift],
        [.command, .option],
        .control,
        [.control, .option],
        [.control, .shift]
    ]
    
    func start() {
        // Request accessibility access if needed for global hotkeys
        let promptOption = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptOption: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleEvent(event)
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
    }
    
    private func handleEvent(_ event: NSEvent) {
        guard let chars = event.charactersIgnoringModifiers?.lowercased(), chars.count > 0 else { return }
        let char = String(chars.prefix(1))
        
        // Strip out things like caps lock or numeric pad to strictly match our required modifiers
        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        
        // 1. Scan Shortcut
        let scanKey = (UserDefaults.standard.string(forKey: "scanShortcutKey") ?? "b").lowercased()
        let scanModIndex = UserDefaults.standard.integer(forKey: "scanShortcutModIndex")
        
        if !scanKey.isEmpty && char == String(scanKey.prefix(1)) {
            let requiredFlags = modifierOptions[scanModIndex < modifierOptions.count ? scanModIndex : 0]
            if flags == requiredFlags {
                FolderMonitor.shared.performScan()
                return
            }
        }
        
        // 2. Custom Command Shortcut
        let scriptKey = (UserDefaults.standard.string(forKey: "scriptShortcutKey") ?? "").lowercased()
        let scriptModIndex = UserDefaults.standard.integer(forKey: "scriptShortcutModIndex")
        
        if !scriptKey.isEmpty && char == String(scriptKey.prefix(1)) {
            let requiredFlags = modifierOptions[scriptModIndex < modifierOptions.count ? scriptModIndex : 0]
            if flags == requiredFlags {
                runCustomScript()
                return
            }
        }
        
        // 3. Open Folder Shortcut
        let openKey = (UserDefaults.standard.string(forKey: "openShortcutKey") ?? "o").lowercased()
        let openModIndex = UserDefaults.standard.integer(forKey: "openShortcutModIndex")
        
        if !openKey.isEmpty && char == String(openKey.prefix(1)) {
            let requiredFlags = modifierOptions[openModIndex < modifierOptions.count ? openModIndex : 0]
            if flags == requiredFlags {
                openOrganizationFolder()
                return
            }
        }
        
        // 4. Revert History Shortcut
        let revertKey = (UserDefaults.standard.string(forKey: "revertShortcutKey") ?? "z").lowercased()
        let revertModIndex = UserDefaults.standard.integer(forKey: "revertShortcutModIndex")
        
        if !revertKey.isEmpty && char == String(revertKey.prefix(1)) {
            let requiredFlags = modifierOptions[revertModIndex < modifierOptions.count ? revertModIndex : 0]
            if flags == requiredFlags {
                revertLastHistory()
                return
            }
        }
    }
    
    private func openOrganizationFolder() {
        guard let outputPath = UserDefaults.standard.string(forKey: "outputFolder"), !outputPath.isEmpty else { return }
        let organizationFolder = URL(fileURLWithPath: outputPath).appendingPathComponent("Organization")
        if !FileManager.default.fileExists(atPath: organizationFolder.path) {
            try? FileManager.default.createDirectory(at: organizationFolder, withIntermediateDirectories: true)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [organizationFolder.path]
        try? process.run()
    }
    
    private func revertLastHistory() {
        if let lastEvent = HistoryManager.shared.history.first {
            HistoryManager.shared.revert(eventID: lastEvent.id)
            DispatchQueue.main.async {
                let content = UNMutableNotificationContent()
                content.title = "Revert Complete"
                content.body = "Files have been restored via hotkey."
                content.sound = .default
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    private func runCustomScript() {
        guard let command = UserDefaults.standard.string(forKey: "customScriptCommand"), !command.isEmpty else { return }
        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", command]
            try? process.run()
            process.waitUntilExit()
        }
    }
}
