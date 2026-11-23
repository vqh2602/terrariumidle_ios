import Foundation

/// Persistent delivery queue. A failed webhook does not roll back or duplicate a successful like.
@MainActor
final class GardenLikeReporter {
    static let shared = GardenLikeReporter()

    private struct Report: Codable, Identifiable {
        let id: UUID
        let viewerID: String
        let gardenID: String
        let total: Int
        var content: String { "Like by user: \(viewerID)\n Like:\(gardenID) \n Total Like: \(total)" }
    }

    private let queueKey = "garden.likeReports.pending"
    private let defaults = UserDefaults.standard
    private var reports: [Report] = []
    private var delivery: Task<Void, Never>?
    private let webhook = URL(string: "https://discord.com/api/webhooks/1574253065899614420/cBYFx-8ZrbnVuJBkkv_IXPB6vUggzWSuYAT0Mp_IwF1VqO2E9rLZHM3cxKjVeIlP_Ha3?wait=true")!

    private init() {
        if let data = defaults.data(forKey: queueKey), let saved = try? JSONDecoder().decode([Report].self, from: data) {
            reports = saved
        }
    }

    func enqueue(viewerID: String, gardenID: String, total: Int) {
        reports.append(Report(id: UUID(), viewerID: viewerID, gardenID: gardenID, total: total))
        persist()
        retryPending()
    }

    func retryPending() {
        guard delivery == nil, !reports.isEmpty else { return }
        delivery = Task {
            defer { delivery = nil }
            while let report = reports.first {
                var sent = false
                for attempt in 0..<2 {
                    do {
                        try await send(report)
                        sent = true
                        break
                    } catch {
                        if attempt == 0 {
                            do { try await Task.sleep(for: .seconds(3)) } catch { return }
                        }
                    }
                }
                guard sent else { return } // Retain for the next visit or app launch.
                reports.removeAll { $0.id == report.id }
                persist()
            }
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(reports) { defaults.set(data, forKey: queueKey) }
    }

    private func send(_ report: Report) async throws {
        let safeID = report.viewerID.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        let filename = "text_file_\(safeID).txt"
        let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                   appropriateFor: nil, create: true)
        let file = directory.appendingPathComponent(filename)
        try report.content.write(to: file, atomically: true, encoding: .utf8)
        let boundary = "Terrarium-\(UUID().uuidString)"
        let payload: [String: Any] = [
            "content": "like\n\(report.content)",
            "allowed_mentions": ["parse": [String]()],
            "attachments": [["id": 0, "filename": filename]]
        ]
        var body = Data()
        body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"payload_json\"\r\nContent-Type: application/json\r\n\r\n".utf8))
        body.append(try JSONSerialization.data(withJSONObject: payload))
        body.append(Data("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"files[0]\"; filename=\"\(filename)\"\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n".utf8))
        body.append(try Data(contentsOf: file))
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        var request = URLRequest(url: webhook, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
