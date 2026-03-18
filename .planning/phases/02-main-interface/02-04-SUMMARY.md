---
phase: 02-main-interface
plan: 04
subsystem: ui
tags: [swiftui, appkit, nspanel, appdelegate, integration, hotkey]

requires:
  - phase: 02-01
    provides: WindowService with NSPanel creation and slide animation
  - phase: 02-03
    provides: MainWindowView dependencies via CardListView and ClipboardViewModel
  - phase: 01-03
    provides: DatabaseService and ClipboardService core services
  - phase: 01-04
    provides: HotkeyService global shortcut binding
provides:
  - MainWindowView container composing CardListView and view model lifecycle
  - AppDelegate integration wiring WindowService, DatabaseService, ClipboardService, and hotkey toggle
  - NSHostingController-based SwiftUI embedding inside NSPanel
  - End-to-end bottom popup main interface flow
affects: [03-interaction-features, clipboard-actions, paste-flow, window-lifecycle]

tech-stack:
  added: []
  patterns:
    - "SwiftUI view embedded in NSPanel via NSHostingController"
    - "AppDelegate as composition root for desktop services"
    - "Window hide callbacks passed from AppKit container into SwiftUI views"

key-files:
  created:
    - Z-Paste/Views/MainWindow/MainWindowView.swift
  modified:
    - Z-Paste/App/AppDelegate.swift
    - Z-Paste/Views/ContentView.swift

key-decisions:
  - "Use MainWindowView as a thin container that reloads recent clipboard history on appear"
  - "Let AppDelegate own service composition and inject DatabaseService into MainWindowView"
  - "Route hide/copy interactions back to WindowService through callback closures"

patterns-established:
  - "Desktop composition root: AppDelegate initializes services, creates SwiftUI root view, and mounts it through NSHostingController"
  - "Popup lifecycle: hotkey toggles window, window appearance triggers data reload, copy/hide actions close the panel"

requirements-completed: [2.1, 2.2, 2.3, 2.4, 2.5]

duration: 5min
completed: 2026-03-18
---

# Phase 2 Plan 4: MainWindowView & AppDelegate Integration Summary

**底部弹出主窗口现已串联 WindowService、卡片列表、快捷键与数据加载，形成完整可唤起的主界面流。**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-18T00:00:00Z
- **Completed:** 2026-03-18T00:05:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- 创建 MainWindowView 作为主窗口 SwiftUI 容器，并在显示时刷新最近历史
- 在 AppDelegate 中完成 DatabaseService、ClipboardService、WindowService、HotkeyService 的集成编排
- 打通 Option + ` 唤起、底部弹出、卡片浏览、复制后关闭、手动验证通过的完整流程

## Task Commits

Each task was committed atomically:

1. **Task 1: 创建 MainWindowView** - `154c849` (feat)
2. **Task 2: 重构 AppDelegate 集成所有组件** - `5fe172b` (feat)
3. **Task 3: checkpoint:human-verify** - user approved

**Plan metadata:** pending in current session

## Files Created/Modified
- `Z-Paste/Views/MainWindow/MainWindowView.swift` - 主窗口视图容器，负责持有 ClipboardViewModel 与窗口隐藏回调
- `Z-Paste/App/AppDelegate.swift` - 应用生命周期入口，完成服务初始化、窗口挂载、热键切换与主界面整合
- `Z-Paste/Views/ContentView.swift` - 配合 AppDelegate 集成后的应用入口视图调整

## Decisions Made
- 使用 `@StateObject` 在 MainWindowView 中持有 ClipboardViewModel，保证窗口内容状态由 SwiftUI 生命周期管理
- 使用 `NSHostingController` 将 SwiftUI 主界面嵌入 WindowService 创建的 NSPanel
- 通过闭包把隐藏窗口行为从 AppKit 层传递到 SwiftUI 子视图，避免 MainWindowView 直接依赖窗口实现细节

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
存在执行收尾时的权限阻塞，但在用户明确允许 Bash 后已继续完成文档与状态更新。

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- 主界面基础流程已可用于后续交互功能开发
- Phase 3 可在现有窗口与选中状态基础上继续实现粘贴、收藏、删除等操作
- 本计划的人类验证检查点已获用户 approved

---
*Phase: 02-main-interface*
*Completed: 2026-03-18*
