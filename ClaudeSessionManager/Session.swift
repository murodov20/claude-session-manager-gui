import Foundation

struct ClaudeSession: Identifiable, Hashable {
    let id: String          // session UUID
    let project: String     // project path
    let firstMessage: String
    let lastTimestamp: Date
    let messageCount: Int

    var projectName: String {
        URL(fileURLWithPath: project).lastPathComponent
    }
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

        var sessionsMap: [String: (project: String, firstMsg: String, firstTs: Double, lastTs: Double, count: Int)] = [:]

        for line in content.components(separatedBy: "\n") where !line.isEmpty {
            guard let lineData = line.data(using: .utf8),
                  let entry = try? JSONDecoder().decode(HistoryEntry.self, from: lineData),
                  let sid = entry.sessionId, !sid.isEmpty else { continue }

            let display = entry.display ?? ""
            let ts = entry.timestamp ?? 0
            let proj = entry.project ?? ""

            if var existing = sessionsMap[sid] {
                existing.count += 1
                if ts > existing.lastTs { existing.lastTs = ts }
                sessionsMap[sid] = existing
            } else {
                sessionsMap[sid] = (project: proj, firstMsg: display, firstTs: ts, lastTs: ts, count: 1)
            }
        }

        return sessionsMap.map { (sid, info) in
            ClaudeSession(
                id: sid,
                project: info.project,
                firstMessage: info.firstMsg.trimmingCharacters(in: .whitespacesAndNewlines),
                lastTimestamp: Date(timeIntervalSince1970: info.lastTs / 1000),
                messageCount: info.count
            )
        }
        .sorted { $0.lastTimestamp > $1.lastTimestamp }
    }
}
