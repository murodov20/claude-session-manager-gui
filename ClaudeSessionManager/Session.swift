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

    static func fakeSessions() -> [ClaudeSession] {
        [
            ClaudeSession(
                id: "a1b2c3d4-1111-2222-3333-444455556666",
                project: "/Users/dev/projects/weather-app",
                firstMessage: "Add dark mode support and update the color palette for all screens",
                lastTimestamp: Date().addingTimeInterval(-300),
                messageCount: 12
            ),
            ClaudeSession(
                id: "b2c3d4e5-2222-3333-4444-555566667777",
                project: "/Users/dev/projects/api-gateway",
                firstMessage: "Fix rate limiting middleware to handle burst traffic correctly",
                lastTimestamp: Date().addingTimeInterval(-1800),
                messageCount: 8
            ),
            ClaudeSession(
                id: "c3d4e5f6-3333-4444-5555-666677778888",
                project: "/Users/dev/projects/blog-platform",
                firstMessage: "Implement markdown preview with syntax highlighting and image upload",
                lastTimestamp: Date().addingTimeInterval(-7200),
                messageCount: 23
            ),
            ClaudeSession(
                id: "d4e5f6a7-4444-5555-6666-777788889999",
                project: "/Users/dev/projects/mobile-app",
                firstMessage: "Set up push notifications for iOS and Android using Firebase",
                lastTimestamp: Date().addingTimeInterval(-18000),
                messageCount: 5
            ),
            ClaudeSession(
                id: "e5f6a7b8-5555-6666-7777-888899990000",
                project: "/Users/dev/projects/dashboard",
                firstMessage: "Create analytics dashboard with real-time charts and CSV export",
                lastTimestamp: Date().addingTimeInterval(-86400),
                messageCount: 31
            ),
        ]
    }
}
