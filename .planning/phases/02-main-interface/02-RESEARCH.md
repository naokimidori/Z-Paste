# Phase 2: 主界面实现 - 研究报告

**研究时间:** 2026-03-17
**领域:** SwiftUI 窗口系统、动画、横向滚动布局
**置信度:** HIGH

## 摘要

Phase 2 需要实现底部弹出窗口和卡片列表界面。核心技术点包括：
1. **NSPanel 自定义窗口** - 实现 always-on-top 浮动窗口，位于屏幕底部
2. **滑入/滑出动画** - 使用 SwiftUI 原生动画或 NSWindow frame 动画
3. **横向滚动卡片列表** - ScrollView + LazyHStack 性能优化
4. **视觉效果** - 毛玻璃模糊背景
5. **键盘导航** - SwiftUI FocusState 管理焦点

**主要建议:** 使用 NSPanel 替代普通 NSWindow，利用 SwiftUI 原生动画和 LazyHStack 构建高性能卡片列表。

<user_constraints>
## 用户约束 (来自 CONTEXT.md)

### 锁定决策
- **位置：** 屏幕底部中央
- **尺寸：** 宽度 100% 全屏宽，高度固定（约 120-150px）
- **多显示器：** 跟随活动显示器
- **层级：** 始终置顶（NSPanel + canBecomeKey）
- **卡片尺寸：** 250px × 250px 正方形
- **样式：** 圆角卡片
- **动画时长：** 0.2 秒
- **关闭触发：** 快捷键切换、点击外部关闭、ESC 关闭、选择后自动关闭
- **键盘导航：** 左右箭头键选择卡片，Enter 确认
- **默认选中：** 最新卡片（最左侧）
- **排序规则：** 按时间倒序，最新复制的在最左边

### Claude 自由裁量
- 窗口具体高度值（建议 120-150px）
- 卡片圆角半径
- 阴影具体参数
- 动画缓动曲线
- 滚动条样式

### 延迟想法 (不在范围内)
- 点击卡片粘贴功能 — Phase 3
- 右键菜单交互 — Phase 3
- 收藏/删除功能 — Phase 3
- 搜索功能 — Phase 4
- 设置界面 — Phase 5

</user_constraints>

<phase_requirements>
## 阶段需求

| ID | 描述 | 研究支持 |
|----|------|----------|
| 2.1 | MainWindow - 底部弹出窗口 | NSPanel 配置、屏幕位置计算 |
| 2.2 | 滑入/滑出动画效果 | SwiftUI 动画、NSWindow frame 动画 |
| 2.3 | ClipboardCard - 卡片组件 | SwiftUI 视图组合、条件渲染 |
| 2.4 | 横向滚动列表 | ScrollView + LazyHStack、性能优化 |
| 2.5 | 选中状态和高亮效果 | FocusState、状态管理 |
| 2.6 | 来源应用图标获取 | NSImage 转换、异步加载 |

</phase_requirements>

## 标准技术栈

### 核心
| 库/框架 | 版本 | 用途 | 为何是标准 |
|---------|------|------|-----------|
| SwiftUI | macOS 13+ | UI 框架 | Apple 原生，声明式语法 |
| AppKit (NSPanel) | macOS 13+ | 窗口管理 | 提供浮动面板能力 |
| GRDB.swift | 已集成 | 数据查询 | Phase 1 已选型 |

### 辅助
| 组件 | 用途 | 使用场景 |
|------|------|---------|
| NSVisualEffectView | 毛玻璃效果 | 窗口背景模糊 |
| ScrollViewReader | 程序化滚动 | 默认选中最新卡片 |

### 已考虑的替代方案
| 标准 | 可用替代 | 权衡 |
|------|----------|------|
| NSPanel | NSWindow | NSPanel 提供 floatingPanel、becomesKeyOnlyIfNeeded 等专用属性 |
| SwiftUI 动画 | Core Animation | SwiftUI 更简洁，0.2s 短动画性能差异可忽略 |
| LazyHStack | HStack | 懒加载避免大量卡片内存问题 |

## 架构模式

### 推荐项目结构
```
Z-Paste/
├── Z-Paste/
│   ├── Views/
│   │   ├── MainWindow/
│   │   │   ├── MainWindowView.swift      // 主窗口容器
│   │   │   ├── ClipboardCardView.swift   // 单个卡片视图
│   │   │   └── CardListView.swift        // 横向滚动列表
│   │   └── ContentView.swift             // 入口视图
│   ├── ViewModels/
│   │   └── ClipboardViewModel.swift      // 数据绑定
│   └── Services/
│       └── WindowService.swift           // 窗口动画服务
```

