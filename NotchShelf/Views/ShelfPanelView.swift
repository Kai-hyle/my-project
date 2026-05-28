import AppKit
import SwiftUI

struct ShelfPanelView: View {
    @ObservedObject var store: ShelfStore
    @Environment(\.colorScheme) private var colorScheme
    let isDragActive: Bool
    let activeDropMode: ShelfImportMode?
    private let panelShape = UnevenRoundedRectangle(
        topLeadingRadius: 0,
        bottomLeadingRadius: 36,
        bottomTrailingRadius: 36,
        topTrailingRadius: 0,
        style: .continuous
    )
    private var theme: ShelfPanelTheme {
        ShelfPanelTheme(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            panelShape
                .fill(theme.panelFill)
                .shadow(color: theme.primaryShadow, radius: 28, x: 0, y: 16)
                .shadow(color: theme.secondaryShadow, radius: 8, x: 0, y: 4)

            panelShape
                .fill(theme.panelFill)
                .overlay(
                    panelShape
                        .fill(
                            LinearGradient(
                                colors: theme.panelGradient,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    VStack {
                        Rectangle()
                            .fill(theme.topHairline)
                            .frame(height: 1)
                        Spacer()
                    }
                )
                .overlay(
                    panelShape
                        .strokeBorder(isDragActive ? theme.activeStroke : theme.stroke, lineWidth: 1)
                )
                .overlay(
                    panelShape
                        .strokeBorder(theme.innerStroke, lineWidth: 0.5)
                        .padding(1)
                )
                .clipShape(panelShape)

            HStack(spacing: 10) {
                DropZoneView(
                    mode: .transfer,
                    items: items(for: .transfer),
                    store: store,
                    theme: theme,
                    isActive: activeDropMode == .transfer,
                    isDragActive: isDragActive
                )

                Rectangle()
                    .fill(theme.divider)
                    .frame(width: 1)
                    .padding(.vertical, 30)

                DropZoneView(
                    mode: .copy,
                    items: items(for: .copy),
                    store: store,
                    theme: theme,
                    isActive: activeDropMode == .copy,
                    isDragActive: isDragActive
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)
        }
        .background(.clear)
    }

    private func items(for mode: ShelfImportMode) -> [ShelfItem] {
        store.items.filter { $0.importMode == mode }
    }
}

private struct DropZoneView: View {
    let mode: ShelfImportMode
    let items: [ShelfItem]
    @ObservedObject var store: ShelfStore
    let theme: ShelfPanelTheme
    let isActive: Bool
    let isDragActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if mode == .copy {
                    Spacer(minLength: 0)
                }

                Image(systemName: mode == .transfer ? "arrow.right.doc.on.clipboard" : "doc.on.doc")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isActive ? theme.zoneActiveText : theme.secondaryText)

                Text(mode.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isActive ? theme.zoneActiveText : theme.primaryText)

                Text(mode.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if mode == .transfer {
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: mode == .copy ? .trailing : .leading)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isActive ? theme.zoneActiveFill : theme.zoneFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isActive ? theme.zoneActiveStroke : theme.zoneStroke, lineWidth: 1)
                    )

                if items.isEmpty {
                    VStack(spacing: 7) {
                        Image(systemName: mode == .transfer ? "tray.and.arrow.down.fill" : "plus.square.on.square")
                            .font(.system(size: 18, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(isDragActive ? theme.secondaryText : theme.tertiaryText)

                        Text(isDragActive ? "Drop here" : "Empty")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.secondaryText)
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(items) { item in
                                ShelfItemView(item: item, store: store, theme: theme)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ShelfItemView: View {
    let item: ShelfItem
    @ObservedObject var store: ShelfStore
    let theme: ShelfPanelTheme
    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Image(nsImage: FileIconService.icon(for: item.url))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)

                Text(item.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 76, height: 30, alignment: .top)
            }
            .frame(width: 86, height: 104)

            DraggableShelfItemView(
                item: item,
                onOpen: {
                    store.open(item)
                },
                onMoveToTrash: {
                    store.moveToTrash(item)
                },
                onDragCompleted: {
                    store.removeFromShelfAfterExternalDrag(item)
                }
            )
            .frame(width: 86, height: 104)

            Button {
                store.moveToTrash(item)
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.deleteIcon)
                    .frame(width: 22, height: 22)
                    .background(theme.deleteButtonFill, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.deleteButtonStroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Move to Trash")
            .opacity(isHovering ? 1 : 0)
            .scaleEffect(isHovering ? 1 : 0.82)
            .animation(.spring(response: 0.18, dampingFraction: 0.78), value: isHovering)
        }
        .frame(width: 86, height: 104)
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isHovering ? theme.itemHoverFill : .white.opacity(0.001))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isHovering ? theme.itemHoverStroke : .clear, lineWidth: 1)
                )
        }
        .onHover { isHovering = $0 }
    }
}

private struct ShelfPanelTheme {
    let colorScheme: ColorScheme

    var isDark: Bool {
        colorScheme == .dark
    }

    var panelFill: Color {
        isDark ? .black.opacity(0.58) : .white.opacity(0.64)
    }

