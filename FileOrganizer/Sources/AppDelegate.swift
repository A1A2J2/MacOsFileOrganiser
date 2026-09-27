import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Register default shortcuts
        UserDefaults.standard.register(defaults: [
            "scanShortcutKey": "b",
            "scanShortcutModIndex": 1, // Cmd+Shift by default
            "openShortcutKey": "o",
            "openShortcutModIndex": 1,
            "revertShortcutKey": "z",
            "revertShortcutModIndex": 1
        ])
        
        // Request notification authorization
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        
        // Start Hotkey Manager
        ShortcutManager.shared.start()
        
        // Initialize Status Bar UI
        statusBarController = StatusBarController()
        
        // Initialize folder monitoring state based on saved settings
        FolderMonitor.shared.loadSettings()
    }
    
    // Ensures notifications show up even when the app is active
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
