import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeyService = HotkeyService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 应用启动配置
        configureApp()

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
        return true
    }

    // MARK: - Private Methods

    private func configureApp() {
        // 配置窗口外观
        NSApp.appearance = NSAppearance(named: .darkAqua)

        // 隐藏 Dock 图标 (可选，设置为 false 保持在 Dock 显示)
        // NSApp.setActivationPolicy(.accessory)

        print("Z-Paste 应用已启动")
    }

    private func cleanup() {
        // 清理资源
        print("Z-Paste 应用正在退出")
    }

    /// 切换窗口显示/隐藏
    private func toggleWindow() {
        print("HotkeyService: 触发窗口切换回调")
        // TODO: 实现窗口显示/隐藏逻辑
    }
}
