import AppKit
import Foundation

@MainActor
final class ShelfStore: ObservableObject {
    @Published private(set) var items: [ShelfItem] = []

    private let defaultsKey = "BetterNorch.items"
    private let storageService = ShelfStorageService()

    init() {
        load()
    }

    func addFiles(_ urls: [URL], mode: ShelfImportMode) {
        let newItems = urls.compactMap { sourceURL -> ShelfItem? in
            let sourceURL = sourceURL.standardizedFileURL
            guard FileManager.default.fileExists(atPath: sourceURL.path) else { return nil }

            let id = UUID()
            guard let storedURL = try? storageService.importFile(from: sourceURL, id: id, mode: mode) else {
                return nil
            }

            return ShelfItem(
                id: id,
                url: storedURL,
                originalName: sourceURL.lastPathComponent,
                importMode: mode
            )
        }

        guard !newItems.isEmpty else { return }
        items.append(contentsOf: newItems)
        save()
    }

    func remove(_ item: ShelfItem) {
        try? storageService.moveToTrash(item.url)
        items.removeAll { $0.id == item.id }
        save()
    }

    func clear() {
        items.forEach { try? storageService.moveToTrash($0.url) }
        items.removeAll()
        save()
    }

    func moveToTrash(_ item: ShelfItem) {
        remove(item)
    }

    func removeFromShelfAfterExternalDrag(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func open(_ item: ShelfItem) {
        NSWorkspace.shared.open(item.url)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    func load() {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let decodedItems = try? JSONDecoder().decode([ShelfItem].self, from: data)
        else {
            items = []
            return
        }

        items = decodedItems.filter { FileManager.default.fileExists(atPath: $0.url.path) }
    }
}
