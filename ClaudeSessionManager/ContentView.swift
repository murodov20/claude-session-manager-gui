import SwiftUI

struct ContentView: View {
    @ObservedObject var l10n = L10n.shared
    @ObservedObject var settings = AppSettings.shared
    @State private var sessions: [ClaudeSession] = []
    @State private var searchText = ""
    @State private var selectedSession: ClaudeSession?
    @State private var cursorIndex: Int = 0
    @State private var showSettings = false
    @State private var viewingSession: ClaudeSession?
    @FocusState private var isSearchFocused: Bool

    var filteredSessions: [ClaudeSession] {
        if searchText.isEmpty { return sessions }
        let q = searchText.lowercased()
        return sessions.filter {
            $0.projectName.lowercased().contains(q) ||
            $0.firstMessage.lowercased().contains(q) ||
            $0.lastMessage.lowercased().contains(q) ||
            $0.project.lowercased().contains(q) ||
            $0.allPrompts.contains { $0.lowercased().contains(q) }
        }
    }

    var body: some View {
        if let session = viewingSession {
            SessionDetailView(session: session, onBack: { viewingSession = nil })
        } else if showSettings {
            SettingsView(
                onSave: {
                    showSettings = false
                    NotificationCenter.default.post(name: .hotkeyChanged, object: nil)
                },
                onCancel: { showSettings = false }
            )
        } else {
            mainView
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(l10n.t(.appTitle))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                HStack(spacing: 8) {
                    Button(action: { sessions = SessionLoader.loadSessions() }) {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.borderless)
                    .help(l10n.t(.refreshSessions))

                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.borderless)
                    .help(l10n.t(.settings))

                    Button(action: { NSApp.terminate(nil) }) {
                        Image(systemName: "power")
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.borderless)
                    .help(l10n.t(.quit))
                }
            }
            .padding()

            // Search — always focused
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(l10n.t(.searchPlaceholder), text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .onChange(of: isSearchFocused) { _, focused in
                        if !focused {
                            DispatchQueue.main.async { isSearchFocused = true }
                        }
                    }
                    .onChange(of: searchText) {
                        cursorIndex = 0
                    }
                    .onSubmit {
                        let list = filteredSessions
                        if !list.isEmpty && cursorIndex < list.count {
                            openSessionInTerminal(list[cursorIndex])
                        }
                    }
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // Session list
            if filteredSessions.isEmpty {
                Spacer()
                Text(sessions.isEmpty ? l10n.t(.noSessionsFound) : l10n.t(.noMatchingFound))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    List(Array(filteredSessions.enumerated()), id: \.element.id, selection: $selectedSession) { index, session in
                        SessionRow(
                            session: session,
                            isCursored: index == cursorIndex,
                            onView: { viewingSession = session }
                        )
                        .id(session.id)
                        .onTapGesture(count: 2) {
                            openSessionInTerminal(session)
                        }
                        .onTapGesture(count: 1) {
                            cursorIndex = index
                        }
                        .contentShape(Rectangle())
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                    .onChange(of: cursorIndex) { _, newIndex in
                        let list = filteredSessions
                        if newIndex >= 0 && newIndex < list.count {
                            withAnimation {
                                proxy.scrollTo(list[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                Text(l10n.t(.sessionsCount, filteredSessions.count))
                    .foregroundColor(.secondary)
                    .font(.caption)
                Spacer()
                Button("GitHub") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/murodov20/claude-session-manager-gui")!)
                }
                .controlSize(.small)

                if !filteredSessions.isEmpty && cursorIndex < filteredSessions.count {
                    Button(l10n.t(.openInTerminal)) {
                        openSessionInTerminal(filteredSessions[cursorIndex])
                    }
                    .controlSize(.small)
                }
            }
            .padding(8)
            .padding(.horizontal, 4)
        }
        .frame(minWidth: 500, minHeight: 300)
        .onAppear {
            sessions = SessionLoader.loadSessions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                return handleKeyEvent(event)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshSessions)) { _ in
            sessions = SessionLoader.loadSessions()
        }
        .background(
            Group {
                Button("") { copyCurrentSessionCommand() }
                    .keyboardShortcut("/", modifiers: .command)
                Button("") { sessions = SessionLoader.loadSessions() }
                    .keyboardShortcut("r", modifiers: .command)
                Button("") { showSettings = true }
                    .keyboardShortcut(",", modifiers: .command)
                Button("") { viewCurrentSession() }
                    .keyboardShortcut("o", modifiers: .command)
            }
            .hidden()
        )
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let list = filteredSessions
        guard !list.isEmpty else { return event }

        switch event.keyCode {
        case 125: // Down arrow
            if cursorIndex < list.count - 1 {
                cursorIndex += 1
            }
            return nil
        case 126: // Up arrow
            if cursorIndex > 0 {
                cursorIndex -= 1
            }
            return nil
        default:
            return event
        }
    }

    private func copyCurrentSessionCommand() {
        let list = filteredSessions
        guard !list.isEmpty && cursorIndex < list.count else { return }
        let session = list[cursorIndex]
        let cmd = "cd \(session.project) && claude -r \(session.id)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cmd, forType: .string)
    }

    private func viewCurrentSession() {
        let list = filteredSessions
        guard !list.isEmpty && cursorIndex < list.count else { return }
        viewingSession = list[cursorIndex]
    }

    private func openSessionInTerminal(_ session: ClaudeSession) {
        let sessionCmd = "cd \(session.project) && claude -r \(session.id)"
        let template = settings.terminalCommand
        let script = template.replacingOccurrences(of: "{cmd}", with: sessionCmd)

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            }
        }
    }
}

struct SessionRow: View {
    @ObservedObject var l10n = L10n.shared
    let session: ClaudeSession
    let isCursored: Bool
    let onView: () -> Void

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: session.lastTimestamp, relativeTo: Date())
    }

    private var resumeCommand: String {
        "cd \(session.project) && claude -r \(session.id)"
    }

    private var copyHotkeyLabel: String {
        AppSettings.shared.copyHotkey.displayString
    }

    private var viewHotkeyLabel: String {
        AppSettings.shared.viewHotkey.displayString
    }

    var body: some View {
        HStack(spacing: 8) {
            // Cursor indicator
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(isCursored ? .accentColor : .clear)
                .frame(width: 8)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                    Text(session.projectName)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(session.lastMessage.isEmpty ? l10n.t(.empty) : session.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Text(session.project)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                    Spacer()
                    Text(l10n.t(.msgs, session.messageCount))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // View button
            Button(action: onView) {
                Image(systemName: "eye")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.borderless)
            .help(l10n.t(.viewSession) + " (\(viewHotkeyLabel))")

            // Copy button
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(resumeCommand, forType: .string)
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "doc.on.doc")
                    Text(copyHotkeyLabel)
                        .font(.system(size: 9))
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
            }
            .buttonStyle(.borderless)
            .help(l10n.t(.copyHotkey) + " (\(copyHotkeyLabel))")
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isCursored ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}

extension Notification.Name {
    static let hotkeyChanged = Notification.Name("hotkeyChanged")
    static let refreshSessions = Notification.Name("refreshSessions")
}

#Preview {
    ContentView()
}
