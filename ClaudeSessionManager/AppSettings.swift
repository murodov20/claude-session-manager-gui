import Foundation
import Carbon

struct HotkeyCombo: Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("\u{2303}") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("\u{2325}") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("\u{21E7}") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("\u{2318}") }
        parts.append(keyCodeName(keyCode))
        return parts.joined()
    }

    static let defaultToggle = HotkeyCombo(keyCode: UInt32(kVK_F12), modifiers: UInt32(cmdKey))
    static let defaultCopy = HotkeyCombo(keyCode: 44, modifiers: UInt32(cmdKey)) // Cmd+/
    static let defaultView = HotkeyCombo(keyCode: 31, modifiers: UInt32(cmdKey)) // Cmd+O
    static let defaultRefresh = HotkeyCombo(keyCode: 15, modifiers: UInt32(cmdKey)) // Cmd+R

    func save(prefix: String) {
        UserDefaults.standard.set(Int(keyCode), forKey: "\(prefix)_keyCode")
        UserDefaults.standard.set(Int(modifiers), forKey: "\(prefix)_modifiers")
    }

    static func load(prefix: String, fallback: HotkeyCombo) -> HotkeyCombo {
        guard UserDefaults.standard.object(forKey: "\(prefix)_keyCode") != nil else { return fallback }
        let kc = UserDefaults.standard.integer(forKey: "\(prefix)_keyCode")
        let mod = UserDefaults.standard.integer(forKey: "\(prefix)_modifiers")
        return HotkeyCombo(keyCode: UInt32(kc), modifiers: UInt32(mod))
    }
}

private func keyCodeName(_ keyCode: UInt32) -> String {
    let names: [UInt32: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\",
        43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
        48: "Tab", 49: "Space", 50: "`", 51: "Delete",
        53: "Esc", 36: "Return",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
        101: "F9", 103: "F11", 105: "F13", 107: "F14",
        109: "F10", 111: "F12", 113: "F15",
        118: "F4", 120: "F2", 122: "F1",
        123: "\u{2190}", 124: "\u{2192}", 125: "\u{2193}", 126: "\u{2191}",
    ]
    return names[keyCode] ?? "Key\(keyCode)"
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var toggleHotkey: HotkeyCombo
    @Published var copyHotkey: HotkeyCombo
    @Published var viewHotkey: HotkeyCombo
    @Published var refreshHotkey: HotkeyCombo
    @Published var sessionsFolder: String
    @Published var terminalCommand: String

    static let defaultSessionsFolder = "~/.claude"
    static let defaultTerminalCommand = """
        tell application "Terminal"
            activate
            do script "{cmd}"
        end tell
        """

    /// Expands ~ to the user's home directory
    var resolvedSessionsFolder: String {
        if sessionsFolder.hasPrefix("~") {
            return NSHomeDirectory() + sessionsFolder.dropFirst()
        }
        return sessionsFolder
    }

    private init() {
        self.toggleHotkey = HotkeyCombo.load(prefix: "hotkey_toggle", fallback: .defaultToggle)
        self.copyHotkey = HotkeyCombo.load(prefix: "hotkey_copy", fallback: .defaultCopy)
        self.viewHotkey = HotkeyCombo.load(prefix: "hotkey_view", fallback: .defaultView)
        self.refreshHotkey = HotkeyCombo.load(prefix: "hotkey_refresh", fallback: .defaultRefresh)
        self.sessionsFolder = UserDefaults.standard.string(forKey: "sessionsFolder") ?? Self.defaultSessionsFolder
        self.terminalCommand = UserDefaults.standard.string(forKey: "terminalCommand") ?? Self.defaultTerminalCommand
    }

    func save() {
        toggleHotkey.save(prefix: "hotkey_toggle")
        copyHotkey.save(prefix: "hotkey_copy")
        viewHotkey.save(prefix: "hotkey_view")
        refreshHotkey.save(prefix: "hotkey_refresh")
        UserDefaults.standard.set(sessionsFolder, forKey: "sessionsFolder")
        UserDefaults.standard.set(terminalCommand, forKey: "terminalCommand")
    }
}
