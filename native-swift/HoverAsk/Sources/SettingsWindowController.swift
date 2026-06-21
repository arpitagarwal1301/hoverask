import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow

    var isVisible: Bool {
        window.isVisible
    }

    init(rootView: some View) {
        let contentSize = NSSize(width: 1220, height: 760)
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init()
        window.title = "HoverAsk Settings"
        window.titleVisibility = .visible
        window.toolbarStyle = .unifiedCompact
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 980, height: 640)
        window.contentView = NSHostingView(rootView: AnyView(rootView))
        window.delegate = self
        window.center()
    }

    func show() {
        if !window.isVisible {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        window.orderOut(nil)
    }
}

