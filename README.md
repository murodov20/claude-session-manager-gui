# Claude Session Manager

A lightweight macOS menu bar app for browsing and resuming [Claude Code](https://docs.anthropic.com/en/docs/claude-code) sessions.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.0-orange) ![License](https://img.shields.io/badge/license-MIT-green) ![Version](https://img.shields.io/badge/version-0.0.1-brightgreen)

## Features

- **Menu bar app** — lives in the macOS menu bar, no Dock icon
- **Session list** — reads all Claude Code sessions from `~/.claude/history.jsonl`
- **Search** — filter sessions by project name, path, or message content
- **Keyboard navigation** — arrow keys to move cursor, Enter to open session
- **Double-click** — opens a Terminal window and resumes the selected session
- **Copy command** — copy the resume command (`cd <project> && claude -r <session-id>`) to clipboard
- **Global hotkey** — toggle the popover from anywhere (default: `Cmd+F12`)
- **Localization** — English, Russian, Arabic, and Uzbek
- **Settings** — configurable hotkeys, session folder path, terminal command, and language

## Requirements

- macOS 14.0+
- Xcode 15.0+
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed

## Installation

```bash
brew tap murodov20/tap
brew install --cask claude-session-manager
```

## Build from source

1. Clone the repository:
   ```bash
   git clone https://github.com/murodov20/claude-session-manager-gui.git
   cd claude-session-manager-gui
   ```

2. Build with Xcode:
   ```bash
   xcodebuild -scheme ClaudeSessionManager -configuration Release build
   ```

3. Or open in Xcode:
   ```bash
   open ClaudeSessionManager.xcodeproj
   ```
   Then press `Cmd+R` to build and run.

4. The built app will be in:
   ```
   ~/Library/Developer/Xcode/DerivedData/ClaudeSessionManager-*/Build/Products/Release/ClaudeSessionManager.app
   ```
   Copy it to `/Applications` for permanent use.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+F12` | Toggle popover (global, works from any app) |
| `Cmd+/` | Copy resume command for selected session |
| `Cmd+R` | Refresh session list |
| `Cmd+,` | Open settings |
| `Up/Down` | Navigate session list |
| `Enter` | Open selected session in Terminal |
| `Esc` | Cancel hotkey recording (in settings) |

All hotkeys can be customized in Settings.

## Custom Terminal

By default, sessions open in the built-in macOS Terminal. You can change this in Settings by modifying the AppleScript template. Use `{cmd}` as a placeholder for the session command.

**iTerm2 example:**
```applescript
tell application "iTerm2"
    activate
    create window with default profile command "{cmd}"
end tell
```

## Note

This project was almost entirely written with the help of AI ([Claude Code](https://docs.anthropic.com/en/docs/claude-code)). If you find any bugs or issues, feel free to open a PR — contributions are welcome!

## License

[MIT](LICENSE)
