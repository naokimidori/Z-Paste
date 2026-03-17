import AppKit
import SwiftUI

/// 窗口管理服务
/// 负责 NSPanel 底部弹出窗口的创建、显示、隐藏和动画
class WindowService {
    // MARK: - Singleton

    static let shared = WindowService()

    // MARK: - Properties

    private var panel: NSPanel?
    private var isAnimating = false
    private var contentView: NSView?

    /// 窗口高度 - 卡片高度 250 + padding
    private let windowHeight: CGFloat = 280

    /// 窗口是否可见
    var isVisible: Bool {
        return panel?.isVisible == true
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 创建并配置 NSPanel
    /// - Parameter contentView: 窗口内容视图
    /// - Returns: 配置好的 NSPanel
    @discardableResult
    func createPanel(with contentView: NSView) -> NSPanel {
        // 如果已有 panel，先销毁
        if let existingPanel = panel {
            existingPanel.close()
        }

        self.contentView = contentView

        // 获取屏幕尺寸
        guard let screen = NSScreen.main else {
            fatalError("No main screen available")
        }
        let screenFrame = screen.visibleFrame

        // 创建 NSPanel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: screenFrame.width, height: windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Panel 属性配置
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true
        panel.hasShadow = true

        // 设置毛玻璃背景
        let visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: screenFrame.width, height: windowHeight))
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true

        // 添加内容视图到毛玻璃背景
        contentView.autoresizingMask = [.width, .height]
        visualEffectView.addSubview(contentView)

        panel.contentView = visualEffectView

        // 设置初始位置（屏幕底部，隐藏状态）
        let offScreenY = screenFrame.origin.y - windowHeight - 10
        panel.setFrameOrigin(NSPoint(x: screenFrame.origin.x, y: offScreenY))

        self.panel = panel

        return panel
    }

    /// 显示窗口（带动画）
    func showWindow() {
        guard let panel = panel, !isAnimating else { return }

        isAnimating = true

        // 激活应用并显示窗口
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        // 计算目标位置
        let positions = calculatePositions()

        // 执行滑入动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrameOrigin(
                NSPoint(x: calculateXPosition(), y: positions.onScreen)
            )
        } completionHandler: { [weak self] in
            self?.isAnimating = false
        }
    }

    /// 隐藏窗口（带动画）
    func hideWindow() {
        guard let panel = panel, panel.isVisible, !isAnimating else { return }

        isAnimating = true

        // 计算目标位置
        let positions = calculatePositions()

        // 执行滑出动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrameOrigin(
                NSPoint(x: calculateXPosition(), y: positions.offScreen)
            )
        } completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.isAnimating = false
        }
    }

    /// 切换窗口显示/隐藏
    func toggleWindow() {
        if panel?.isVisible == true {
            hideWindow()
        } else {
            showWindow()
        }
    }

    // MARK: - Private Methods

    /// 计算窗口在屏幕上和屏幕外的 Y 坐标
    /// - Returns: (屏幕上Y, 屏幕外Y)
    private func calculatePositions() -> (onScreen: CGFloat, offScreen: CGFloat) {
        guard let screen = getCurrentScreen() else { return (0, 0) }
        let screenFrame = screen.visibleFrame

        // 屏幕上位置：屏幕底部（visibleFrame.origin.y 就是屏幕可用区域底部）
        let onScreenY = screenFrame.origin.y
        // 屏幕外位置：屏幕下方
        let offScreenY = screenFrame.origin.y - windowHeight - 10

        return (onScreenY, offScreenY)
    }

    /// 计算窗口 X 坐标（居中）
    /// - Returns: X 坐标
    private func calculateXPosition() -> CGFloat {
        guard let screen = getCurrentScreen() else { return 0 }
        let screenFrame = screen.visibleFrame

        // 窗口宽度等于屏幕宽度，X 坐标从屏幕左边开始
        return screenFrame.origin.x
    }

    /// 获取当前显示器（支持多显示器）
    /// 优先获取鼠标所在的显示器，如果没有则返回主显示器
    /// - Returns: 当前显示器
    private func getCurrentScreen() -> NSScreen? {
        // 获取鼠标位置
        let mouseLocation = NSEvent.mouseLocation

        // 找到包含鼠标位置的显示器
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
            return screen
        }

        // 默认返回主显示器
        return NSScreen.main
    }
}
