import AppKit
import SwiftUI

private final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// 窗口管理服务
/// 负责 NSPanel 底部弹出窗口的创建、显示、隐藏和动画
class WindowService {
    // MARK: - Singleton

    static let shared = WindowService()

    // MARK: - Properties

    private var panel: NSPanel?
    private var isAnimating = false
    private var contentViewController: NSViewController?

    /// 窗口高度 - 卡片高度 250 + padding
    private let windowHeight: CGFloat = 280
    private let horizontalInset: CGFloat = 40
    private let focusReturnDelay: TimeInterval = 0.08

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
    func createPanel(with contentViewController: NSViewController) -> NSPanel {
        if let existingPanel = panel {
            existingPanel.close()
        }

        self.contentViewController = contentViewController

        guard let screen = NSScreen.main else {
            fatalError("No main screen available")
        }
        let screenFrame = screen.visibleFrame

        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth(for: screenFrame), height: windowHeight),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .windowBackgroundColor
        panel.contentViewController = contentViewController

        let offScreenY = screenFrame.origin.y - windowHeight - 10
        panel.setFrameOrigin(NSPoint(x: calculateXPosition(), y: offScreenY))

        self.panel = panel

        return panel
    }

    /// 显示窗口（带动画）
    func showWindow() {
        guard let panel = panel, !isAnimating else { return }

        isAnimating = true

        let positions = calculatePositions()
        let targetOrigin = NSPoint(x: calculateXPosition(), y: positions.onScreen)

        panel.setFrameOrigin(targetOrigin)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        isAnimating = false
    }

    func hideWindow(completion: (() -> Void)? = nil) {
        guard let panel = panel, panel.isVisible, !isAnimating else {
            completion?()
            return
        }

        isAnimating = true
        panel.orderOut(nil)
        isAnimating = false

        guard let completion else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + focusReturnDelay) {
            completion()
        }
    }

    func hideWindow() {
        hideWindow(completion: nil)
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

        let onScreenY = screenFrame.origin.y
        let offScreenY = screenFrame.origin.y - windowHeight - 10

        return (onScreenY, offScreenY)
    }

    /// 计算窗口 X 坐标（居中）
    /// - Returns: X 坐标
    private func calculateXPosition() -> CGFloat {
        guard let screen = getCurrentScreen() else { return 0 }
        let screenFrame = screen.visibleFrame

        return screenFrame.origin.x + horizontalInset
    }

    private func panelWidth(for screenFrame: NSRect) -> CGFloat {
        max(800, screenFrame.width - (horizontalInset * 2))
    }

    /// 获取当前显示器（支持多显示器）
    /// 优先获取鼠标所在的显示器，如果没有则返回主显示器
    /// - Returns: 当前显示器
    private func getCurrentScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation

        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
            return screen
        }

        return NSScreen.main
    }
}
