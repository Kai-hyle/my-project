import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let shelfStore = ShelfStore()
    private var notchWindowController: NotchWindowController?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let notchWindowController = NotchWindowController(store: shelfStore)
        self.notchWindowController = notchWindowController
        notchWindowController.showWindow(nil)

        statusBarController = StatusBarController(
            store: shelfStore,
            notchWindowController: notchWindowController
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
