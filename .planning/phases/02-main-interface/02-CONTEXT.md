# Phase 2: 主界面实现 - Context

**Gathered:** 2026-03-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 目标：实现底部弹窗和卡片列表界面

**交付内容:**
1. MainWindow - 底部弹出窗口
2. 滑入/滑出动画效果
3. ClipboardCard - 卡片组件
4. 横向滚动列表
5. 选中状态和高亮效果
6. 来源应用图标获取

**不包含:**
- 点击卡片粘贴功能 (Phase 3)
- 右键菜单 (Phase 3)
- 收藏/删除功能 (Phase 3)
- 搜索功能 (Phase 4)
- 设置界面 (Phase 5)

</domain>

<decisions>
## Implementation Decisions

### 窗口行为
- **位置：** 屏幕底部中央
- **尺寸：** 宽度 100% 全屏宽，高度固定（约 120-150px，由 Claude 决定具体值）
- **多显示器：** 跟随活动显示器
- **层级：** 始终置顶（NSPanel + canBecomeKey）

### 卡片设计
- **尺寸：** 250px × 250px 正方形
- **样式：** 圆角
- **类型标签：** 左上角显示类型名称（文本/图片/文件/富文本）
- **选中状态：** 高亮边框
- **显示信息：** 来源应用图标、时间戳、内容大小、收藏标记
- **文本预览：** 多行预览，超出部分省略
- **图片展示：** 缩略图填满卡片
- **文件展示：** 图标 + 文件名 + 大小

### 动画效果
- **弹出动画：** 底部滑入
- **收起动画：** 滑出屏幕
- **动画时长：** 0.2 秒
- **关闭触发：** 快捷键切换、点击外部关闭、ESC 关闭、选择后自动关闭

### 交互方式
- **键盘导航：** 左右箭头键选择卡片，Enter 确认
- **默认选中：** 最新卡片（最左侧）
- **选择行为：** 仅复制到剪贴板，不自动粘贴
- **右键菜单：** 复制、收藏/取消收藏、删除

### 空状态
- 显示友好提示文字（如"暂无剪贴板历史"）

### 排序规则
- 按时间倒序，最新复制的在最左边

### 收藏显示
- 收藏卡片与普通卡片混合显示，仅标记星标图标

### 间距样式
- 卡片间距：8-12px
- 内边距：16px

### 视觉风格
- **整体风格：** 遵循 macOS 液态玻璃设计规范
- **窗口背景：** 半透明 + 毛玻璃模糊效果
- **卡片样式：** 玻璃质感，轻微阴影
- **悬停效果：** 轻微高亮
- **主题：** 跟随系统深色/浅色模式

### Claude's Discretion
- 窗口具体高度值（建议 120-150px）
- 卡片圆角半径
- 阴影具体参数
- 动画缓动曲线
- 滚动条样式

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 项目需求
- `.planning/REQUIREMENTS.md` — 完整功能需求和非功能需求
- `.planning/ROADMAP.md` — Phase 2 目标和验证标准

### 先前阶段
- `.planning/phases/01-project-foundation/01-CONTEXT.md` — Phase 1 决策（技术栈、架构、依赖库）
- `.planning/phases/01-project-foundation/01-RESEARCH.md` — 技术调研和 API 参考

### macOS 设计规范
- Apple Human Interface Guidelines — macOS 设计原则
- macOS Sequoia Liquid Glass — 液态玻璃设计规范

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ClipboardItem` (Models/ClipboardItem.swift) — 数据模型，包含 content, itemType, sourceApp, sourceAppIcon, isFavorite 等字段
- `ClipboardService` (Services/ClipboardService.swift) — 剪贴板监听服务，提供 `onNewItem` 回调
- `DatabaseService` (Services/DatabaseService.swift) — 数据库服务，可查询历史记录
- `HotkeyService` (Services/HotkeyService.swift) — 快捷键服务，已集成 KeyboardShortcuts 库

### Established Patterns
- MVVM 架构
- SwiftUI 视图
- GRDB.swift 数据库操作
- KeyboardShortcuts 全局快捷键

### Integration Points
- `ContentView.swift` — 当前占位符视图，需替换为 MainWindow
- `ClipboardService.onNewItem` — 用于 UI 更新回调
- `DatabaseService.fetchAll()` — 获取历史记录列表
- `HotkeyService` — 触发窗口显示/隐藏

</code_context>

<specifics>
## Specific Ideas

### 窗口布局示意
```
┌─────────────────────────────────────────────────────────────────┐
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │ 文本    │ │ 图片    │ │ 文件    │ │ 链接    │ │ 文本    │  │
│  │ 1分钟前 │ │ 5分钟前 │ │ 10分钟前│ │ 15分钟前│ │ 20分钟前│  │
│  │ ...内容 │ │ [缩略图]│ │ 📄 file │ │ url...  │ │ ...内容 │  │
│  │ 383字符 │ │ 2.1MB   │ │ 128KB   │ │ 28字符  │ │ 156字符 │  │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘  │
│   ← 横向滚动 →                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 卡片结构
```
┌─────────────────────┐
│ 文本          ⭐    │  ← 类型标签(左上) + 收藏标记(右上)
│                     │
│ 这是一段文本预览... │  ← 多行内容预览
│ 第二行内容...       │
│                     │
│ 📱 Safari  2分钟前  │  ← 来源图标 + 时间戳
│ 383 字符            │  ← 内容大小
└─────────────────────┘
```

</specifics>

<deferred>
## Deferred Ideas

- 点击卡片粘贴功能 — Phase 3
- 右键菜单交互 — Phase 3
- 收藏/删除功能 — Phase 3
- 搜索功能 — Phase 4
- 设置界面 — Phase 5

</deferred>

---

*Phase: 02-main-interface*
*Context gathered: 2026-03-17*
