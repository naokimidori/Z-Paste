import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeyService = HotkeyService()
    private var clipboardService: ClipboardService!
    private var databaseService: DatabaseService!
    private let windowService = WindowService.shared

    private var panel: NSPanel?
    private var hostingController: NSHostingController<MainWindowView>?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var isContextMenuPresented = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let dbPath = databasePath()
            databaseService = try DatabaseService(databasePath: dbPath)
        } catch {
            print("Failed to initialize database: \(error)")
            return
        }

        clipboardService = ClipboardService(database: databaseService)
        configureApp()
        createMainWindow()

        hotkeyService.register()
        hotkeyService.onToggleWindow = { [weak self] in
            DispatchQueue.main.async {
                self?.toggleWindow()
            }
        }

        clipboardService.onNewItem = { [weak self] _ in
            if self?.windowService.isVisible == true {
            }
        }
        clipboardService.startMonitoring()

        print("Z-Paste 应用已启动")
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService.unregister()
        clipboardService.stopMonitoring()
        tearDownClickOutsideHandling()
        print("Z-Paste 应用正在退出")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func configureApp() {
        NSApp.setActivationPolicy(.accessory)
    }

    private func createMainWindow() {
        let mainWindowView = MainWindowView(
            database: databaseService,
            primaryActionPerformer: clipboardService,
            onPrimaryActionCompleted: { [weak self] result in
                self?.handlePrimaryActionCompleted(result)
            },
            onHide: { [weak self] in
                self?.hideWindow()
            },
            onContextMenuStateChanged: { [weak self] isPresented in
                self?.isContextMenuPresented = isPresented
            }
        )

        let hostingController = NSHostingController(rootView: mainWindowView)
        self.hostingController = hostingController
        hostingController.loadView()
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 1200, height: 320)

        panel = windowService.createPanel(with: hostingController)
        setupClickOutsideHandling()
    }

    private func handlePrimaryActionCompleted(_ result: PrimaryActionResult) {
        hideWindow { [weak self] in
            guard let self else { return }

            switch result {
            case .pasted:
                let pasteResult = self.clipboardService.attemptPasteAfterWindowHide()
                if case .failed(let message) = pasteResult {
                    print("Primary action failed: \(message)")
                }
            case .copiedOnly:
                break
            case .failed(let message):
                print("Primary action failed: \(message)")
            }
        }
    }

    func shouldHideForOutsideClick(eventIsInsidePanel: Bool) -> Bool {
        guard !isContextMenuPresented else { return false }
        return !eventIsInsidePanel
    }

    func setContextMenuPresentedForTesting(_ isPresented: Bool) {
        isContextMenuPresented = isPresented
    }

    private func toggleWindow() {
        windowService.toggleWindow()
    }

    private func hideWindow(completion: (() -> Void)? = nil) {
        windowService.hideWindow(completion: completion)
    }

    private func hideWindow() {
        hideWindow(completion: nil)
    }

    private func setupClickOutsideHandling() {
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.windowService.isVisible else { return }
            guard self.shouldHideForOutsideClick(eventIsInsidePanel: false) else { return }
            self.hideWindow()
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.windowService.isVisible else { return event }
            guard let panel = self.panel else { return event }

            let locationInWindow = event.locationInWindow
            let locationOnScreen = panel.convertPoint(toScreen: locationInWindow)
            let eventIsInsidePanel = panel.frame.contains(locationOnScreen)
            if self.shouldHideForOutsideClick(eventIsInsidePanel: eventIsInsidePanel) {
                self.hideWindow()
            }

            return event
        }
    }

    private func tearDownClickOutsideHandling() {
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }

        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
    }

    @objc func applicationDidResignActive(_ notification: Notification) {
    }

    private func databasePath() -> String {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Z-Paste")
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("clipboard.sqlite").path
    }
}
