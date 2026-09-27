import Foundation

extension URL {
    func getExtendedAttribute(name: String) -> Data? {
        let path = self.path
        let size = getxattr(path, name, nil, 0, 0, 0)
        guard size > 0 else { return nil }
        var data = Data(count: size)
        let result = data.withUnsafeMutableBytes {
            getxattr(path, name, $0.baseAddress, size, 0, 0)
        }
        return result > 0 ? data : nil
    }
    
    func setExtendedAttribute(name: String, data: Data) {
        let path = self.path
        _ = data.withUnsafeBytes {
            setxattr(path, name, $0.baseAddress, data.count, 0, 0)
        }
    }
}

struct FileMove: Codable {
    let originalPath: String
    let newPath: String
    var creationDate: Date?
    var modificationDate: Date?
    var dateAddedRaw: Data?
}

struct ScanEvent: Codable {
    let id: UUID
    let timestamp: Date
    let moves: [FileMove]
}

class HistoryManager {
    static let shared = HistoryManager()
    private let historyKey = "scanHistory"
    private let maxHistory = 3

    var history: [ScanEvent] = [] {
        didSet {
            saveHistory()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("HistoryUpdated"), object: nil)
            }
        }
    }

    private init() {
        loadHistory()
    }

    func addScan(moves: [FileMove]) {
        guard !moves.isEmpty else { return }
        let event = ScanEvent(id: UUID(), timestamp: Date(), moves: moves)
        var current = history
        current.insert(event, at: 0) // Newest first
        if current.count > maxHistory {
            current = Array(current.prefix(maxHistory))
        }
        history = current
    }

    func revert(eventID: UUID) {
        guard let index = history.firstIndex(where: { $0.id == eventID }) else { return }
        let event = history[index]
        
        let fm = FileManager.default
        for move in event.moves {
            let currentURL = URL(fileURLWithPath: move.newPath)
            var originalURL = URL(fileURLWithPath: move.originalPath)
            
            // If the file still exists at the location we moved it to
            if fm.fileExists(atPath: currentURL.path) {
                // Ensure the target name is unique so we don't overwrite user files
                originalURL = determineUniqueFileURL(for: originalURL, in: originalURL.deletingLastPathComponent())
                do {
                    // Create the original directory if it was deleted
                    let originalDir = originalURL.deletingLastPathComponent()
                    if !fm.fileExists(atPath: originalDir.path) {
                        try fm.createDirectory(at: originalDir, withIntermediateDirectories: true)
                    }
                    try fm.moveItem(at: currentURL, to: originalURL)
                    
                    // Restore original dates and Date Added xattr to preserve finder metadata
                    var attributes: [FileAttributeKey: Any] = [:]
                    if let cDate = move.creationDate { attributes[.creationDate] = cDate }
                    if let mDate = move.modificationDate { attributes[.modificationDate] = mDate }
                    if !attributes.isEmpty {
                        try? fm.setAttributes(attributes, ofItemAtPath: originalURL.path)
                    }
                    
                    if let dateAdded = move.dateAddedRaw {
                        originalURL.setExtendedAttribute(name: "com.apple.metadata:kMDItemDateAdded", data: dateAdded)
                    }
                    
                } catch {
                    print("Failed to revert file \(currentURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
        
        history.remove(at: index)
    }
    
    private func determineUniqueFileURL(for fileURL: URL, in destinationFolder: URL) -> URL {
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension
        var targetURL = destinationFolder.appendingPathComponent(fileURL.lastPathComponent)
        var counter = 1
        
        while FileManager.default.fileExists(atPath: targetURL.path) {
            let newFileName = ext.isEmpty ? "\(fileName) (\(counter))" : "\(fileName) (\(counter)).\(ext)"
            targetURL = destinationFolder.appendingPathComponent(newFileName)
            counter += 1
        }
        return targetURL
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([ScanEvent].self, from: data) {
            history = decoded
        }
    }
}
