# Phase 4: 搜索与过滤 - Research

**Researched:** 2026-03-21
**Domain:** SwiftUI + GRDB 搜索/过滤与高亮
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- 组合筛选（例如“收藏里的图片”或“链接中的文本再叠加类型”）— 可作为后续增强能力再评估
- 保留上次搜索词、可配置默认焦点行为 — 更适合放到设置相关阶段讨论
- 更复杂的无结果恢复动作（同时提供清空搜索与回到全部）— 如后续验证发现必要再补充
</user_constraints>

## Summary

本阶段需要在既有单窗口卡片流中追加“左搜右筛”的顶栏，并把搜索词与单一互斥筛选条件合并为同一过滤管线。现有 DatabaseService 已有 `search(query:)`，但当前 ViewModel 只拉取最近记录并由 KeyCaptureView 抢焦；因此规划必须明确：搜索状态在 ViewModel 统一管理、列表渲染与空状态在 CardListView 切换、输入焦点对键盘导航的优先级处理。

高亮与筛选不应引入新依赖，推荐使用 SwiftUI 原生的 `AttributedString` 或 `Text` 组合实现高亮覆盖，仅作用于文本/富文本卡片内容区域，图片/文件仅显示为普通预览。链接筛选必须基于“系统可打开 URL”判定，且富文本归入“文本”筛选。搜索匹配范围建议覆盖 `content` 与文件路径的文件名（`itemType == .file`），是否覆盖 `sourceApp` 需在隐私与可预期性之间权衡。

**Primary recommendation:** 以 ViewModel 为核心维护 `searchQuery` 与 `activeFilter`，通过统一的过滤函数/查询入口驱动列表与空状态，并在搜索输入焦点期间临时让 KeyCaptureView 退让键盘控制。

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | 系统内置 | 视图与交互 | 现有主界面已完全基于 SwiftUI |
| AppKit | 系统内置 | NSPanel/键盘事件 | 现有 KeyCaptureView 与窗口行为依赖 |
| GRDB.swift | 6.29.3 | SQLite 访问 | 现有 DatabaseService 已集成 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation | 系统内置 | URL/AttributedString 等 | URL 判定、文本处理 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| LIKE 过滤 | SQLite FTS | FTS 需要迁移和索引，超出当前范围 |
| SwiftUI Text 组合 | NSAttributedString 渲染 | 可能需要 AppKit 兼容与额外桥接 |

**Installation:**
```bash
# 无新增依赖
```

**Version verification:**
- GRDB.swift 版本来自 `Package.resolved`（6.29.3）。非 npm 生态，无法通过 npm view 验证。

## Architecture Patterns

### Recommended Project Structure
```
Z-Paste/
├── ViewModels/
│   └── ClipboardViewModel.swift   # 搜索词/筛选状态与过滤管线
├── Views/
│   └── MainWindow/
│       ├── MainWindowView.swift   # 顶部搜索与筛选入口
│       ├── CardListView.swift     # 空状态与过滤结果列表
│       └── ClipboardCardView.swift# 高亮展示入口
└── Services/
    └── DatabaseService.swift      # 组合搜索/筛选查询
```

### Pattern 1: 统一过滤管线（Query + Filter）
**What:** 在 ViewModel 维护 `searchQuery` + `activeFilter`，并将其统一作用于数据库查询或内存过滤。
**When to use:** 需要搜索与互斥筛选组合生效，且空状态需区分“无历史”与“无结果”。
**Example:**
```swift
// Source: Z-Paste/ViewModels/ClipboardViewModel.swift
// 现有 loadItems() 仅 fetchRecent，需要扩展为统一搜索/筛选入口
```

### Pattern 2: 焦点驱动键盘优先级
**What:** 搜索框聚焦时，左右方向键用于文本光标；失焦后恢复卡片导航。
**When to use:** 顶部搜索框常驻，且存在 KeyCaptureView 拦截键盘事件。
**Example:**
```swift
// Source: Z-Paste/Views/MainWindow/CardListView.swift
// KeyCaptureView 当前总是 makeFirstResponder，需要在搜索框聚焦时退让
```

### Anti-Patterns to Avoid
- **在搜索输入时仍强制 KeyCaptureView 成为第一响应者：** 会导致方向键无法编辑文本，违背明确决策。
- **多重筛选组合 UI：** 已明确单层互斥筛选，禁止叠加多条件 UI。

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 文本高亮渲染 | 手写字符级绘制 | SwiftUI `AttributedString` / Text 组合 | 简化渲染、适配系统字体与主题 |
| URL 判定 | 自定义正则解析 | 系统 URL 可打开性判定 | 降低误判，符合“系统可打开 URL”规则 |

**Key insight:** 现有 UI 以 SwiftUI 为主，手写渲染和复杂解析会增加维护成本并影响性能。

## Common Pitfalls

