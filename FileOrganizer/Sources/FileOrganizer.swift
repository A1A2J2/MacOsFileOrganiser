import Foundation
import UserNotifications

/// Handles the actual file moving and organization logic.
class FileOrganizer {
    static let shared = FileOrganizer()
    private let fileManager = FileManager.default
    
    // Categories and their extensions
    private let extensionMappings: [String: [String]] = [
        "Photos": ["jpg", "jpeg", "png", "gif", "heic", "heif", "webp", "tiff", "tif", "psd", "raw", "cr2", "nef", "orf", "sr2", "bmp", "svg", "ico"],
        "Videos": ["mp4", "mov", "mkv", "avi", "wmv", "flv", "webm", "m4v", "mpg", "mpeg", "3gp"],
        "Documents": ["pdf", "docx", "doc", "txt", "rtf", "xlsx", "xls", "pptx", "ppt", "csv", "pages", "numbers", "key", "md", "odt", "ods", "odp"],
        "Archives": ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "dmg", "iso", "pkg"],
        "Audio": ["mp3", "wav", "flac", "m4a", "aac", "ogg", "wma", "aiff", "alac", "mid", "midi"]
    ]
    
    private let codingMappings: [String: [String]] = [
        "Frontend": ["html", "css", "js", "jsx", "ts", "tsx", "vue", "svelte", "scss", "sass", "less"],
        "Backend": ["py", "go", "java", "php", "rb", "rs", "cs", "c", "cpp", "h", "hpp", "sql", "graphql", "pl", "scala"],
        "Mobile": ["swift", "kt", "dart", "m"],
        "Config": ["json", "yaml", "yml", "toml", "xml", "ini", "env", "plist", "config"],
        "Scripts": ["sh", "bash", "zsh", "bat", "ps1", "cmd"]
    ]
    
    private init() {}
    
    func organizeFiles(from sourceURL: URL, to outputURL: URL) {
        let organizationFolder = outputURL.appendingPathComponent("Organization", isDirectory: true)
        
        do {
            // Create Organization folder if it doesn't exist
            if !fileManager.fileExists(atPath: organizationFolder.path) {
                try fileManager.createDirectory(at: organizationFolder, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Get files in source directory
            // We use skipsHiddenFiles to ignore hidden files
            let contents = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            
            // Get excluded extensions from UserDefaults
            let excludedString = UserDefaults.standard.string(forKey: "excludedExtensions") ?? ""
            let excludedExtensions = excludedString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            
            var filesMoved = 0
            var affectedCategories = Set<String>()
            var currentBatchMoves: [FileMove] = []
            
            for fileURL in contents {
                // Skip directories
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDir), isDir.boolValue {
                    continue
                }
                
                let ext = fileURL.pathExtension.lowercased()
                if ext.isEmpty { continue } // Skip files without extensions
                
                // Skip excluded extensions
                if excludedExtensions.contains(ext) { continue }
                
                let categoryPath = determineCategoryPath(for: ext, baseFolder: organizationFolder)
                
                // Create category folder if it doesn't exist
                if !fileManager.fileExists(atPath: categoryPath.path) {
                    try fileManager.createDirectory(at: categoryPath, withIntermediateDirectories: true, attributes: nil)
                }
                
                let targetURL = determineUniqueFileURL(for: fileURL, in: categoryPath)
                
                let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
                let creationDate = attributes?[.creationDate] as? Date
                let modificationDate = attributes?[.modificationDate] as? Date
                let dateAddedRaw = fileURL.getExtendedAttribute(name: "com.apple.metadata:kMDItemDateAdded")
                
                try fileManager.moveItem(at: fileURL, to: targetURL)
                
                // Restore attributes on targetURL so "Date Added" is preserved exactly
                var newAttributes: [FileAttributeKey: Any] = [:]
                if let cDate = creationDate { newAttributes[.creationDate] = cDate }
                if let mDate = modificationDate { newAttributes[.modificationDate] = mDate }
                if !newAttributes.isEmpty {
                    try? fileManager.setAttributes(newAttributes, ofItemAtPath: targetURL.path)
                }
                if let dateAdded = dateAddedRaw {
                    targetURL.setExtendedAttribute(name: "com.apple.metadata:kMDItemDateAdded", data: dateAdded)
                }
                
                currentBatchMoves.append(FileMove(originalPath: fileURL.path, newPath: targetURL.path, creationDate: creationDate, modificationDate: modificationDate, dateAddedRaw: dateAddedRaw))
                filesMoved += 1
                affectedCategories.insert(categoryPath.lastPathComponent)
            }
            
            if filesMoved > 0 {
                HistoryManager.shared.addScan(moves: currentBatchMoves)
                sendNotification(filesMoved: filesMoved, categories: Array(affectedCategories))
                runPostScanCommand(filesMoved: filesMoved, source: sourceURL.path, output: outputURL.path)
            }
            
        } catch {
            print("Error organizing files: \(error.localizedDescription)")
        }
    }
    
    private func runPostScanCommand(filesMoved: Int, source: String, output: String) {
        guard let command = UserDefaults.standard.string(forKey: "postScanCommand"), !command.isEmpty else { return }
        
        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", command]
            
            var env = ProcessInfo.processInfo.environment
            env["FO_FILES_MOVED"] = "\(filesMoved)"
            env["FO_SOURCE"] = source
            env["FO_OUTPUT"] = output
            process.environment = env
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Error running post-scan command: \(error)")
            }
        }
    }
    
    private func determineCategoryPath(for ext: String, baseFolder: URL) -> URL {
        // Check normal categories
        for (category, extensions) in extensionMappings {
            if extensions.contains(ext) {
                return baseFolder.appendingPathComponent(category, isDirectory: true)
            }
        }
        
        // Check coding categories
        for (subCategory, extensions) in codingMappings {
            if extensions.contains(ext) {
                let codingFolder = baseFolder.appendingPathComponent("Coding", isDirectory: true)
                return codingFolder.appendingPathComponent(subCategory, isDirectory: true)
            }
        }
        
        // If it's a known development file but not categorized
        let otherCodingExtensions = ["asm", "r", "lua", "vbs", "asmx", "clj", "erl"]
        if otherCodingExtensions.contains(ext) {
             let codingFolder = baseFolder.appendingPathComponent("Coding", isDirectory: true)
             return codingFolder.appendingPathComponent("Other", isDirectory: true)
        }
        
        // For unknown files, return Misc folder
        return baseFolder.appendingPathComponent("Misc", isDirectory: true)
    }
    
    private func determineUniqueFileURL(for fileURL: URL, in destinationFolder: URL) -> URL {
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension
        
        var targetURL = destinationFolder.appendingPathComponent(fileURL.lastPathComponent)
        var counter = 1
        
        while fileManager.fileExists(atPath: targetURL.path) {
            let newFileName = "\(fileName) (\(counter)).\(ext)"
            targetURL = destinationFolder.appendingPathComponent(newFileName)
            counter += 1
        }
        
        return targetURL
    }
    
    private func sendNotification(filesMoved: Int, categories: [String]) {
        let content = UNMutableNotificationContent()
        content.title = "Files Organized"
        let categoryList = categories.joined(separator: ", ")
        content.body = "Successfully organized \(filesMoved) files into: \(categoryList)"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
}
