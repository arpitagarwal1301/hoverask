import AppKit
import SwiftUI

@MainActor
final class OrbWindowController: NSObject {
    private let panel: FloatingOrbPanel

    var isVisible: Bool {
        panel.isVisible
    }

    override init() {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let initialFrame = NSRect(
            x: visibleFrame.midX - WindowSize.idle.width / 2,
            y: visibleFrame.midY - WindowSize.idle.height / 2,
            width: WindowSize.idle.width,
            height: WindowSize.idle.height
        )

        panel = FloatingOrbPanel(
            contentRect: initialFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.title = "HoverAsk"
    }

    func setRootView(_ rootView: some View) {
        let hostingView = NSHostingView(rootView: AnyView(rootView))
        hostingView.frame = NSRect(origin: .zero, size: panel.frame.size)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.isOpaque = false
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView
    }

    func show() {
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func toggleVisibility() {
        isVisible ? hide() : show()
    }

    func apply(phase: OrbPhase) {
        let size: CGSize
        let anchorMode: AnchorMode
        switch phase {
        case .idle:
            size = WindowSize.idle
            anchorMode = .avatarCenter
        case .listening:
            size = WindowSize.companion
            anchorMode = .avatarCenter
        case .thinking, .answer, .error:
            size = WindowSize.companion
            anchorMode = .avatarCenter
        case .settings:
            size = WindowSize.settings
            anchorMode = .windowCenter
        }
        resize(to: size, anchorMode: anchorMode)
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }

    func performDrag(with event: NSEvent) {
        panel.performDrag(with: event)
    }

    private func resize(to size: CGSize, anchorMode: AnchorMode) {
        var frame = panel.frame
        let anchor = CGPoint(x: frame.midX, y: frame.midY)
        frame.size = size
        switch anchorMode {
        case .avatarCenter, .windowCenter:
            frame.origin.x = anchor.x - size.width / 2
            frame.origin.y = anchor.y - size.height / 2
        }
        frame = clampToVisibleScreen(frame)
        panel.setFrame(frame, display: true, animate: true)
    }

    func avatarCenter() -> CGPoint {
        CGPoint(x: panel.frame.midX, y: panel.frame.midY)
    }

    func visibleFrame(containing point: CGPoint? = nil) -> NSRect {
        screen(containing: point)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? panel.frame
    }

    func setAvatarCenter(_ center: CGPoint) {
        var frame = panel.frame
        frame.origin.x = center.x - frame.width / 2
        frame.origin.y = center.y - frame.height / 2
        frame = clampToVisibleScreen(frame, preferredPoint: center)
        panel.setFrame(frame, display: true, animate: false)
        if panel.isVisible {
            panel.level = .screenSaver
            panel.orderFrontRegardless()
        }
    }

    private func clampToVisibleScreen(_ frame: NSRect, preferredPoint: CGPoint? = nil) -> NSRect {
        let screen = screen(containing: preferredPoint) ?? NSScreen.screens.first { $0.visibleFrame.intersects(frame) } ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else {
            return frame
        }

        var clamped = frame
        if clamped.minX < visibleFrame.minX {
            clamped.origin.x = visibleFrame.minX
        }
        if clamped.maxX > visibleFrame.maxX {
            clamped.origin.x = visibleFrame.maxX - clamped.width
        }
        if clamped.minY < visibleFrame.minY {
            clamped.origin.y = visibleFrame.minY
        }
        if clamped.maxY > visibleFrame.maxY {
            clamped.origin.y = visibleFrame.maxY - clamped.height
        }
        return clamped
    }

    private func screen(containing point: CGPoint?) -> NSScreen? {
        guard let point else {
            return panel.screen ?? NSScreen.main
        }
        return NSScreen.screens.first { $0.visibleFrame.contains(point) } ?? panel.screen ?? NSScreen.main
    }

    private enum AnchorMode {
        case avatarCenter
        case windowCenter
    }

    private enum WindowSize {
        static let idle = CGSize(width: 136, height: 136)
        static let companion = CGSize(width: 720, height: 420)
        static let settings = CGSize(width: 620, height: 760)
    }
}

final class FloatingOrbPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

struct ClickDragOverlay: NSViewRepresentable {
    let onClick: () -> Void
    let onHoldStart: () -> Void
    let onHoldEnd: () -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void

    func makeNSView(context: Context) -> ClickDragNSView {
        let view = ClickDragNSView()
        view.onClick = onClick
        view.onHoldStart = onHoldStart
        view.onHoldEnd = onHoldEnd
        view.onDragStart = onDragStart
        view.onDragEnd = onDragEnd
        return view
    }

    func updateNSView(_ nsView: ClickDragNSView, context: Context) {
        nsView.onClick = onClick
        nsView.onHoldStart = onHoldStart
        nsView.onHoldEnd = onHoldEnd
        nsView.onDragStart = onDragStart
        nsView.onDragEnd = onDragEnd
    }
}

final class ClickDragNSView: NSView {
    var onClick: (() -> Void)?
    var onHoldStart: (() -> Void)?
    var onHoldEnd: (() -> Void)?
    var onDragStart: (() -> Void)?
    var onDragEnd: (() -> Void)?

    private var downEvent: NSEvent?
    private var didDrag = false
    private var holdTimer: Timer?
    private var didHold = false
    private var didNotifyDragStart = false

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        downEvent = event
        didDrag = false
        didHold = false
        didNotifyDragStart = false
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: false) { [weak self] _ in
            self?.didHold = true
            self?.onHoldStart?()
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let downEvent else { return }
        if !didNotifyDragStart {
            didNotifyDragStart = true
            onDragStart?()
        }
        didDrag = true
        holdTimer?.invalidate()
        window?.performDrag(with: downEvent)
    }

    override func mouseUp(with event: NSEvent) {
        holdTimer?.invalidate()
        if didHold {
            onHoldEnd?()
        } else if !didDrag {
            onClick?()
        } else {
            onDragEnd?()
        }
        downEvent = nil
        didDrag = false
        didHold = false
        didNotifyDragStart = false
    }
}

struct PanelDragSurface: NSViewRepresentable {
    func makeNSView(context: Context) -> PanelDragNSView {
        PanelDragNSView()
    }

    func updateNSView(_ nsView: PanelDragNSView, context: Context) {}
}

final class PanelDragNSView: NSView {
    private var downEvent: NSEvent?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        downEvent = event
    }

    override func mouseDragged(with event: NSEvent) {
        window?.performDrag(with: downEvent ?? event)
    }

    override func mouseUp(with event: NSEvent) {
        downEvent = nil
    }
}
