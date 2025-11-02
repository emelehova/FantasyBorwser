import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var browserVC: BrowserViewController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let args = CommandLine.arguments
        browserVC = BrowserViewController(arguments: args)

        let styleMask: NSWindow.StyleMask = [.titled, .closable, .resizable, .miniaturizable]
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x:0,y:0,width:1440,height:900)
        let w = NSRect(x: screenRect.origin.x + (screenRect.width - 1200)/2,
                       y: screenRect.origin.y + (screenRect.height - 800)/2,
                       width: 1200,
                       height: 800)

        window = NSWindow(contentRect: w, styleMask: styleMask, backing: .buffered, defer: false)
        window.title = "FH Browser"
        window.contentViewController = browserVC
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu

        let appMenu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit FH Browser", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu

        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        let toggleMobile = NSMenuItem(title: "Toggle Mobile UA", action: #selector(toggleMobile(_:)), keyEquivalent: "m")
        toggleMobile.keyEquivalentModifierMask = [.command]
        toggleMobile.target = self
        viewMenu.addItem(toggleMobile)
        viewMenuItem.submenu = viewMenu
    }

    @objc func toggleMobile(_ sender: Any?) {
        browserVC.toggleMobileMode()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}
