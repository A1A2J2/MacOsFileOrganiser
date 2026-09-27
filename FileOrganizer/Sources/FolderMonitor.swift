import Foundation

/// Manages the periodic scanning of the selected source folder.
class FolderMonitor {
    static let shared = FolderMonitor()
    
    private var timer: Timer?
    private var dailyTimer: Timer?
    
    var isMonitoring: Bool = false {
        didSet {
            reloadTimers()
        }
    }
    
    // Scan interval in seconds (-1 indicates daily schedule)
    var scanInterval: TimeInterval = 60 {
        didSet {
            reloadTimers()
        }
    }
    
    private init() {
        // Load settings from UserDefaults
        loadSettings()
    }
    
    func loadSettings() {
        let interval = UserDefaults.standard.double(forKey: "scanInterval")
        if interval != 0 {
            self.scanInterval = interval
        } else {
            self.scanInterval = 60
        }
        
        self.isMonitoring = UserDefaults.standard.bool(forKey: "isAutomaticScanEnabled")
    }
    
    func reloadTimers() {
        timer?.invalidate()
        timer = nil
        dailyTimer?.invalidate()
        dailyTimer = nil
        
        guard isMonitoring else { return }
        
        if scanInterval == -1 {
            scheduleNextDailyScan()
        } else {
            // Schedule on the main run loop to ensure Timer fires correctly
            DispatchQueue.main.async {
                self.timer = Timer.scheduledTimer(withTimeInterval: self.scanInterval, repeats: true) { [weak self] _ in
                    self?.performScan()
                }
            }
        }
    }
    
    private func scheduleNextDailyScan() {
        guard let targetTime = UserDefaults.standard.object(forKey: "dailyScanTime") as? Date else {
            // Default to current time if never set
            UserDefaults.standard.set(Date(), forKey: "dailyScanTime")
            scheduleNextDailyScan()
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetTime)
        
        guard let nextScanDate = calendar.nextDate(after: now, matching: targetComponents, matchingPolicy: .nextTime) else {
            return
        }
        
        let delay = nextScanDate.timeIntervalSince(now)
        
        DispatchQueue.main.async {
            self.dailyTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.performScan()
                self?.scheduleNextDailyScan() // Schedule for the next day
            }
        }
    }
    
    func performScan() {
        guard let sourcePath = UserDefaults.standard.string(forKey: "sourceFolder"),
              let outputPath = UserDefaults.standard.string(forKey: "outputFolder"),
              !sourcePath.isEmpty,
              !outputPath.isEmpty else {
            return
        }
        
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let outputURL = URL(fileURLWithPath: outputPath)
        
        // Use a background queue to prevent blocking the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            FileOrganizer.shared.organizeFiles(from: sourceURL, to: outputURL)
        }
    }
}
