import AppKit

let path = "/Users/arhamsiva/.gemini/tmp/fileorganiser"
let url = URL(fileURLWithPath: path)
NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
