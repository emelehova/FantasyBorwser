import Cocoa
import WebKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var controller: BrowserViewController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let width: CGFloat = 1200
        let height: CGFloat = 800
        let rect = NSRect(
            x: screen.midX - width/2,
            y: screen.midY - height/2,
            width: width,
            height: height
        )

        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "FH Browser"
        window.isReleasedWhenClosed = false

        controller = BrowserViewController()
        window.contentViewController = controller
        window.makeKeyAndOrderFront(nil)

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
