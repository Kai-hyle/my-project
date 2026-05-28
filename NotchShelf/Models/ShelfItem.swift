import Foundation

enum ShelfImportMode: String, Codable, Equatable {
    case transfer
    case copy

    var title: String {
        switch self {
        case .transfer:
            return "Trans"
        case .copy:
            return "Copy"
        }
    }

    var subtitle: String {
        switch self {
        case .transfer:
            return "Move original here"
        case .copy:
            return "Keep original in place"
        }
    }
}

struct ShelfItem: Identifiable, Codable, Equatable {
    let id: UUID
    let url: URL
    let originalName: String
    let importMode: ShelfImportMode
    let addedAt: Date

    init(
        id: UUID = UUID(),
        url: URL,
        originalName: String,
        importMode: ShelfImportMode = .transfer,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.url = url.standardizedFileURL
        self.originalName = originalName
        self.importMode = importMode
        self.addedAt = addedAt
    }

    var displayName: String {
        originalName.isEmpty ? url.lastPathComponent : originalName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case originalName
        case importMode
        case addedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url).standardizedFileURL
        originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? url.lastPathComponent
        importMode = try container.decodeIfPresent(ShelfImportMode.self, forKey: .importMode) ?? .transfer
        addedAt = try container.decode(Date.self, forKey: .addedAt)
    }
}
