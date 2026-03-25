import Foundation

struct ClaudeSession: Identifiable, Hashable {
    let id: String          // session UUID
    let project: String     // project path
    let firstMessage: String
    let lastMessage: String
    let lastTimestamp: Date
    let messageCount: Int
    let allPrompts: [String] // all user prompts for deep search

    var projectName: String {
        URL(fileURLWithPath: project).lastPathComponent
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ClaudeSession, rhs: ClaudeSession) -> Bool {
        lhs.id == rhs.id
    }
}

struct SessionMessage: Identifiable {
    let id = UUID()
    let role: String        // "user" or "assistant"
    let content: String
    let timestamp: Date
}

class SessionLoader {
    static func loadSessions() -> [ClaudeSession] {
        let folder = AppSettings.shared.resolvedSessionsFolder
        let historyPath = folder + "/history.jsonl"
        guard let data = FileManager.default.contents(atPath: historyPath),
              let content = String(data: data, encoding: .utf8) else {
            return []
        }

        struct HistoryEntry: Decodable {
            let display: String?
            let timestamp: Double?
            let project: String?
            let sessionId: String?
        }

        var sessionsMap: [String: (project: String, firstMsg: String, lastMsg: String, firstTs: Double, lastTs: Double, count: Int, prompts: [String])] = [:]

        for line in content.components(separatedBy: "\n") where !line.isEmpty {
            guard let lineData = line.data(using: .utf8),
                  let entry = try? JSONDecoder().decode(HistoryEntry.self, from: lineData),
                  let sid = entry.sessionId, !sid.isEmpty else { continue }

            let display = entry.display ?? ""
            let ts = entry.timestamp ?? 0
            let proj = entry.project ?? ""

            if var existing = sessionsMap[sid] {
                existing.count += 1
                if ts > existing.lastTs {
                    existing.lastTs = ts
                    existing.lastMsg = display
                }
                existing.prompts.append(display)
                sessionsMap[sid] = existing
            } else {
                sessionsMap[sid] = (project: proj, firstMsg: display, lastMsg: display, firstTs: ts, lastTs: ts, count: 1, prompts: [display])
            }
        }

        return sessionsMap.map { (sid, info) in
            ClaudeSession(
                id: sid,
                project: info.project,
                firstMessage: info.firstMsg.trimmingCharacters(in: .whitespacesAndNewlines),
                lastMessage: info.lastMsg.trimmingCharacters(in: .whitespacesAndNewlines),
                lastTimestamp: Date(timeIntervalSince1970: info.lastTs / 1000),
                messageCount: info.count,
                allPrompts: info.prompts
            )
        }
        .sorted { $0.lastTimestamp > $1.lastTimestamp }
    }

    /// Load full session messages from the session JSONL file
    static func loadSessionMessages(session: ClaudeSession) -> [SessionMessage] {
        let folder = AppSettings.shared.resolvedSessionsFolder
        // Project path encoded: /Users/foo/bar -> -Users-foo-bar
        let encodedProject = session.project.replacingOccurrences(of: "/", with: "-")
        let sessionFile = "\(folder)/projects/\(encodedProject)/\(session.id).jsonl"

        guard let data = FileManager.default.contents(atPath: sessionFile),
              let content = String(data: data, encoding: .utf8) else {
            return []
        }

        var messages: [SessionMessage] = []

        for line in content.components(separatedBy: "\n") where !line.isEmpty {
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else { continue }

            guard let type = json["type"] as? String,
                  (type == "user" || type == "assistant"),
                  let message = json["message"] as? [String: Any],
                  let role = message["role"] as? String else { continue }

            let timestampStr = json["timestamp"] as? String ?? ""
            let timestamp = ISO8601DateFormatter().date(from: timestampStr) ?? Date()

            var text = ""
            if let contentStr = message["content"] as? String {
                text = contentStr
            } else if let contentArr = message["content"] as? [[String: Any]] {
                let textBlocks = contentArr.compactMap { block -> String? in
                    guard let blockType = block["type"] as? String, blockType == "text",
                          let blockText = block["text"] as? String else { return nil }
                    return blockText
                }
                text = textBlocks.joined(separator: "\n")
            }

            guard !text.isEmpty else { continue }

            // Skip duplicate messages (assistant messages can appear multiple times as they stream)
            if role == "assistant", let last = messages.last, last.role == "assistant" {
                messages[messages.count - 1] = SessionMessage(role: role, content: text, timestamp: timestamp)
            } else {
                messages.append(SessionMessage(role: role, content: text, timestamp: timestamp))
            }
        }

        return messages
    }
}