### Pitfall 1: 搜索输入与键盘导航冲突
**What goes wrong:** KeyCaptureView 抢焦，导致方向键无法编辑搜索文本。
**Why it happens:** CardListView 强制设置 first responder。
**How to avoid:** 搜索框聚焦时停止抢焦或改为条件性拦截键盘事件。
**Warning signs:** 搜索框中左右方向键不移动光标。

### Pitfall 2: 空状态混淆
**What goes wrong:** 搜索无结果与无历史共用文案和图标。
**Why it happens:** 仅判断 items 是否为空，未区分过滤后空结果。
**How to avoid:** 维护“原始数据为空”与“过滤结果为空”两个状态。
**Warning signs:** 清空搜索后仍显示“无结果”文案或相反。

### Pitfall 3: 搜索性能退化
**What goes wrong:** 每次输入触发全量查询或复杂过滤导致响应卡顿。
**Why it happens:** 未做节流或过滤在主线程上进行。
**How to avoid:** 轻量查询、必要时加入短时节流；在 ViewModel 中集中管理。
**Warning signs:** 搜索输入卡顿、CPU 占用飙升。

## Code Examples

Verified patterns from official sources:

### 搜索入口（现有 DatabaseService.search）
```swift
// Source: Z-Paste/Services/DatabaseService.swift
func search(query: String) throws -> [ClipboardItem] {
    return try dbQueue.read { db in
        try ClipboardItem
            .filter(Column("content").like("%\(query)%"))
            .order(Column("created_at").desc)
            .fetchAll(db)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 仅加载最近记录 | 搜索+互斥筛选统一管线 | Phase 4 | 支撑实时搜索与过滤空状态 |

**Deprecated/outdated:**
- 仅依赖 `fetchRecent(limit:)` 的展示逻辑：在搜索与筛选加入后不再满足需求。

## Open Questions

1. **搜索匹配范围是否覆盖来源应用名/文件名**
   - What we know: 决策允许 Claude 选择是否覆盖 `content` 以外字段。
   - What's unclear: 是否会引入隐私或误匹配问题。
   - Recommendation: 默认覆盖文本 `content`，文件类型额外匹配文件名；来源应用名需用户确认后再纳入。

2. **搜索高亮在富文本/图片/文件上的策略**
   - What we know: 仅文本匹配可直接高亮。
   - What's unclear: 富文本是否需要还原格式；图片/文件是否显示命中提示。
   - Recommendation: 仅对文本/富文本内容预览高亮，图片/文件不高亮但保留正常预览。

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (系统内置) |
| Config file | none — see Wave 0 |
| Quick run command | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` |
| Full suite command | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FR-4.1 | 文本内容搜索 | unit | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` | ❌ Wave 0 |
| FR-4.2 | 实时过滤结果 | unit/integration | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` | ❌ Wave 0 |
| FR-4.3 | 搜索高亮 | unit/UI | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'`
- **Per wave merge:** `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `Tests/Z-PasteTests/SearchFilterTests.swift` — 覆盖 FR-4.1/FR-4.2/FR-4.3
- [ ] UI 验证辅助（若需高亮 UI 行为）

## Sources

### Primary (HIGH confidence)
- `/Users/longzhao/aicodes/Z-Paste/.planning/phases/04-search-filter/04-CONTEXT.md` — 过滤模型、搜索入口、空结果约束
- `/Users/longzhao/aicodes/Z-Paste/Z-Paste/Services/DatabaseService.swift` — 现有搜索入口
- `/Users/longzhao/aicodes/Z-Paste/Z-Paste/ViewModels/ClipboardViewModel.swift` — 数据加载与状态管理入口
- `/Users/longzhao/aicodes/Z-Paste/Z-Paste/Views/MainWindow/CardListView.swift` — 键盘事件拦截与空状态
- `/Users/longzhao/aicodes/Z-Paste/Z-Paste/Views/MainWindow/MainWindowView.swift` — 顶部工具栏挂载点
- `/Users/longzhao/aicodes/Z-Paste/Z-Paste/Views/MainWindow/ClipboardCardView.swift` — 卡片内容渲染入口
- `/Users/longzhao/aicodes/Z-Paste/Z-Paste.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` — GRDB.swift 版本

### Secondary (MEDIUM confidence)
- `/Users/longzhao/aicodes/Z-Paste/.planning/REQUIREMENTS.md` — FR-4.1/FR-4.2/FR-4.3
- `/Users/longzhao/aicodes/Z-Paste/.planning/ROADMAP.md` — Phase 4 任务与验证标准

### Tertiary (LOW confidence)
- 无

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - 现有依赖与系统库已锁定
- Architecture: MEDIUM - 需结合现有 ViewModel/KeyCaptureView 行为调整
- Pitfalls: MEDIUM - 基于当前键盘拦截与空状态结构判断

**Research date:** 2026-03-21
**Valid until:** 2026-04-20
