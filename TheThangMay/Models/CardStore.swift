import Foundation
import Combine

/// Lưu trữ thẻ dưới dạng JSON trong thư mục Application Support.
final class CardStore: ObservableObject {
    @Published private(set) var cards: [HomeCard] = []

    private let fileURL: URL

    init() {
        let manager = FileManager.default
        let base = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? manager.temporaryDirectory
        let folder = base.appendingPathComponent("TheThangMay", isDirectory: true)
        try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("cards.json")
        load()
    }

    func card(with id: UUID) -> HomeCard? {
        cards.first { $0.id == id }
    }

    func add(_ card: HomeCard) {
        var newCard = card
        newCard.createdAt = Date()
        newCard.lastReadAt = card.lastReadAt ?? Date()
        cards.append(newCard)
        save()
    }

    func update(_ card: HomeCard) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index] = card
        save()
    }

    func delete(_ card: HomeCard) {
        cards.removeAll { $0.id == card.id }
        save()
    }

    func markRead(_ card: HomeCard) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index].lastReadAt = Date()
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            cards = HomeCard.samples
            save()
            return
        }
        if let decoded = try? JSONDecoder().decode([HomeCard].self, from: data) {
            cards = decoded
        } else {
            cards = []
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(cards) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
