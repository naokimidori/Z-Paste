# Phase 3: 交互功能 - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 3 目标：为现有底部弹窗卡片列表补齐核心交互能力，让用户可以直接对历史项执行粘贴、复制、收藏、删除，以及批量操作。

**交付内容：**
1. 点击卡片将内容用于当前应用的粘贴流程
2. 右键菜单提供复制、收藏/取消收藏、删除操作
3. 收藏/取消收藏状态可即时反馈
4. 删除历史项功能可即时生效
5. 批量操作作为本阶段低优先级能力纳入规划

**不包含：**
- 搜索与过滤（Phase 4）
- 设置界面（Phase 5）
- 更复杂的同步、分享、云端能力（未来阶段）

</domain>

<decisions>
## Implementation Decisions

### 卡片触发行为
- **单击卡片即执行主动作：** 将该条历史重新写入系统剪贴板，并立即尝试粘贴到当前活动应用。
- **键盘确认与鼠标点击保持一致：** Enter 触发与单击卡片相同的主动作。
- **执行后自动关闭窗口：** 保持快速操作流，沿用 Phase 2 已定下的“选择后自动关闭”。
- **主动作面向所有已支持类型：** 文本、图片、文件、富文本都走统一的“选中并执行粘贴/复制流”。

### 右键菜单结构
- **右键菜单仅放单项操作：** 复制、收藏/取消收藏、删除。
- **菜单顺序：** 复制 → 收藏/取消收藏 → 删除，危险操作放最后。
- **菜单文案跟随当前状态：** 已收藏项显示“取消收藏”，未收藏项显示“收藏”。
- **右键不直接执行主动作：** 右键仅用于次级管理操作，不触发粘贴。

### 收藏规则
- **收藏状态即时切换：** 在当前列表中立刻更新星标显示，无需重新打开窗口。
- **收藏项继续与普通项混排：** 延续 Phase 2 已确认的展示规则，不单独置顶、不改排序模型。
- **收藏是轻量标记，不弹确认：** 适合高频切换。

### 删除规则
- **删除从右键菜单进入：** 避免误触主动作。
- **默认直接删除，不额外弹确认框：** 保持操作轻量，但仅通过右键菜单暴露。
- **删除后列表立即刷新并保持可继续操作：** 若删除的是当前选中项，选择应平滑移动到相邻可用项；若已空则回到空状态。

### 批量操作边界
- **批量操作是本阶段最后实现的低优先级能力：** 先保证单项粘贴、收藏、删除闭环稳定。
- **批量操作范围以管理型操作为主：** 优先考虑批量删除、批量收藏，不扩展为复杂整理系统。
- **批量粘贴不是默认重点：** 如需支持，必须作为次级能力处理，不能干扰单击即粘贴的主流程。

### Claude's Discretion
- 实际粘贴实现细节（如通过模拟快捷键或事件分发完成）
- 右键菜单的具体交互承载形式（SwiftUI contextMenu 或 AppKit 菜单桥接）
- 删除后选中项向前还是向后回退的具体规则
- 批量模式的具体入口和 UI 细节，但应保持轻量、不可抢占主流程
- 粘贴失败时的提示方式与降级反馈

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 项目需求与路线
- `.planning/REQUIREMENTS.md` — FR-2 历史管理、FR-3.5 点击卡片复制/粘贴、NFR-2 隐私约束
- `.planning/ROADMAP.md` — Phase 3 范围、任务列表与验证标准
- `.planning/STATE.md` — 当前阶段状态、已锁定的前序决策与最新实现情况

### 前序阶段决策
- `.planning/phases/01-project-foundation/01-CONTEXT.md` — 技术栈、存储方式、隐私与排除策略
- `.planning/phases/01-project-foundation/01-RESEARCH.md` — Phase 1 技术研究与 API 背景
- `.planning/phases/02-main-interface/02-CONTEXT.md` — 已锁定的窗口行为、键盘导航、排序与收藏展示规则
- `.planning/phases/02-main-interface/02-UI-SPEC.md` — 当前主界面的卡片尺寸、布局和视觉约束

### 现有实现入口
- `Z-Paste/ViewModels/ClipboardViewModel.swift` — 当前键盘选择与主动作入口（copySelected）占位实现
- `Z-Paste/Views/MainWindow/CardListView.swift` — 卡片点击、回车触发、列表滚动与选中逻辑
- `Z-Paste/Views/MainWindow/ClipboardCardView.swift` — 卡片点击交互与收藏标记展示位置
- `Z-Paste/Services/DatabaseService.swift` — 已有删除、收藏切换、最近记录查询能力
- `Z-Paste/Services/ClipboardService.swift` — 剪贴板写回/监听相关现有能力与通知机制
- `Z-Paste/App/AppDelegate.swift` — 窗口生命周期、隐藏行为与服务装配入口

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ClipboardViewModel` — 已有 items、selectedIndex、键盘导航与 `copySelected()` 占位入口，适合作为单项交互编排层。
- `DatabaseService` — 已提供 `delete(id:)`、`toggleFavorite(id:isFavorite:)`、`fetchRecent(limit:)`、`fetchFavorites()`，可直接支撑收藏/删除交互。
- `CardListView` — 已实现点击卡片选中、Enter/Escape、左右切换和滚动到选中项，是主交互接入点。
- `ClipboardCardView` — 已有卡片点击和星标显示，可在不改整体结构的前提下接入更多交互反馈。
- `ClipboardService` — 已有剪贴板内容提取、通知刷新、图标缓存等能力，可复用到“重新写回剪贴板”流程。

### Established Patterns
- 当前 UI 状态由 `@StateObject` + `@ObservedObject` 驱动，数据刷新通过 `loadItems()` 和 `clipboardItemsDidChange` 通知更新。
- 列表排序已固定为按 `created_at` 倒序展示；收藏仅作为标记，不改变 Phase 2 已定的混排规则。
- 主窗口是 `NSPanel` + `NSHostingController`，选择动作后关闭窗口已经是既有交互模式。
- 项目保持轻量原生实现，优先沿用现有 SwiftUI/AppKit/GRDB 组合，不引入新依赖。

### Integration Points
- `ClipboardViewModel.copySelected()` 是实现“点击/回车执行主动作”的首要接入点。
- `CardListView` 的 `.onTapGesture` 与 `onReturn` 需要统一到同一条交互链路。
- 收藏/删除动作应落到 `DatabaseService`，然后触发列表即时刷新并维持选择状态。
- 如需真正向前台应用发送粘贴，应与 `WindowService` / `AppDelegate` 的隐藏时机协同，避免窗口抢焦点影响粘贴目标。

</code_context>

<specifics>
## Specific Ideas

- Phase 2 已经明确：键盘导航存在、Enter 为确认动作、选择后自动关闭，因此 Phase 3 应保持“快速选中 → 执行 → 收起”的单手流程。
- 当前卡片头部右上角已显示星标，说明收藏最自然的反馈方式是直接复用现有视觉位置。
- 删除与收藏都应尽量在当前面板内完成反馈，避免引入新窗口或复杂确认流。
- 右键菜单应该是补充管理入口，不应削弱“单击即完成主任务”的效率定位。

</specifics>

<deferred>
## Deferred Ideas

- 更复杂的批量整理体验（多选工具栏、批量标签、批量移动）— 如超出轻量实现，可拆到后续 phase/backlog
- 搜索、过滤后的批量管理 — Phase 4 以后再结合实现
- 设置中自定义点击行为（只复制、不粘贴等）— 更适合 Phase 5 设置界面

</deferred>

---

*Phase: 03-interaction-features*
*Context gathered: 2026-03-18*
