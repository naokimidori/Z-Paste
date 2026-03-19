import Foundation
import KeyboardShortcuts

/// 全局快捷键服务
/// 使用 KeyboardShortcuts 库注册和监听全局快捷键
class HotkeyService {
    /// 窗口切换回调
    var onToggleWindow: (() -> Void)?

    /// 初始化并注册快捷键回调
    init() {
        KeyboardShortcuts.onKeyDown(for: .toggleWindow) { [weak self] in
            print("Hotkey triggered: toggleWindow")
            self?.onToggleWindow?()
        }
    }

    /// 注册快捷键
    /// 默认快捷键：Option + `
    func register() {
        if KeyboardShortcuts.getShortcut(for: .toggleWindow) == nil {
            KeyboardShortcuts.setShortcut(.init(.backtick, modifiers: [.option]), for: .toggleWindow)
        }

        if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleWindow) {
            print("Hotkey registered: \(shortcut)")
        } else {
            print("Hotkey registration failed: no shortcut configured")
        }
    }

    /// 注销快捷键
    func unregister() {
        KeyboardShortcuts.reset(.toggleWindow)
    }
}

// MARK: - KeyboardShortcuts.Name Extension

extension KeyboardShortcuts.Name {
    /// 切换窗口显示的快捷键
    static let toggleWindow = Self("toggleWindow")
}
