import AppKit
import Carbon

class SettingsWindowController: NSWindowController, NSWindowDelegate, NSTextFieldDelegate {
    
    private let sourceLabel = NSTextField(labelWithString: "Source Folder: None")
    private let outputLabel = NSTextField(labelWithString: "Output Folder: None")
    
    private let excludeTextField = NSTextField()
    private let commandTextField = NSTextField()
    
    private let intervalPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let timePicker = NSDatePicker()
    
    private let autoScanCheckbox = NSButton(checkboxWithTitle: "Enable Automatic Scanning", target: nil, action: nil)
    
    // Shortcut UI
    private let scanModifierPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let scanKeyField = NSTextField()
    
    private let scriptModifierPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let scriptKeyField = NSTextField()
    private let scriptCommandField = NSTextField()
    
    private let openModifierPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let openKeyField = NSTextField()
    
    private let revertModifierPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let revertKeyField = NSTextField()
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "File Organizer Settings"
        window.center()
        window.minSize = NSSize(width: 500, height: 500)
        
        super.init(window: window)
        window.delegate = self
        setupUI()
        loadSettings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // Scroll View
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        contentView.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Stack View
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 15
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.documentView = stackView
        stackView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor).isActive = true
        // Fix for massive forehead issue:
        stackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor).isActive = true
        
        // Source Folder
        let sourceButton = NSButton(title: "Choose Source Folder...", target: self, action: #selector(chooseSourceFolder))
        stackView.addArrangedSubview(sourceLabel)
        stackView.addArrangedSubview(sourceButton)
        
        // Output Folder
        let outputButton = NSButton(title: "Choose Output Folder...", target: self, action: #selector(chooseOutputFolder))
        stackView.addArrangedSubview(outputLabel)
        stackView.addArrangedSubview(outputButton)
        
        // Separator
        let separator1 = NSBox()
        separator1.boxType = .separator
        stackView.addArrangedSubview(separator1)
        separator1.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -40).isActive = true
        
        // Exclude Extensions
        let excludeLabel = NSTextField(labelWithString: "Exclude Extensions (comma separated):")
        excludeTextField.placeholderString = "e.g., app, iso, dmg"
        excludeTextField.delegate = self
        
        let excludeStack = NSStackView(views: [excludeLabel, excludeTextField])
        excludeStack.orientation = .horizontal
        excludeTextField.widthAnchor.constraint(equalToConstant: 200).isActive = true
        stackView.addArrangedSubview(excludeStack)
        
        // Post-Scan Command
        let commandLabel = NSTextField(labelWithString: "Post-Scan Command (Bash):")
        commandTextField.placeholderString = "e.g., /path/to/script.sh"
        commandTextField.delegate = self
        
        let commandStack = NSStackView(views: [commandLabel, commandTextField])
        commandStack.orientation = .horizontal
        commandTextField.widthAnchor.constraint(equalToConstant: 240).isActive = true
        stackView.addArrangedSubview(commandStack)
        
        // Separator
        let separator2 = NSBox()
        separator2.boxType = .separator
        stackView.addArrangedSubview(separator2)
        separator2.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -40).isActive = true
        
        // Interval
        let intervalLabel = NSTextField(labelWithString: "Scan Interval:")
        
        intervalPopup.addItems(withTitles: ["30 Seconds", "1 Minute", "5 Minutes", "10 Minutes", "30 Minutes", "Daily"])
        intervalPopup.target = self
        intervalPopup.action = #selector(intervalChanged)
        
        timePicker.datePickerElements = .hourMinute
        timePicker.datePickerStyle = .textField
        timePicker.target = self
        timePicker.action = #selector(timeChanged)
        
        let intervalStack = NSStackView(views: [intervalLabel, intervalPopup, timePicker])
        intervalStack.orientation = .horizontal
        stackView.addArrangedSubview(intervalStack)
        
        // Auto Scan
        autoScanCheckbox.target = self
        autoScanCheckbox.action = #selector(autoScanChanged)
        stackView.addArrangedSubview(autoScanCheckbox)
        
        // Separator
        let separator3 = NSBox()
        separator3.boxType = .separator
        stackView.addArrangedSubview(separator3)
        separator3.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -40).isActive = true
        
        // --- Shortcuts Section ---
        let modifierTitles = ["Command (⌘)", "Command + Shift (⌘⇧)", "Command + Option (⌘⌥)", "Control (⌃)", "Control + Option (⌃⌥)", "Control + Shift (⌃⇧)"]
        
        // Scan Shortcut
        let scanShortcutLabel = NSTextField(labelWithString: "Organize Now Hotkey:")
        scanModifierPopup.addItems(withTitles: modifierTitles)
        scanModifierPopup.target = self
        scanModifierPopup.action = #selector(scanShortcutChanged)
        scanKeyField.delegate = self
        scanKeyField.placeholderString = "b"
        scanKeyField.widthAnchor.constraint(equalToConstant: 40).isActive = true
        let scanShortcutStack = NSStackView(views: [scanShortcutLabel, scanModifierPopup, scanKeyField])
        stackView.addArrangedSubview(scanShortcutStack)
        
        // Open Org Folder Shortcut
        let openShortcutLabel = NSTextField(labelWithString: "Open Org Folder Hotkey:")
        openModifierPopup.addItems(withTitles: modifierTitles)
        openModifierPopup.target = self
        openModifierPopup.action = #selector(openShortcutChanged)
        openKeyField.delegate = self
        openKeyField.placeholderString = "o"
        openKeyField.widthAnchor.constraint(equalToConstant: 40).isActive = true
        let openShortcutStack = NSStackView(views: [openShortcutLabel, openModifierPopup, openKeyField])
        stackView.addArrangedSubview(openShortcutStack)
        
        // Revert Shortcut
        let revertShortcutLabel = NSTextField(labelWithString: "Revert History Hotkey:")
        revertModifierPopup.addItems(withTitles: modifierTitles)
        revertModifierPopup.target = self
        revertModifierPopup.action = #selector(revertShortcutChanged)
        revertKeyField.delegate = self
        revertKeyField.placeholderString = "z"
        revertKeyField.widthAnchor.constraint(equalToConstant: 40).isActive = true
        let revertShortcutStack = NSStackView(views: [revertShortcutLabel, revertModifierPopup, revertKeyField])
        stackView.addArrangedSubview(revertShortcutStack)
        
        // Custom Script Shortcut
        let scriptShortcutLabel = NSTextField(labelWithString: "Custom Hotkey:")
        scriptModifierPopup.addItems(withTitles: modifierTitles)
        scriptModifierPopup.target = self
        scriptModifierPopup.action = #selector(scriptShortcutChanged)
        scriptKeyField.delegate = self
        scriptKeyField.placeholderString = "c"
        scriptKeyField.widthAnchor.constraint(equalToConstant: 40).isActive = true
        let scriptShortcutStack = NSStackView(views: [scriptShortcutLabel, scriptModifierPopup, scriptKeyField])
        stackView.addArrangedSubview(scriptShortcutStack)
        
        // Custom Script Command
        let scriptCmdLabel = NSTextField(labelWithString: "Custom Hotkey Action (Bash):")
        scriptCommandField.delegate = self
        scriptCommandField.placeholderString = "e.g., say 'Hello'"
        scriptCommandField.widthAnchor.constraint(equalToConstant: 240).isActive = true
        let scriptCmdStack = NSStackView(views: [scriptCmdLabel, scriptCommandField])
        stackView.addArrangedSubview(scriptCmdStack)
        
        // Manual Scan
        let manualScanButton = NSButton(title: "Organize Files Now", target: self, action: #selector(runManualScan))
        stackView.addArrangedSubview(manualScanButton)
    }
    
    private func loadSettings() {
        if let source = UserDefaults.standard.string(forKey: "sourceFolder") {
            sourceLabel.stringValue = "Source Folder: \(URL(fileURLWithPath: source).lastPathComponent)"
        }
        
        if let output = UserDefaults.standard.string(forKey: "outputFolder") {
            outputLabel.stringValue = "Output Folder: \(URL(fileURLWithPath: output).lastPathComponent)"
        }
        
        excludeTextField.stringValue = UserDefaults.standard.string(forKey: "excludedExtensions") ?? ""
        commandTextField.stringValue = UserDefaults.standard.string(forKey: "postScanCommand") ?? ""
        
        let interval = UserDefaults.standard.double(forKey: "scanInterval")
        switch interval {
        case 30: intervalPopup.selectItem(at: 0)
        case 60: intervalPopup.selectItem(at: 1)
        case 300: intervalPopup.selectItem(at: 2)
        case 600: intervalPopup.selectItem(at: 3)
        case 1800: intervalPopup.selectItem(at: 4)
        case -1: intervalPopup.selectItem(at: 5)
        default: intervalPopup.selectItem(at: 1) // Default 1 min
        }
        
        if let time = UserDefaults.standard.object(forKey: "dailyScanTime") as? Date {
            timePicker.dateValue = time
        } else {
            let now = Date()
            timePicker.dateValue = now
            UserDefaults.standard.set(now, forKey: "dailyScanTime")
        }
        
        timePicker.isEnabled = (interval == -1)
        autoScanCheckbox.state = UserDefaults.standard.bool(forKey: "isAutomaticScanEnabled") ? .on : .off
        
        // Load Shortcuts
        scanModifierPopup.selectItem(at: UserDefaults.standard.integer(forKey: "scanShortcutModIndex"))
        scanKeyField.stringValue = UserDefaults.standard.string(forKey: "scanShortcutKey") ?? ""
        
        openModifierPopup.selectItem(at: UserDefaults.standard.integer(forKey: "openShortcutModIndex"))
        openKeyField.stringValue = UserDefaults.standard.string(forKey: "openShortcutKey") ?? ""
        
        revertModifierPopup.selectItem(at: UserDefaults.standard.integer(forKey: "revertShortcutModIndex"))
        revertKeyField.stringValue = UserDefaults.standard.string(forKey: "revertShortcutKey") ?? ""
        
        scriptModifierPopup.selectItem(at: UserDefaults.standard.integer(forKey: "scriptShortcutModIndex"))
        scriptKeyField.stringValue = UserDefaults.standard.string(forKey: "scriptShortcutKey") ?? ""
        scriptCommandField.stringValue = UserDefaults.standard.string(forKey: "customScriptCommand") ?? ""
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            if textField == excludeTextField {
                UserDefaults.standard.set(textField.stringValue, forKey: "excludedExtensions")
            } else if textField == commandTextField {
                UserDefaults.standard.set(textField.stringValue, forKey: "postScanCommand")
            } else if textField == scanKeyField {
                updateShortcut(key: textField.stringValue, modIndex: scanModifierPopup.indexOfSelectedItem, keyKey: "scanShortcutKey", modKey: "scanShortcutModIndex", textField: scanKeyField, modifierPopup: scanModifierPopup)
            } else if textField == scriptKeyField {
                updateShortcut(key: textField.stringValue, modIndex: scriptModifierPopup.indexOfSelectedItem, keyKey: "scriptShortcutKey", modKey: "scriptShortcutModIndex", textField: scriptKeyField, modifierPopup: scriptModifierPopup)
            } else if textField == openKeyField {
                updateShortcut(key: textField.stringValue, modIndex: openModifierPopup.indexOfSelectedItem, keyKey: "openShortcutKey", modKey: "openShortcutModIndex", textField: openKeyField, modifierPopup: openModifierPopup)
            } else if textField == revertKeyField {
                updateShortcut(key: textField.stringValue, modIndex: revertModifierPopup.indexOfSelectedItem, keyKey: "revertShortcutKey", modKey: "revertShortcutModIndex", textField: revertKeyField, modifierPopup: revertModifierPopup)
            } else if textField == scriptCommandField {
                UserDefaults.standard.set(textField.stringValue, forKey: "customScriptCommand")
            }
        }
    }
    
    private func updateShortcut(key: String, modIndex: Int, keyKey: String, modKey: String, textField: NSTextField, modifierPopup: NSPopUpButton) {
        let char = String(key.prefix(1)).lowercased()
        
        if !char.isEmpty {
            if isHotkeyTaken(character: char, modIndex: modIndex, ignoringKeyKey: keyKey) {
                // Revert to previous value
                textField.stringValue = UserDefaults.standard.string(forKey: keyKey) ?? ""
                modifierPopup.selectItem(at: UserDefaults.standard.integer(forKey: modKey))
                
                let alert = NSAlert()
                alert.messageText = "Hotkey taken"
                alert.informativeText = "This shortcut is already in use by the system or another application."
                alert.alertStyle = .warning
                alert.runModal()
                return
            }
        }
        
        UserDefaults.standard.set(char, forKey: keyKey)
        UserDefaults.standard.set(modIndex, forKey: modKey)
    }
    
    private func isHotkeyTaken(character: String, modIndex: Int, ignoringKeyKey: String) -> Bool {
        guard let char = character.lowercased().first else { return false }
        
        // 1. Check internal conflicts
        let shortcuts = [
            ("scanShortcutKey", "scanShortcutModIndex"),
            ("scriptShortcutKey", "scriptShortcutModIndex"),
            ("openShortcutKey", "openShortcutModIndex"),
            ("revertShortcutKey", "revertShortcutModIndex")
        ]
        
        for (kKey, mKey) in shortcuts {
            if kKey == ignoringKeyKey { continue }
            let existingChar = (UserDefaults.standard.string(forKey: kKey) ?? "").lowercased()
            let existingMod = UserDefaults.standard.integer(forKey: mKey)
            
            if existingChar.prefix(1) == String(char) && existingMod == modIndex {
                return true
            }
        }
        
        // 2. Check system conflicts via Carbon
        let keyMap: [String: UInt32] = [
            "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
            "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17, "1": 18, "2": 19,
            "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28,
            "0": 29, "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37, "j": 38,
            "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43, "/": 44, "n": 45, "m": 46, ".": 47,
            " ": 49
        ]
        
        guard let keyCode = keyMap[String(char)] else { return false }
        
        var carbonFlags: UInt32 = 0
        switch modIndex {
        case 0: carbonFlags = UInt32(cmdKey)
        case 1: carbonFlags = UInt32(cmdKey | shiftKey)
        case 2: carbonFlags = UInt32(cmdKey | optionKey)
        case 3: carbonFlags = UInt32(controlKey)
        case 4: carbonFlags = UInt32(controlKey | optionKey)
        case 5: carbonFlags = UInt32(controlKey | shiftKey)
        default: break
        }
        
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: 1111, id: UInt32(keyCode))
        let status = RegisterEventHotKey(keyCode, carbonFlags, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr {
            UnregisterEventHotKey(hotKeyRef)
            return false
        } else {
            return true
        }
    }
    
    @objc private func scanShortcutChanged() {
        updateShortcut(key: scanKeyField.stringValue, modIndex: scanModifierPopup.indexOfSelectedItem, keyKey: "scanShortcutKey", modKey: "scanShortcutModIndex", textField: scanKeyField, modifierPopup: scanModifierPopup)
    }
    
    @objc private func scriptShortcutChanged() {
        updateShortcut(key: scriptKeyField.stringValue, modIndex: scriptModifierPopup.indexOfSelectedItem, keyKey: "scriptShortcutKey", modKey: "scriptShortcutModIndex", textField: scriptKeyField, modifierPopup: scriptModifierPopup)
    }
    
    @objc private func openShortcutChanged() {
        updateShortcut(key: openKeyField.stringValue, modIndex: openModifierPopup.indexOfSelectedItem, keyKey: "openShortcutKey", modKey: "openShortcutModIndex", textField: openKeyField, modifierPopup: openModifierPopup)
    }
    
    @objc private func revertShortcutChanged() {
        updateShortcut(key: revertKeyField.stringValue, modIndex: revertModifierPopup.indexOfSelectedItem, keyKey: "revertShortcutKey", modKey: "revertShortcutModIndex", textField: revertKeyField, modifierPopup: revertModifierPopup)
    }
    
    @objc private func chooseSourceFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            UserDefaults.standard.set(url.path, forKey: "sourceFolder")
            sourceLabel.stringValue = "Source Folder: \(url.lastPathComponent)"
            FolderMonitor.shared.loadSettings()
        }
    }
    
    @objc private func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            UserDefaults.standard.set(url.path, forKey: "outputFolder")
            outputLabel.stringValue = "Output Folder: \(url.lastPathComponent)"
            FolderMonitor.shared.loadSettings()
        }
    }
    
    @objc private func intervalChanged() {
        let intervals: [Double] = [30, 60, 300, 600, 1800, -1]
        let selectedInterval = intervals[intervalPopup.indexOfSelectedItem]
        UserDefaults.standard.set(selectedInterval, forKey: "scanInterval")
        
        timePicker.isEnabled = (selectedInterval == -1)
        FolderMonitor.shared.scanInterval = selectedInterval
    }
    
    @objc private func timeChanged() {
        UserDefaults.standard.set(timePicker.dateValue, forKey: "dailyScanTime")
        FolderMonitor.shared.reloadTimers()
    }
    
    @objc private func autoScanChanged() {
        let isEnabled = autoScanCheckbox.state == .on
        UserDefaults.standard.set(isEnabled, forKey: "isAutomaticScanEnabled")
        FolderMonitor.shared.isMonitoring = isEnabled
    }
    
    @objc private func runManualScan() {
        FolderMonitor.shared.performScan()
    }
}