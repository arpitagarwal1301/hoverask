import Carbon
import Foundation

final class HotKeyController {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var shortcut: HotKeyShortcut
    private var registeredShortcut: HotKeyShortcut?
    private let onPressed: () -> Void

    init(shortcut: HotKeyShortcut, onPressed: @escaping () -> Void) {
        self.shortcut = shortcut
        self.onPressed = onPressed
    }

    @discardableResult
    func register() -> Bool {
        unregister()
        return install(shortcut)
    }

    var activeShortcut: HotKeyShortcut {
        registeredShortcut ?? shortcut
    }

    private func install(_ shortcut: HotKeyShortcut) -> Bool {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        let handlerStatus = InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
            guard let userData else { return noErr }
            let controller = Unmanaged<HotKeyController>.fromOpaque(userData).takeUnretainedValue()
            controller.onPressed()
            return noErr
        }, 1, &eventType, selfPointer, &eventHandler)
        guard handlerStatus == noErr else {
            eventHandler = nil
            return false
        }

        let hotKeyID = EventHotKeyID(signature: fourCharCode("SORB"), id: 1)
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        guard status == noErr else {
            if let eventHandler {
                RemoveEventHandler(eventHandler)
            }
            eventHandler = nil
            hotKeyRef = nil
            return false
        }
        self.shortcut = shortcut
        registeredShortcut = shortcut
        return true
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
        hotKeyRef = nil
        eventHandler = nil
        registeredShortcut = nil
    }

    @discardableResult
    func update(shortcut: HotKeyShortcut) -> Bool {
        let previous = activeShortcut
        unregister()
        if install(shortcut) {
            return true
        }
        _ = install(previous)
        return false
    }

    private func fourCharCode(_ string: String) -> OSType {
        var result: OSType = 0
        for scalar in string.unicodeScalars.prefix(4) {
            result = (result << 8) + OSType(scalar.value)
        }
        return result
    }
}
