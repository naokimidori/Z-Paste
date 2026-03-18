import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Services
    private let hotkeyService = HotkeyService()
    private var clipboardService: ClipboardService!
    private var databaseService: DatabaseService!
    private let windowService = WindowService.shared

    // MARK: - State
    private var panel: NSPanel?

    // MARK: - Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. 初始化数据库
        do {
            let dbPath = databasePath()
            databaseService = try DatabaseService(databasePath: dbPath)
        } catch {
            print("Failed to initialize database: \(error)")
            return
        }

        // 2. 初始化剪贴板服务
        clipboardService = ClipboardService(database: databaseService)

        // 3. 配置应用
        configureApp()

        // 4. 创建主窗口
        createMainWindow()

        // 5. 注册快捷键
        hotkeyService.register()
        hotkeyService.onToggleWindow = { [weak self] in
            self?.toggleWindow()
        }

        // 6. 启动剪贴板监听
        clipboardService.onNewItem = { [weak self] _ in
            // 新项目添加时，如果窗口可见则刷新
            if self?.windowService.isVisible == true {
                // ViewModel 会在 onAppear 时自动加载
            }
        }
        clipboardService.startMonitoring()

        print("Z-Paste 应用已启动")
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService.unregister()
        clipboardService.stopMonitoring()
        print("Z-Paste 应用正在退出")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // 窗口关闭时不退出应用
    }

    // MARK: - Private Methods

    private func configureApp() {
        // 隐藏 Dock 图标
        NSApp.setActivationPolicy(.accessory)
    }

    private func createMainWindow() {
        // 创建 MainWindowView
        let mainWindowView = MainWindowView(database: databaseService) { [weak self] in
            self?.hideWindow()
        }

        // 创建 NSHostingController
        let hostingController = NSHostingController(rootView: mainWindowView)

        // 创建 Panel
        panel = windowService.createPanel(with: hostingController.view)

        // 设置点击外部关闭
        setupClickOutsideHandling()
    }

    private func toggleWindow() {
        windowService.toggleWindow()
    }

    private func hideWindow() {
        windowService.hideWindow()
    }

    private func showWindow() {
        windowService.showWindow()
    }

    // MARK: - Click Outside Handling
    private func setupClickOutsideHandling() {
        // 监听应用失去激活事件
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }

    @objc private func applicationDidResignActive(_ notification: Notification) {
        // 窗口失去焦点时关闭
        if windowService.isVisible {
            hideWindow()
        }
    }

    // MARK: - Helpers
    private func databasePath() -> String {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Z-Paste")

        // 确保目录存在
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)

        return appDir.appendingPathComponent("clipboard.sqlite").path
    }
}