### 模式 1: NSPanel 底部弹出窗口

**用途:** 创建始终置顶的浮动窗口
**何时使用:** 需要类似 Spotlight 的全局唤起窗口

```swift
// AppDelegate.swift 中创建 NSPanel
let panel = NSPanel(
    contentRect: NSRect(x: 0, y: 0, width: screenWidth, height: 140),
    styleMask: [.borderless, .nonactivatingPanel],
    backing: .buffered,
    defer: false
)

// 关键配置
panel.level = .floating          // 置顶层级
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
panel.isFloatingPanel = true     // 浮动面板
panel.becomesKeyOnlyIfNeeded = true
panel.hidesOnDeactivate = false  // 切换应用不隐藏

// 位置计算 - 屏幕底部中央
if let screen = NSScreen.main {
    let screenFrame = screen.visibleFrame
    let panelY = screenFrame.origin.y  // 屏幕底部
    panel.setFrameOrigin(NSPoint(x: 0, y: panelY))
}

// 毛玻璃背景
panel.contentView?.wantsLayer = true
panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
```

**来源:** Apple NSPanel 文档

### 模式 2: 滑入/滑出动画

**用途:** 窗口从屏幕底部滑入/滑出
**何时使用:** 唤起和关闭窗口时

```swift
// 方案 A: NSWindow frame 动画 (推荐，更流畅)
func animateWindow(show: Bool, completion: (() -> Void)? = nil) {
    guard let screen = NSScreen.main else { return }
    let screenFrame = screen.visibleFrame
    let windowWidth = screenFrame.width
    let windowHeight: CGFloat = 140
    let offScreenY = screenFrame.origin.y - windowHeight
    let onScreenY = screenFrame.origin.y

    let targetY = show ? onScreenY : offScreenY

    NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.2
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        window.animator().setFrameOrigin(NSPoint(x: (screenFrame.width - windowWidth) / 2, y: targetY))
    } completionHandler: {
        completion?()
    }
}

// 方案 B: SwiftUI transition (适用于视图内部)
struct SlideTransition: View {
    @State private var isVisible = false

    var body: some View {
        ContentView()
            .offset(y: isVisible ? 0 : 200)
            .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}
```

**来源:** SwiftUI 动画文档

### 模式 3: 横向滚动卡片列表

**用途:** 高性能横向滚动的卡片列表
**何时使用:** 显示剪贴板历史记录

```swift
struct CardListView: View {
    let items: [ClipboardItem]
    @State private var selectedID: Int64?
    @FocusState private var focusedID: Int64?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items) { item in
                    ClipboardCardView(item: item, isSelected: selectedID == item.id)
                        .focused($focusedID, equals: item.id)
                        .onTapGesture {
                            selectedID = item.id
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
```

**来源:** SwiftUI ScrollView 文档

### 模式 4: 卡片视图组件

**用途:** 渲染单个剪贴板卡片
**何时使用:** 显示不同类型的内容预览

```swift
struct ClipboardCardView: View {
    let item: ClipboardItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 类型标签 + 收藏标记
            HStack {
                Text(item.itemType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }

            // 内容预览
            switch item.itemType {
            case .text:
                TextPreview(content: item.content)
            case .image:
                ImagePreview(data: item.data)
            case .file:
                FilePreview(content: item.content)
            case .rtf:
                TextPreview(content: item.content)
            }

            Spacer()

            // 来源 + 时间
            HStack {
                if let iconData = item.sourceAppIcon,
                   let nsImage = NSImage(data: iconData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                Text(item.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 250, height: 250)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
```

### 模式 5: 键盘导航

**用途:** 支持左右箭头键选择卡片
**何时使用:** 窗口激活时

```swift
struct CardListView: View {
    @State private var selectedIndex = 0
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        CardView(item: item, isSelected: selectedIndex == index)
                            .id(item.id)
                    }
                }
            }
            .focused($isFocused)
            .onKeyPress(.leftArrow) {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                    scrollToItem(proxy: proxy)
                }
                return .handled
            }
            .onKeyPress(.rightArrow) {
                if selectedIndex < items.count - 1 {
                    selectedIndex += 1
                    scrollToItem(proxy: proxy)
                }
                return .handled
            }
            .onKeyPress(.return) {
                selectCurrentItem()
                return .handled
            }
            .onKeyPress(.escape) {
                hideWindow()
                return .handled
            }
        }
    }

    func scrollToItem(proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo(items[selectedIndex].id, anchor: .center)
        }
    }
}
```

