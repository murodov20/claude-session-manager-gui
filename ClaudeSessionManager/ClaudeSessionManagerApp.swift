import SwiftUI
import Carbon

@main
struct ClaudeSessionManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 650, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = createClaudeIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }

        registerGlobalHotKey()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(onHotkeyChanged), name: .hotkeyChanged, object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        unregisterGlobalHotKey()
    }

    @objc private func onHotkeyChanged() {
        unregisterGlobalHotKey()
        registerGlobalHotKey()
    }

    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        NotificationCenter.default.post(name: .refreshSessions, object: nil)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }

    // MARK: - Global Hotkey

    private func registerGlobalHotKey() {
        let combo = AppSettings.shared.toggleHotkey
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C5353), id: 1)

        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("Failed to register hotkey: \(status)")
            return
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                let delegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
                DispatchQueue.main.async {
                    delegate.togglePopover()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }

    private func unregisterGlobalHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }

    /// Creates a Claude-like sparkle icon for the menu bar
    private func createClaudeIcon() -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let cx = rect.midX
            let cy = rect.midY
            let r: CGFloat = size * 0.42

            let path = NSBezierPath()
            let points = 6
            for i in 0..<(points * 2) {
                let angle = (CGFloat(i) * .pi / CGFloat(points)) - .pi / 2
                let radius = i % 2 == 0 ? r : r * 0.38
                let x = cx + radius * cos(angle)
                let y = cy + radius * sin(angle)
                if i == 0 {
                    path.move(to: NSPoint(x: x, y: y))
                } else {
                    path.line(to: NSPoint(x: x, y: y))
                }
            }
            path.close()

            NSColor.controlTextColor.setFill()
            path.fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
