import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeyService = HotkeyService()
    var mainWindow: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 应用启动配置
        configureApp()

        // 创建主窗口
        createMainWindow()

        // 注册全局快捷键
        hotkeyService.register()
        hotkeyService.onToggleWindow = { [weak self] in
            self?.toggleWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 应用终止前清理资源
        hotkeyService.unregister()
        cleanup()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // 窗口关闭时不退出应用
    }

    // MARK: - Private Methods

    private func configureApp() {
        // 配置窗口外观
        NSApp.appearance = NSAppearance(named: .darkAqua)

        // 隐藏 Dock 图标
        NSApp.setActivationPolicy(.accessory)

        print("Z-Paste 应用已启动")
    }

    private func createMainWindow() {
        // 创建 ContentView
        let contentView = ContentView()

        // 创建窗口
        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        mainWindow.contentViewController = NSHostingController(rootView: contentView)
        mainWindow.center()
        mainWindow.level = .floating // 保持窗口在最前
        mainWindow.isMovable = true
        mainWindow.isMovableByWindowBackground = true

        print("主窗口已创建")
    }

    /// 切换窗口显示/隐藏
    private func toggleWindow() {
        print("HotkeyService: 触发窗口切换回调")

        if mainWindow.isVisible {
            // 窗口已激活，隐藏它
            mainWindow.orderOut(nil)
            print("隐藏窗口")
        } else {
            // 显示窗口并激活
            mainWindow.makeKeyAndOrderFront(nil)
            mainWindow.center()
            NSApp.activate(ignoringOtherApps: true)
            print("显示窗口")
        }
    }

    private func cleanup() {
        // 清理资源
        print("Z-Paste 应用正在退出")
    }
}
