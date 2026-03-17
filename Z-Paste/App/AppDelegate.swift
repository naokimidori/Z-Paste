import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 应用启动配置
        configureApp()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 应用终止前清理资源
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
}

// 简单的 ContentView 占位符
struct ContentView: View {
    var body: some View {
        Text("Z-Paste - 剪贴板管理器")
            .frame(width: 400, height: 200)
    }
}
