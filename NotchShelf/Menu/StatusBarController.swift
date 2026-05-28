import AppKit

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let store: ShelfStore
    private weak var notchWindowController: NotchWindowController?
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")

    init(store: ShelfStore, notchWindowController: NotchWindowController) {
        self.store = store
        self.notchWindowController = notchWindowController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tray.full", accessibilityDescription: "Better Norch")
            button.imagePosition = .imageOnly
        }

        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "Show Shelf", action: #selector(showShelf), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Clear Shelf", action: #selector(clearShelf), keyEquivalent: ""))
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        menu.items.forEach { $0.target = self }
        updateLaunchAtLoginState()
        statusItem.menu = menu
    }

    @objc private func showShelf() {
        notchWindowController?.showShelf()
    }

    @objc private func clearShelf() {
        store.clear()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LoginItemService.setEnabled(!LoginItemService.isEnabled)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not update Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
        updateLaunchAtLoginState()
    }

    private func updateLaunchAtLoginState() {
        launchAtLoginItem.state = LoginItemService.isEnabled ? .on : .off
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateLaunchAtLoginState()
    }
}
