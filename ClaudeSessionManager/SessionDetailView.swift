import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var l10n = L10n.shared
    let session: ClaudeSession
    let onBack: () -> Void
    @State private var messages: [SessionMessage] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body)
                }
                .buttonStyle(.borderless)
                .help("Esc")

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.projectName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text(session.project)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(l10n.t(.msgs, session.messageCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Messages
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            } else if messages.isEmpty {
                Spacer()
                Text(l10n.t(.noMessagesFound))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { msg in
                                MessageBubble(message: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 300)
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                let loaded = SessionLoader.loadSessionMessages(session: session).reversed()
                DispatchQueue.main.async {
                    messages = Array(loaded)
                    isLoading = false
                }
            }
        }
        .background(
            Button("") { onBack() }
                .keyboardShortcut(.cancelAction)
                .hidden()
        )
    }
}

struct MessageBubble: View {
    let message: SessionMessage

    private var isUser: Bool { message.role == "user" }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.timestamp)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !isUser { Spacer(minLength: 20) }

            VStack(alignment: isUser ? .leading : .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: isUser ? "person.fill" : "sparkle")
                        .font(.caption2)
                        .foregroundColor(isUser ? .blue : .orange)
                    Text(isUser ? "You" : "Claude")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isUser ? .blue : .orange)
                    Text(timeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(message.content)
                    .font(.system(.body, design: isUser ? .default : .default))
                    .textSelection(.enabled)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isUser
                                  ? Color.blue.opacity(0.1)
                                  : Color.orange.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isUser
                                    ? Color.blue.opacity(0.2)
                                    : Color.orange.opacity(0.15), lineWidth: 0.5)
                    )
            }

            if isUser { Spacer(minLength: 20) }
        }
    }
}
