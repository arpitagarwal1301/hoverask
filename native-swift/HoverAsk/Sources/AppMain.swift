import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var settings: SettingsStore!
    private var history: HistoryStore!
    private var viewModel: OrbViewModel!
    private var windowController: OrbWindowController!
    private var settingsWindowController: SettingsWindowController!
    private var hotKeyController: HotKeyController?
    private var statusItem: NSStatusItem?
    private var showHideMenuItem: NSMenuItem?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        settings = SettingsStore()
        history = HistoryStore()
        viewModel = OrbViewModel(settings: settings, history: history)
        windowController = OrbWindowController()
        viewModel.attach(windowController: windowController)

        let rootView = OrbRootView(viewModel: viewModel)
            .environmentObject(settings)
            .environmentObject(history)
        let settingsView = SettingsRootView(viewModel: viewModel)
            .environmentObject(settings)
            .environmentObject(history)

        windowController.setRootView(rootView)
        settingsWindowController = SettingsWindowController(rootView: settingsView)
        viewModel.attach(settingsWindowController: settingsWindowController)
        windowController.show()
        configureStatusMenu()

        hotKeyController = HotKeyController(shortcut: settings.hotKeyShortcut) { [weak self] in
            DispatchQueue.main.async {
                self?.viewModel.showOrb()
                self?.viewModel.startListening()
            }
        }
        viewModel.updateHotKeyRegistration(success: hotKeyController?.register() == true)
        settings.$hotKeyShortcut
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] shortcut in
                guard let self else { return }
                let success = self.hotKeyController?.update(shortcut: shortcut) == true
                if !success, let activeShortcut = self.hotKeyController?.activeShortcut, self.settings.hotKeyShortcut != activeShortcut {
                    self.settings.hotKeyShortcut = activeShortcut
                }
                self.viewModel.updateHotKeyRegistration(success: success)
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController?.unregister()
        viewModel?.collapse()
    }

    func menuWillOpen(_ menu: NSMenu) {
        showHideMenuItem?.title = windowController.isVisible ? "Hide HoverAsk" : "Show HoverAsk"
    }

    private func configureStatusMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "HoverAsk")
        item.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.delegate = self

        let showHide = NSMenuItem(title: "Hide HoverAsk", action: #selector(toggleOrbFromMenu), keyEquivalent: "")
        showHide.target = self
        menu.addItem(showHide)
        showHideMenuItem = showHide

        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettingsFromMenu), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let supportItem = NSMenuItem(title: "Support HoverAsk", action: #selector(openSupportFromMenu), keyEquivalent: "")
        supportItem.target = self
        supportItem.isEnabled = SupportConfig.supportURL != nil
        menu.addItem(supportItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitFromMenu), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    @objc private func toggleOrbFromMenu() {
        viewModel.toggleOrbVisibility()
    }

    @objc private func openSettingsFromMenu() {
        viewModel.openSettings()
    }

    @objc private func openSupportFromMenu() {
        guard let url = SupportConfig.supportURL else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func quitFromMenu() {
        viewModel.quitApp()
    }
}

@main
enum HoverAskMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
        _ = delegate
    }
}