**来源:** SwiftUI FocusState 文档 (macOS 13+)

## 避免手动实现

| 问题 | 不要自己写 | 使用现有方案 | 原因 |
|------|-----------|-------------|------|
| 窗口位置计算 | 手动计算屏幕坐标 | NSScreen.main.visibleFrame | 处理多显示器、Dock 位置 |
| 毛玻璃效果 | 自定义半透明视图 | .ultraThinMaterial | 系统原生，性能优化 |
| 图片加载 | 手动异步加载 | AsyncImage 或 NSImage(data:) | 内置缓存和生命周期 |
| 列表滚动 | 手动管理偏移量 | ScrollViewReader | 自动处理虚拟化 |
| 键盘事件 | NSEvent addMonitor | SwiftUI .onKeyPress | 类型安全，自动清理 |

**关键洞察:** SwiftUI 在 macOS 13+ 提供了完整的键盘导航 API，无需使用底层 NSEvent。

## 常见陷阱

### 陷阱 1: 窗口位置错误
**问题:** 使用 `NSScreen.main?.frame` 而非 `visibleFrame`
**原因:** frame 包含菜单栏和 Dock 区域
**避免方法:** 使用 `visibleFrame` 获取可用区域
**预警信号:** 窗口被 Dock 遮挡或超出屏幕边界

### 陷阱 2: 多显示器不跟随
**问题:** 窗口总是显示在主显示器
**原因:** 使用 `NSScreen.main` 而非活动显示器
**避免方法:**
```swift
// 获取鼠标所在的显示器
let mouseLocation = NSEvent.mouseLocation
let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) }
```

### 陷阱 3: LazyHStack 不复用视图
**问题:** 大量卡片时内存持续增长
**原因:** HStack 会预加载所有子视图
**避免方法:** 使用 `LazyHStack` 实现懒加载

### 陷阱 4: 动画卡顿
**问题:** 窗口动画不流畅
**原因:** 在动画期间执行繁重操作
**避免方法:** 数据预加载，动画前完成布局计算

### 陷阱 5: 点击外部不关闭
**问题:** 点击窗口外部无法关闭
**原因:** 未配置 `hidesOnDeactivate` 或缺少全局点击监听
**避免方法:**
```swift
// 方案 A: 监听应用失去激活
NotificationCenter.default.addObserver(
    forName: NSApplication.didResignActiveNotification,
    object: nil,
    queue: .main
) { _ in
    hideWindow()
}

// 方案 B: 全局点击监听
NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { _ in
    hideWindow()
}
```

## 代码示例

### 底部弹出窗口完整实现

```swift
// WindowService.swift
import AppKit

class WindowService {
    static let shared = WindowService()
    private var panel: NSPanel?
    private var isAnimating = false

    private let windowHeight: CGFloat = 140

    func createPanel(with content: NSView) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: NSScreen.main!.frame.width, height: windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.contentView = content
        panel.acceptsMouseMovedEvents = true

        return panel
    }

    func showWindow() {
        guard let panel = panel, !isAnimating else { return }

        isAnimating = true

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        // 从底部滑入
        animateToPosition(visible: true) { [weak self] in
            self?.isAnimating = false
        }
    }

    func hideWindow() {
        guard let panel = panel, panel.isVisible, !isAnimating else { return }

        isAnimating = true

        // 滑出到底部
        animateToPosition(visible: false) { [weak self] in
            panel.orderOut(nil)
            self?.isAnimating = false
        }
    }

    private func animateToPosition(visible: Bool, completion: @escaping () -> Void) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        let targetY = visible ? screenFrame.origin.y : screenFrame.origin.y - windowHeight - 10

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel?.animator().setFrameOrigin(
                NSPoint(x: screenFrame.origin.x, y: targetY)
            )
        } completionHandler: {
            completion()
        }
    }
}
```

### 卡片列表 ViewModel

