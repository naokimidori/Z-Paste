# Phase 4: 搜索与过滤 - Context

**Gathered:** 2026-03-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 4 目标：在现有底部弹窗卡片列表中加入搜索与过滤，让用户可以在当前面板内快速缩小剪贴板历史范围并定位目标内容。

**交付内容：**
1. 顶部搜索框组件
2. 实时文本搜索
3. 搜索结果高亮
4. 分类标签过滤（全部 / 收藏 / 链接）
5. 类型过滤（文本 / 图片 / 文件）

**不包含：**
- 新页面或独立搜索视图
- 设置项（如“记住上次搜索”开关）
- 复杂多条件筛选系统
- 新的数据类型体系重构

</domain>

<decisions>
## Implementation Decisions

### 过滤模型
- **采用单层互斥筛选：** 顶部所有筛选项放在同一排，每次只能激活一个条件。
- **筛选项混排展示：** 同一排同时包含 `全部 / 收藏 / 链接 / 文本 / 图片 / 文件`。
- **搜索词与筛选同时生效：** 输入关键词后，继续叠加当前单个筛选条件一起收窄结果。
- **链接筛选按“系统可打开 URL”判定：** 只把可识别为可打开网址的文本视为链接，不新增独立 link 类型。
- **富文本归入文本筛选：** UI 仍只保留文本 / 图片 / 文件三类类型过滤，RTF 跟文本一起进入“文本”结果。

### 搜索入口
- **顶部采用“左搜右筛”单行布局：** 搜索框在左，互斥筛选标签在右，保持现有面板结构紧凑。
- **窗口唤起后搜索框自动聚焦：** 用户呼出面板后可直接输入开始搜索。
- **每次重新打开窗口时清空搜索词：** 不保留上次关键词，保证每次呼起都是新的查找起点。
- **搜索编辑时方向键优先服务文本输入：** 当用户正在编辑搜索内容时，左右方向键先用于文本光标移动；退出或失焦后再恢复卡片导航。

### 空结果反馈
- **搜索/筛选无结果时使用专用无结果态：** 与“历史为空”区分，明确表达当前是过滤后的空结果。
- **无结果时优先提供“一键清空搜索词”出口：** 作为主要恢复动作。
- **若仅因筛选无结果且当前没有搜索词：** 不额外增加“回到全部”按钮，保持界面克制。
- **无结果时继续保留当前搜索词与筛选标签：** 让用户清楚知道无结果的原因。
- **无结果文案语气采用简洁直接风格：** 偏工具型表达，不走产品化口吻。

### Claude's Discretion
- 搜索匹配范围除 `content` 外，是否同时覆盖文件名、来源应用名等附加字段。
- 搜索高亮的具体承载方式、样式和对不同卡片类型的展示策略。
- 顶部筛选项的具体顺序、视觉样式与选中态细节。
- 无结果态的图标、辅助说明文案以及“清空搜索”触发形式。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 产品与范围
- `.planning/PROJECT.md` — 顶部工具栏草图、卡片式主界面方向、基础搜索定位
- `.planning/REQUIREMENTS.md` — FR-4.1 / FR-4.2 / FR-4.3 搜索需求，FR-2.3 收藏语义，FR-3 系列现有主界面约束
- `.planning/ROADMAP.md` — Phase 4 任务列表与验证标准
- `.planning/STATE.md` — 当前阶段推进状态与已锁定前序决策

### 前序阶段约束
- `.planning/phases/01-project-foundation/01-CONTEXT.md` — 数据类型、存储方式、轻量依赖与隐私边界
- `.planning/phases/02-main-interface/02-CONTEXT.md` — 横向卡片列表、排序规则、收藏混排、窗口与键盘交互约束
- `.planning/phases/02-main-interface/02-UI-SPEC.md` — 顶部/卡片/空状态的视觉与交互合同
- `.planning/phases/03-interaction-features/03-CONTEXT.md` — 当前主动作、收藏/删除、批量工具栏和面板内交互原则

### 现有实现入口
- `Z-Paste/ViewModels/ClipboardViewModel.swift` — 当前列表加载、选中、批量模式和错误状态入口
- `Z-Paste/Views/MainWindow/MainWindowView.swift` — 顶部 toolbar 现有挂载点，搜索/筛选的直接接入位置
- `Z-Paste/Views/MainWindow/CardListView.swift` — 横向卡片列表、空状态与键盘导航逻辑
- `Z-Paste/Views/MainWindow/ClipboardCardView.swift` — 卡片正文区域和未来高亮展示入口
- `Z-Paste/Services/DatabaseService.swift` — 现有 `search(query:)`、最近记录查询、收藏查询能力
- `Z-Paste/Models/ClipboardItem.swift` — 当前类型模型（text / image / file / rtf）与筛选边界

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DatabaseService.search(query:)` — 已有基础文本搜索入口，可作为实时搜索的底层起点。
- `MainWindowView.batchToolbar` — 顶部已经存在工具栏区域，适合接入搜索框与筛选标签。
- `CardListView.emptyStateView` — 现有空状态结构可扩展为“无结果态”。
- `ClipboardCardView` — 卡片内容区域已按类型分发预览，可承接后续搜索高亮展示。
- `ClipboardViewModel` — 已集中管理 `items`、选择状态、错误提示和批量模式，适合作为搜索/过滤状态编排层。

### Established Patterns
- 当前主界面仍然是单窗口、横向卡片流，不适合扩展成新页面式搜索体验。
- 收藏项继续和普通项混排，这是 Phase 2 / Phase 3 已锁定规则。
- 项目偏轻量原生实现，优先沿用 SwiftUI + AppKit + GRDB，不引入新的搜索状态管理方案。
- 当前数据模型没有独立链接类型，因此“链接”过滤必须建立在现有文本内容判定之上。

### Integration Points
- `MainWindowView.swift` 顶部布局需要从现有批量工具栏演化为搜索 + 过滤入口。
- `ClipboardViewModel.loadItems()` 当前只加载最近记录，后续需要接入搜索词和互斥筛选条件。
- `DatabaseService.swift` 需要支撑实时搜索与分类结果获取，或在现有查询基础上扩展过滤能力。
- `CardListView.swift` 需要在空状态和正常列表之间区分“历史为空”与“搜索/筛选无结果”。

</code_context>

<specifics>
## Specific Ideas

- 顶部结构延续 PROJECT.md 里的方向：搜索框 + 一排筛选标签，不额外开辟第二层界面。
- Phase 4 仍然服务快速呼起后的即时操作流，所以搜索框自动聚焦、每次重新打开清空关键词。
- 虽然 roadmap 里同时列了“分类过滤”和“类型过滤”，这次明确采用**单层互斥**，不做组合条件 UI。
- “链接”不是新类型，而是基于文本内容是否能被系统识别并打开来判定。

</specifics>

<deferred>
## Deferred Ideas

- 组合筛选（例如“收藏里的图片”或“链接中的文本再叠加类型”）— 可作为后续增强能力再评估
- 保留上次搜索词、可配置默认焦点行为 — 更适合放到设置相关阶段讨论
- 更复杂的无结果恢复动作（同时提供清空搜索与回到全部）— 如后续验证发现必要再补充

</deferred>

---

*Phase: 04-search-filter*
*Context gathered: 2026-03-21*
