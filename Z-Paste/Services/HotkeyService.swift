import Foundation
import KeyboardShortcuts

/// 全局快捷键服务
/// 使用 KeyboardShortcuts 库注册和监听全局快捷键
class HotkeyService {
    /// 窗口切换回调
    var onToggleWindow: (() -> Void)?

    /// 初始化并注册快捷键回调
    init() {
        // 注册快捷键按下事件
        KeyboardShortcuts.onKeyDown(for: .toggleWindow) { [weak self] in
            self?.onToggleWindow?()
        }
    }

    /// 注册快捷键
    /// 默认快捷键：Option + `
    func register() {
        // KeyboardShortcuts 会在首次访问 .toggleWindow 时自动注册
        // 确保快捷键名称已定义
        _ = KeyboardShortcuts.Name.toggleWindow
    }

    /// 注销快捷键
    func unregister() {
        // 重置快捷键为 nil
        KeyboardShortcuts.reset(.toggleWindow)
    }
}

// MARK: - KeyboardShortcuts.Name Extension

extension KeyboardShortcuts.Name {
    /// 切换窗口显示的快捷键
    static let toggleWindow = Self("toggleWindow", default: .init(.backquote, modifiers: .option))
}
