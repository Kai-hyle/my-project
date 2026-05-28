import AppKit
import SwiftUI

@MainActor
final class NotchWindowController: NSWindowController {
    private let store: ShelfStore
    private let state = NotchWindowState()
    private var localPointerMonitor: Any?
    private var globalPointerMonitor: Any?
    private var collapseTask: DispatchWorkItem?

    private let expandedSize = NSSize(width: 640, height: 198)
    private var collapsedSize: NSSize {
        Self.notchTriggerSize(for: NSScreen.main ?? NSScreen.screens.first)
    }

    init(store: ShelfStore) {
        self.store = store
        let initialCollapsedSize = Self.notchTriggerSize(for: NSScreen.main ?? NSScreen.screens.first)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: initialCollapsedSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false

        super.init(window: panel)

        let rootView = DragReceiverView(
            store: store,
            state: state,
            onRequestExpand: { [weak self] in self?.setExpanded(true) },
            onRequestCollapse: { [weak self] in self?.setExpanded(false) }
        )
        let hostingView = ClearHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.isOpaque = false
        let containerView = MaskedPanelContainerView()
        containerView.addHostedView(hostingView)
        panel.contentView = containerView
        positionWindow(size: initialCollapsedSize)
        panel.orderOut(nil)
        startMouseMonitoring()
    }

    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        if let localPointerMonitor {
            NSEvent.removeMonitor(localPointerMonitor)
        }
        if let globalPointerMonitor {
            NSEvent.removeMonitor(globalPointerMonitor)
        }
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.orderFrontRegardless()
    }

    func showShelf() {
        setExpanded(true)
        window?.orderFrontRegardless()
    }

    func toggleShelf() {
        setExpanded(!state.isExpanded)
    }

    func setExpanded(_ expanded: Bool) {
        guard state.isExpanded != expanded else { return }
        collapseTask?.cancel()

        if expanded {
            positionWindow(size: expandedSize)
            window?.orderFrontRegardless()
            state.isExpanded = true
        } else {
            state.isExpanded = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self, self.state.isExpanded == false else { return }
                self.positionWindow(size: self.collapsedSize)
                self.window?.orderOut(nil)
            }
        }
    }

    private func positionWindow(size: NSSize) {
        window?.setFrame(frameForWindow(size: size), display: true)
    }

    private func startMouseMonitoring() {
        let pointerEvents: NSEvent.EventTypeMask = [
            .mouseMoved,
            .leftMouseDragged,
            .rightMouseDragged,
            .otherMouseDragged
        ]

        localPointerMonitor = NSEvent.addLocalMonitorForEvents(matching: pointerEvents) { [weak self] event in
            self?.handlePointerEvent(event, at: NSEvent.mouseLocation)
            return event
        }

        globalPointerMonitor = NSEvent.addGlobalMonitorForEvents(matching: pointerEvents) { [weak self] event in
            self?.handlePointerEvent(event, at: NSEvent.mouseLocation)
        }
    }

    private func handlePointerEvent(_ event: NSEvent, at mouseLocation: NSPoint) {
        let inNotch = notchTriggerFrame().contains(mouseLocation)
        let isDraggingPointer = event.type == .leftMouseDragged
            || event.type == .rightMouseDragged
            || event.type == .otherMouseDragged

        if state.isExpanded {
            let inPanel = window?.frame.contains(mouseLocation) == true
            state.isHovering = inNotch || inPanel

            if state.isHovering {
                collapseTask?.cancel()
            } else if state.isDragActive == false && isDraggingPointer == false {
                scheduleCollapse()
            }
        } else if inNotch {
            state.isHovering = true
            setExpanded(true)
        } else {
            state.isHovering = false
        }
    }

    private func scheduleCollapse() {
        collapseTask?.cancel()

        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.state.isDragActive == false else { return }
            guard self.notchTriggerFrame().contains(NSEvent.mouseLocation) == false else { return }
            guard self.window?.frame.contains(NSEvent.mouseLocation) != true else { return }
            self.setExpanded(false)
        }

        collapseTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: task)
    }

    private func frameForWindow(size: NSSize) -> NSRect {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.frame ?? .zero
        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.maxY - size.height
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    private func notchTriggerFrame() -> NSRect {
        frameForWindow(size: collapsedSize)
    }

    private static func notchTriggerSize(for screen: NSScreen?) -> NSSize {
        let topSafeArea = max(screen?.safeAreaInsets.top ?? 0, 32)
        return NSSize(width: topSafeArea * 4, height: topSafeArea + 2)
    }
}

private final class MaskedPanelContainerView: NSView {
    private let maskLayer = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
        layer?.mask = maskLayer
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var isOpaque: Bool {
        false
    }

    func addHostedView(_ hostedView: NSView) {
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func layout() {
        super.layout()
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
        maskLayer.frame = bounds
        maskLayer.path = panelMaskPath(in: bounds).cgPath
    }

    private func panelMaskPath(in rect: CGRect) -> NSBezierPath {
        let radius = min(CGFloat(36), rect.width / 2, rect.height)
        let path = NSBezierPath()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.minY + radius))
        path.curve(
            to: CGPoint(x: rect.maxX - radius, y: rect.minY),
            controlPoint1: CGPoint(x: rect.maxX, y: rect.minY + radius * 0.45),
            controlPoint2: CGPoint(x: rect.maxX - radius * 0.45, y: rect.minY)
        )
        path.line(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.curve(
            to: CGPoint(x: rect.minX, y: rect.minY + radius),
            controlPoint1: CGPoint(x: rect.minX + radius * 0.45, y: rect.minY),
            controlPoint2: CGPoint(x: rect.minX, y: rect.minY + radius * 0.45)
        )
        path.line(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.close()

        return path
    }
}

private final class ClearHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool {
        false
    }

    override var wantsUpdateLayer: Bool {
        true
    }

    override func makeBackingLayer() -> CALayer {
        let layer = CALayer()
        layer.backgroundColor = NSColor.clear.cgColor
        layer.isOpaque = false
        return layer
    }

    override func updateLayer() {
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
        window?.backgroundColor = .clear
        window?.isOpaque = false
    }
}