    var panelGradient: [Color] {
        if isDark {
            return [
                .white.opacity(0.18),
                .white.opacity(0.04),
                .black.opacity(0.18)
            ]
        }

        return [
            .white.opacity(0.54),
            .white.opacity(0.22),
            .black.opacity(0.05)
        ]
    }

    var topHairline: Color {
        isDark ? .white.opacity(0.12) : .white.opacity(0.42)
    }

    var stroke: Color {
        isDark ? .white.opacity(0.18) : .white.opacity(0.58)
    }

    var activeStroke: Color {
        isDark ? .white.opacity(0.42) : .black.opacity(0.2)
    }

    var innerStroke: Color {
        isDark ? .black.opacity(0.3) : .black.opacity(0.08)
    }

    var primaryShadow: Color {
        isDark ? .black.opacity(0.36) : .black.opacity(0.16)
    }

    var secondaryShadow: Color {
        isDark ? .black.opacity(0.24) : .white.opacity(0.28)
    }

    var primaryText: Color {
        isDark ? .white.opacity(0.84) : .black.opacity(0.74)
    }

    var secondaryText: Color {
        isDark ? .white.opacity(0.7) : .black.opacity(0.46)
    }

    var tertiaryText: Color {
        isDark ? .white.opacity(0.42) : .black.opacity(0.3)
    }

    var divider: Color {
        isDark ? .white.opacity(0.12) : .black.opacity(0.08)
    }

    var zoneFill: Color {
        isDark ? .white.opacity(0.045) : .white.opacity(0.28)
    }

    var zoneStroke: Color {
        isDark ? .white.opacity(0.08) : .black.opacity(0.06)
    }

    var zoneActiveFill: Color {
        isDark ? .white.opacity(0.14) : .white.opacity(0.62)
    }

    var zoneActiveStroke: Color {
        isDark ? .white.opacity(0.34) : .black.opacity(0.16)
    }

    var zoneActiveText: Color {
        isDark ? .white.opacity(0.96) : .black.opacity(0.84)
    }

    var itemHoverFill: Color {
        isDark ? .white.opacity(0.12) : .black.opacity(0.06)
    }

    var itemHoverStroke: Color {
        isDark ? .white.opacity(0.16) : .black.opacity(0.08)
    }

    var deleteIcon: Color {
        isDark ? .white.opacity(0.92) : .black.opacity(0.74)
    }

    var deleteButtonFill: Color {
        isDark ? .black.opacity(0.42) : .white.opacity(0.72)
    }

    var deleteButtonStroke: Color {
        isDark ? .white.opacity(0.18) : .black.opacity(0.12)
    }
}

private struct DraggableShelfItemView: NSViewRepresentable {
    let item: ShelfItem
    let onOpen: () -> Void
    let onMoveToTrash: () -> Void
    let onDragCompleted: () -> Void

    func makeNSView(context: Context) -> DraggableShelfItemNSView {
        DraggableShelfItemNSView(
            item: item,
            onOpen: onOpen,
            onMoveToTrash: onMoveToTrash,
            onDragCompleted: onDragCompleted
        )
    }

    func updateNSView(_ nsView: DraggableShelfItemNSView, context: Context) {
        nsView.item = item
        nsView.onOpen = onOpen
        nsView.onMoveToTrash = onMoveToTrash
        nsView.onDragCompleted = onDragCompleted
    }
}

private final class DraggableShelfItemNSView: NSView, NSDraggingSource {
    var item: ShelfItem
    var onOpen: () -> Void
    var onMoveToTrash: () -> Void
    var onDragCompleted: () -> Void

    private var isDragging = false

    init(
        item: ShelfItem,
        onOpen: @escaping () -> Void,
        onMoveToTrash: @escaping () -> Void,
        onDragCompleted: @escaping () -> Void
    ) {
        self.item = item
        self.onOpen = onOpen
        self.onMoveToTrash = onMoveToTrash
        self.onDragCompleted = onDragCompleted
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var isOpaque: Bool {
        false
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onOpen()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Open", action: #selector(openFromMenu), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let trashItem = NSMenuItem(title: "Move to Trash", action: #selector(moveToTrashFromMenu), keyEquivalent: "")
        trashItem.target = self
        menu.addItem(trashItem)

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging == false else { return }
        guard FileManager.default.fileExists(atPath: item.url.path) else { return }

        isDragging = true

        let draggingItem = NSDraggingItem(pasteboardWriter: item.url as NSURL)
        let image = FileIconService.icon(for: item.url)
        let draggingFrame = NSRect(
            x: bounds.midX - 24,
            y: bounds.midY - 24,
            width: 48,
            height: 48
        )
        draggingItem.setDraggingFrame(draggingFrame, contents: image)

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        isDragging = false

        guard operation != [] else { return }
        DispatchQueue.main.async { [onDragCompleted] in
            onDragCompleted()
        }
    }

    @objc private func openFromMenu() {
        onOpen()
    }

    @objc private func moveToTrashFromMenu() {
        onMoveToTrash()
    }
}
