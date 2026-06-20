import Foundation
import Combine

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [HistoryItem] = []

    private var fileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HoverAsk", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("history.json")
    }

    init() {
        load()
    }

    var storageSizeBytes: Int64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        return attributes?[.size] as? Int64 ?? 0
    }

    func add(prompt: String, answer: String, provider: AssistantProvider) {
        let item = HistoryItem(id: UUID(), createdAt: Date(), provider: provider, prompt: prompt, answer: answer)
        items.insert(item, at: 0)
        if items.count > 50 {
            items = Array(items.prefix(50))
        }
        save()
    }

    func clear() {
        items = []
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            items = []
            return
        }
        items = (try? JSONDecoder().decode([HistoryItem].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else {
            return
        }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
