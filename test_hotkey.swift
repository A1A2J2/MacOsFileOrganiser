import Foundation
import Carbon

let keyMap: [String: UInt32] = [
    "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
    "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17, "1": 18, "2": 19,
    "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28,
    "0": 29, "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37, "j": 38,
    "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43, "/": 44, "n": 45, "m": 46, ".": 47
]

func checkHotkey(character: String, modIndex: Int) -> Bool {
    guard let char = character.lowercased().first else { return false }
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
    let hotKeyID = EventHotKeyID(signature: 1111, id: 1)
    let status = RegisterEventHotKey(keyCode, carbonFlags, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    
    if status == noErr {
        UnregisterEventHotKey(hotKeyRef)
        return false // not taken
    } else {
        return true // taken
    }
}

print("Cmd+Shift+3 taken?", checkHotkey(character: "3", modIndex: 1))
print("Cmd+Shift+O taken?", checkHotkey(character: "o", modIndex: 1))
print("Cmd+O taken?", checkHotkey(character: "o", modIndex: 0))