```swift
// ClipboardViewModel.swift
import SwiftUI
import Combine

@MainActor
class ClipboardViewModel: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var selectedIndex: Int = 0

    private let database: DatabaseService
    private var cancellables = Set<AnyCancellable>()

    init(database: DatabaseService) {
        self.database = database
        loadItems()
    }

    func loadItems() {
        Task {
            do {
                items = try database.fetchRecent(limit: 100)
            } catch {
                print("Failed to load items: \(error)")
            }
        }
    }

    func selectNext() {
        guard selectedIndex < items.count - 1 else { return }
        selectedIndex += 1
    }

    func selectPrevious() {
        guard selectedIndex > 0 else { return }
        selectedIndex -= 1
    }

    func selectCurrent() {
        guard selectedIndex < items.count else { return }
        let item = items[selectedIndex]
        // 复制到剪贴板（Phase 3 实现）
    }
}
```

## 现状与趋势

| 旧方案 | 当前方案 | 变化时间 | 影响 |
|--------|----------|----------|------|
| NSEvent.addLocalMonitor | .onKeyPress 修饰符 | macOS 13 | 类型安全的键盘处理 |
| HStack | LazyHStack | SwiftUI 2.0 | 滚动性能优化 |
| NSVisualEffectView | .ultraThinMaterial | SwiftUI 3.0 | 声明式毛玻璃效果 |
| NSWindow | NSPanel | 始终 | 浮动窗口专用 API |

**已弃用/过时:**
- NSWindow.frameAnimation: 使用 NSAnimationContext 替代
- manual NSView clipping: 使用 SwiftUI clipShape 替代

## 开放问题

1. **窗口高度精确值**
   - 已知范围: 120-150px
   - 不确定: 具体值依赖实际卡片布局测试
   - 建议: 先用 140px，后续根据视觉反馈调整

2. **点击外部关闭的实现**
   - 已知: 需要 hideOnDeactivate 或全局监听
   - 不确定: 哪种方案用户体验更好
   - 建议: 实现两种方案，用户测试后选择

## 验证架构

### 测试框架
| 属性 | 值 |
|------|-----|
| 框架 | XCTest (Xcode 原生) |
| 配置文件 | 无 — 参见 Wave 0 |
| 快速运行命令 | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` |
| 完整套件命令 | 同上 |

### 阶段需求 → 测试映射
| 需求 ID | 行为 | 测试类型 | 自动化命令 | 文件存在? |
|---------|------|---------|-----------|-----------|
| 2.1 | 窗口在屏幕底部显示 | 手动 | N/A | ❌ Wave 0 |
| 2.2 | 滑入/滑出动画 0.2s | 手动 | N/A | ❌ Wave 0 |
| 2.3 | 卡片显示内容预览 | 手动 | N/A | ❌ Wave 0 |
| 2.4 | 横向滚动工作 | 手动 | N/A | ❌ Wave 0 |
| 2.5 | 选中高亮效果 | 手动 | N/A | ❌ Wave 0 |
| 2.6 | 来源应用图标显示 | 手动 | N/A | ❌ Wave 0 |

### 采样率
- **每次任务提交:** 手动验证该任务功能
- **每波次合并:** 手动验证所有阶段功能
- **阶段门禁:** 全部手动验证通过后 `/gsd:verify-work`

### Wave 0 缺口
- [ ] `Z-PasteTests/` — 单元测试目录
- [ ] `Z-PasteTests/CardListViewTests.swift` — 卡片列表测试
- [ ] `Z-PasteTests/WindowServiceTests.swift` — 窗口服务测试

*注意: 本阶段 UI 功能主要依赖手动验证，自动化测试覆盖率较低。*

## 来源

### 主要来源 (HIGH 置信度)
- Apple Developer Documentation - NSPanel
- Apple Developer Documentation - SwiftUI FocusState
- Apple Developer Documentation - NSAnimationContext
- Phase 1 Research: `.planning/phases/01-project-foundation/01-RESEARCH.md`

### 次要来源 (MEDIUM 置信度)
- SwiftUI ScrollView Performance Best Practices (Hacking with Swift)
- NSWindow Level and Collection Behavior (Stack Overflow 验证)

### 第三来源 (LOW 置信度)
- WebSearch: macOS Sequoia Liquid Glass Design (未验证)

## 元数据

**置信度细分:**
- 标准技术栈: HIGH - 基于 Apple 官方文档
- 架构模式: HIGH - 基于 SwiftUI 标准实践
- 常见陷阱: MEDIUM - 部分来自经验总结

**研究时间:** 2026-03-17
**有效期至:** 30 天 (稳定 API)

---

*研究完成时间: 2026-03-17*
