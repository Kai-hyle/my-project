import Foundation

enum ShelfStorageError: Error {
    case applicationSupportDirectoryUnavailable
    case missingFileName
}

struct ShelfStorageService {
    private let fileManager = FileManager.default

    var shelfDirectory: URL {
        get throws {
            guard let applicationSupportDirectory = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                throw ShelfStorageError.applicationSupportDirectoryUnavailable
            }

            let directory = applicationSupportDirectory
                .appendingPathComponent("Better Norch", isDirectory: true)
                .appendingPathComponent("ShelfItems", isDirectory: true)

            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory
        }
    }

    func importFile(from sourceURL: URL, id: UUID, mode: ShelfImportMode) throws -> URL {
        let sourceURL = sourceURL.standardizedFileURL
        let originalName = sourceURL.lastPathComponent
        guard originalName.isEmpty == false else {
            throw ShelfStorageError.missingFileName
        }

        let itemDirectory = try shelfDirectory
            .appendingPathComponent(id.uuidString, isDirectory: true)
            .standardizedFileURL

        if fileManager.fileExists(atPath: itemDirectory.path) {
            try fileManager.removeItem(at: itemDirectory)
        }

        try fileManager.createDirectory(at: itemDirectory, withIntermediateDirectories: true)

        let destinationURL = itemDirectory
            .appendingPathComponent(originalName)
            .standardizedFileURL

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        switch mode {
        case .transfer:
            do {
                try fileManager.moveItem(at: sourceURL, to: destinationURL)
            } catch {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                try moveToTrash(sourceURL)
            }
        case .copy:
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }

        return destinationURL
    }

    func moveToTrash(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        _ = try fileManager.trashItem(at: url, resultingItemURL: nil)
    }
}
