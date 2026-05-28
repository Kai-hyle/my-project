import AppKit
import SwiftUI

struct DragReceiverView: View {
    @ObservedObject var store: ShelfStore
    @ObservedObject var state: NotchWindowState

    let onRequestExpand: () -> Void
    let onRequestCollapse: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            DragReceiverRepresentable(
                onDragEntered: {
                    state.isDragActive = true
                    onRequestExpand()
                },
                onDragUpdated: { mode in
                    state.activeDropMode = mode
                },
                onDragExited: {
                    state.isDragActive = false
                    state.activeDropMode = nil
                    if state.isHovering == false {
                        onRequestCollapse()
                    }
                },
                onDrop: { urls, mode in
                    state.isDragActive = false
                    state.activeDropMode = nil
                    store.addFiles(urls, mode: mode)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        if state.isHovering == false && state.isDragActive == false {
                            onRequestCollapse()
                        }
                    }
                },
                onClick: {
                    if state.isExpanded {
                        onRequestCollapse()
                    } else {
                        onRequestExpand()
                    }
                }
            )

            ShelfPanelView(
                store: store,
                isDragActive: state.isDragActive,
                activeDropMode: state.activeDropMode
            )
                .frame(width: 640, height: 198)
                .opacity(state.isExpanded ? 1 : 0)
                .scaleEffect(
                    x: state.isExpanded ? 1 : 0.48,
                    y: state.isExpanded ? 1 : 0.24,
                    anchor: .top
                )
                .allowsHitTesting(state.isExpanded)
                .animation(.spring(response: 0.28, dampingFraction: 0.86), value: state.isExpanded)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct DragReceiverRepresentable: NSViewRepresentable {
    let onDragEntered: () -> Void
    let onDragUpdated: (ShelfImportMode) -> Void
    let onDragExited: () -> Void
    let onDrop: ([URL], ShelfImportMode) -> Void
    let onClick: () -> Void

    func makeNSView(context: Context) -> ReceiverNSView {
        ReceiverNSView(
            onDragEntered: onDragEntered,
            onDragUpdated: onDragUpdated,
            onDragExited: onDragExited,
            onDrop: onDrop,
            onClick: onClick
        )
    }

    func updateNSView(_ nsView: ReceiverNSView, context: Context) {
        nsView.onDragEntered = onDragEntered
        nsView.onDragUpdated = onDragUpdated
        nsView.onDragExited = onDragExited
        nsView.onDrop = onDrop
        nsView.onClick = onClick
    }
}

private final class ReceiverNSView: NSView {
    var onDragEntered: () -> Void
    var onDragUpdated: (ShelfImportMode) -> Void
    var onDragExited: () -> Void
    var onDrop: ([URL], ShelfImportMode) -> Void
    var onClick: () -> Void

    init(
        onDragEntered: @escaping () -> Void,
        onDragUpdated: @escaping (ShelfImportMode) -> Void,
        onDragExited: @escaping () -> Void,
        onDrop: @escaping ([URL], ShelfImportMode) -> Void,
        onClick: @escaping () -> Void
    ) {
        self.onDragEntered = onDragEntered
        self.onDragUpdated = onDragUpdated
        self.onDragExited = onDragExited
        self.onDrop = onDrop
        self.onClick = onClick
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var isOpaque: Bool {
        false
    }

    override func mouseDown(with event: NSEvent) {
        onClick()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard fileURLs(from: sender).isEmpty == false else { return [] }
        onDragEntered()
        let mode = dropMode(for: sender)
        onDragUpdated(mode)
        return operation(for: mode)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard fileURLs(from: sender).isEmpty == false else { return [] }
        let mode = dropMode(for: sender)
        onDragUpdated(mode)
        return operation(for: mode)
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onDragExited()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = fileURLs(from: sender)
        guard urls.isEmpty == false else { return false }
        onDrop(urls, dropMode(for: sender))
        return true
    }

    private func dropMode(for draggingInfo: NSDraggingInfo) -> ShelfImportMode {
        convert(draggingInfo.draggingLocation, from: nil).x < bounds.midX ? .transfer : .copy
    }

    private func operation(for mode: ShelfImportMode) -> NSDragOperation {
        switch mode {
        case .transfer:
            .move
        case .copy:
            .copy
        }
    }

    private func fileURLs(from draggingInfo: NSDraggingInfo) -> [URL] {
        let pasteboard = draggingInfo.draggingPasteboard
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]
        let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: options) ?? []
        return objects.compactMap { ($0 as? URL)?.standardizedFileURL }
    }
}
