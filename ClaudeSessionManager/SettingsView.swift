import SwiftUI
import Carbon

struct SettingsView: View {
    @ObservedObject var l10n = L10n.shared
    @ObservedObject var settings = AppSettings.shared
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var selectedLanguage: AppLanguage
    @State private var toggleHotkey: HotkeyCombo
    @State private var copyHotkey: HotkeyCombo
    @State private var viewHotkey: HotkeyCombo
    @State private var refreshHotkey: HotkeyCombo
    @State private var sessionsFolder: String
    @State private var terminalCommand: String
    @State private var recordingHotkey: RecordingTarget?

    enum RecordingTarget {
        case toggle, copy, view, refresh
    }

    init(onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.onSave = onSave
        self.onCancel = onCancel
        let s = AppSettings.shared
        _selectedLanguage = State(initialValue: L10n.shared.current)
        _toggleHotkey = State(initialValue: s.toggleHotkey)
        _copyHotkey = State(initialValue: s.copyHotkey)
        _viewHotkey = State(initialValue: s.viewHotkey)
        _refreshHotkey = State(initialValue: s.refreshHotkey)
        _sessionsFolder = State(initialValue: s.sessionsFolder)
        _terminalCommand = State(initialValue: s.terminalCommand)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "chevron.left")
                        .font(.body)
                }
                .buttonStyle(.borderless)
                Text(l10n.t(.settings))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Language
                    settingSection(l10n.t(.language)) {
                        Picker("", selection: $selectedLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 200)
                        .onChange(of: selectedLanguage) { _, newLang in
                            l10n.current = newLang
                        }
                    }

                    Divider()

                    // Hotkeys
                    settingSection(l10n.t(.globalHotkey)) {
                        hotkeyRow(label: l10n.t(.globalHotkey), combo: $toggleHotkey, target: .toggle)
                        hotkeyRow(label: l10n.t(.copyHotkey), combo: $copyHotkey, target: .copy)
                        hotkeyRow(label: l10n.t(.viewSession), combo: $viewHotkey, target: .view)
                        hotkeyRow(label: l10n.t(.refreshHotkey), combo: $refreshHotkey, target: .refresh)
                    }

                    Divider()

                    // Sessions folder
                    settingSection(l10n.t(.sessionsFolder)) {
                        HStack {
                            TextField("", text: $sessionsFolder)
                                .textFieldStyle(.roundedBorder)
                            Button(l10n.t(.browseFolder)) {
                                let panel = NSOpenPanel()
                                panel.canChooseDirectories = true
                                panel.canChooseFiles = false
                                panel.allowsMultipleSelection = false
                                if panel.runModal() == .OK, let url = panel.url {
                                    sessionsFolder = url.path
                                }
                            }
                            .controlSize(.small)
                        }
                    }

                    Divider()

                    // Terminal command
                    settingSection(l10n.t(.terminalCommand)) {
                        TextEditor(text: $terminalCommand)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 80)
                            .border(Color(nsColor: .separatorColor), width: 0.5)
                        Text(l10n.t(.terminalCommandHint))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button(l10n.t(.resetDefault)) {
                            terminalCommand = AppSettings.defaultTerminalCommand
                        }
                        .controlSize(.small)
                    }
                }
                .padding()
            }

            Divider()

            // Footer buttons
            HStack {
                Spacer()
                Button(l10n.t(.cancel)) { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Button(l10n.t(.save)) { saveSettings() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func settingSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    @ViewBuilder
    private func hotkeyRow(label: String, combo: Binding<HotkeyCombo>, target: RecordingTarget) -> some View {
        HStack {
            Text(label)
                .frame(width: 160, alignment: .leading)

            if recordingHotkey == target {
                Text(l10n.t(.pressHotkey))
                    .foregroundColor(.orange)
                    .frame(width: 200, alignment: .leading)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.orange, lineWidth: 1)
                    )
                    .onAppear {
                        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                            if event.keyCode == 53 { // Esc
                                recordingHotkey = nil
                                return nil
                            }
                            let mods = carbonModifiers(from: event.modifierFlags)
                            if mods != 0 {
                                combo.wrappedValue = HotkeyCombo(keyCode: UInt32(event.keyCode), modifiers: mods)
                                recordingHotkey = nil
                            }
                            return nil
                        }
                    }
            } else {
                Button(combo.wrappedValue.displayString) {
                    recordingHotkey = target
                }
                .frame(width: 200, alignment: .leading)
            }
        }
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        return mods
    }

    private func saveSettings() {
        settings.toggleHotkey = toggleHotkey
        settings.copyHotkey = copyHotkey
        settings.viewHotkey = viewHotkey
        settings.refreshHotkey = refreshHotkey
        settings.sessionsFolder = sessionsFolder
        settings.terminalCommand = terminalCommand
        settings.save()
        onSave()
    }
}
