import AppKit

enum FileIconService {
    static func icon(for url: URL) -> NSImage {
        let image = NSWorkspace.shared.icon(forFile: url.path)
        image.size = NSSize(width: 44, height: 44)
        return image
    }
}
