import Foundation

enum DiagnosticLog {
    private static let queue = DispatchQueue(label: "InputLinkTips.DiagnosticLog")

    static var path: String {
        NSTemporaryDirectory() + "InputLinkTips.log"
    }

    static var previewTriggerPath: String {
        NSTemporaryDirectory() + "InputLinkTips.preview"
    }

    static func write(_ message: String) {
        let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"

        queue.async {
            let url = URL(fileURLWithPath: path)
            let data = Data(line.utf8)

            if !FileManager.default.fileExists(atPath: url.path) {
                _ = FileManager.default.createFile(atPath: url.path, contents: data)
                return
            }

            guard let handle = try? FileHandle(forWritingTo: url) else { return }
            defer { try? handle.close() }
            do {
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } catch {
                return
            }
        }
    }
}
