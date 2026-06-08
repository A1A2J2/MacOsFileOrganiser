import Foundation
import Carbon

let keyMap: [String: UInt32] = [
    "3": 20, "space": 49
]

func checkStatus(keyCode: UInt32, flags: UInt32) {
    var hotKeyRef: EventHotKeyRef?
    let hotKeyID = EventHotKeyID(signature: 1111, id: 1)
    let status = RegisterEventHotKey(keyCode, flags, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    print("Status for \(keyCode) with flags \(flags): \(status)")
    if status == noErr { UnregisterEventHotKey(hotKeyRef) }
}

checkStatus(keyCode: 20, flags: UInt32(cmdKey | shiftKey)) // Cmd+Shift+3
checkStatus(keyCode: 49, flags: UInt32(cmdKey)) // Cmd+Space
