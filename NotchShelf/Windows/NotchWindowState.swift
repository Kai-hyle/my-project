import Foundation

@MainActor
final class NotchWindowState: ObservableObject {
    @Published var isExpanded = false
    @Published var isDragActive = false
    @Published var isHovering = false
    @Published var activeDropMode: ShelfImportMode?
}
