# Phase 3: interaction-features - Research

**Researched:** 2026-03-18
**Domain:** macOS 剪贴板历史应用的核心交互实现（写回剪贴板、向前台应用粘贴、右键管理、即时刷新、轻量批量操作）
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- 更复杂的批量整理体验（多选工具栏、批量标签、批量移动）— 如超出轻量实现，可拆到后续 phase/backlog
- 搜索、过滤后的批量管理 — Phase 4 以后再结合实现
- 设置中自定义点击行为（只复制、不粘贴等）— 更适合 Phase 5 设置界面
</user_constraints>

## Summary

本阶段不应把 Phase 3 规划成“重新做一套交互框架”，而应围绕现有入口最小增量落地：`ClipboardViewModel` 作为单项动作编排层，`CardListView`/`ClipboardCardView` 作为点击、右键和批量入口承载层，`ClipboardService` 负责“写回系统剪贴板”，`DatabaseService` 负责收藏/删除/批量更新，`WindowService`/`AppDelegate` 负责窗口隐藏时机与焦点切换。现有代码已经具备 `items`、`selectedIndex`、键盘导航、点击选中、`Notification.Name.clipboardItemsDidChange`、`DatabaseService.toggleFavorite/delete/fetchRecent`、`WindowService.show/hide` 等关键基础，规划时应避免跨层重复刷新和窗口焦点抢占。

在 macOS 上，“重新写回剪贴板”是标准能力，`NSPasteboard` 官方支持 `clearContents()`、`setString(_:forType:)`、`writeObjects(_:)` 等写入路径；但“自动向前台应用粘贴”本质上不是剪贴板 API 的能力，而是要靠事件注入（例如发送 Command+V）或可访问性链路完成。Apple 官方文档可确认 `CGEvent` 可以创建键盘事件，`AXIsProcessTrusted()` / `AXIsProcessTrustedWithOptions(_:)` 可检测当前进程是否为受信任辅助功能客户端，因此 Phase 3 的推荐方案必须把“写回剪贴板”与“尝试触发粘贴”拆成两个阶段，并把 Accessibility 未授权视为正常降级路径，而不是失败崩溃路径。

右键菜单方面，SwiftUI 官方 `contextMenu(menuItems:)` 已覆盖 macOS，且当前卡片是独立 `View`，非常适合先走 `ClipboardCardView` 上直接挂 `contextMenu` 的轻量方案；只有当需要更细粒度事件路由或与 `NSMenu`/`NSEvent` 深度绑定时，才退回 AppKit `NSView.menu(for:)` 或 `NSMenu.popUpContextMenu(_:with:for:)`。规划上应默认使用 SwiftUI `contextMenu`，批量操作则不要引入复杂模式切换，优先以 `selectedIDs` + 菜单/快捷键衍生入口实现最小多选能力。

**Primary recommendation:** 以“写回剪贴板成功 + 若已获 Accessibility 权限则发送 Command+V，否则退化为仅复制并提示”为主动作方案；右键菜单先用 SwiftUI `contextMenu`；收藏/删除后在 `ClipboardViewModel` 内做原地列表补丁和选中迁移；批量操作仅做轻量多选管理型操作。

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FR-2.3 | 支持收藏/置顶功能 | 明确本阶段只实现“收藏轻量标记、混排不置顶”，使用 `DatabaseService.toggleFavorite` + ViewModel 原地更新即可 |
| FR-3.5 | 点击卡片复制/粘贴 | 明确主动作链路：`ClipboardViewModel` 统一点击/Enter → `ClipboardService` 写回 → `WindowService` 隐藏 → 可访问性允许时发送 Command+V |
| ROADMAP-3.1 | 点击卡片粘贴到当前应用 | 明确需拆为“写回剪贴板”和“尝试粘贴”两步，并处理 Accessibility 缺失时降级 |
| ROADMAP-3.2 | 右键菜单（删除、收藏、复制） | 推荐 `ClipboardCardView.contextMenu` 承载，保持右键不触发主动作 |
| ROADMAP-3.3 | 收藏/取消收藏功能 | 明确使用数据库持久化 + 当前数组就地更新，避免整表重载造成选中跳动 |
| ROADMAP-3.4 | 删除历史项功能 | 明确删除后选中迁移规则：优先保留原 index；若越界则回退到前一项；空列表则设为 -1 |
| ROADMAP-3.5 | 批量操作支持 | 明确轻量落点：在现有 `selectedIndex` 基础上扩展 `selectedIDs`，仅支持批量收藏/删除，不做批量粘贴主流 |
</phase_requirements>

## Standard Stack

### Core
| Library / Framework | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | 平台内建（macOS 13+） | 卡片、列表、上下文菜单、选择态驱动 | 当前项目 UI 已基于 SwiftUI，`contextMenu(menuItems:)` 官方支持 macOS |
| AppKit | 平台内建（macOS 13+） | `NSPasteboard`、`NSPanel`、`NSMenu`、前台应用/窗口控制 | 剪贴板、窗口和焦点管理必须依赖 AppKit |
| CoreGraphics | 平台内建（macOS 13+） | `CGEvent` 键盘事件注入 | 官方标准方式，用于“尝试粘贴”阶段 |
| Application Services | 平台内建（macOS 13+） | `AXIsProcessTrusted()` / `AXIsProcessTrustedWithOptions(_:)` 权限检测 | 自动粘贴前必须检测辅助功能授权 |
| GRDB.swift | 6.29.3（当前锁定） / 7.10.0（最新发布，2026-02-15） | SQLite 持久化、收藏/删除/查询 | 项目已集成，现有数据层已基于 GRDB 实现 |

### Supporting
| Library / Framework | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| KeyboardShortcuts | 2.4.0（当前锁定，最新发布 2025-09-18） | 全局快捷键唤起窗口 | 与本阶段主动作无直接耦合，但批量模式和主窗口回流仍受快捷键流程影响 |
| NotificationCenter | 平台内建 | 发布 `clipboardItemsDidChange` 等变更通知 | 仅用于服务层广播新增/外部变化，不应用作全部交互刷新主路径 |
| NSMenu | 平台内建 | AppKit 级上下文菜单桥接 | 只有 SwiftUI `contextMenu` 不足以表达复杂行为时再启用 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftUI `contextMenu` | AppKit `NSMenu` / `NSView.menu(for:)` | AppKit 更强但接入更重；当前卡片是独立 View，先用 SwiftUI 更轻 |
| `CGEvent` 发送 Command+V | 只写回剪贴板不自动粘贴 | 更稳但不满足锁定决策“立即尝试粘贴” |
| 原地数组补丁刷新 | 每次操作后 `loadItems()` 全量重载 | 实现更简单，但会导致选中跳变、滚动位置抖动、批量操作体验变差 |
| 扩展现有选择模型 | 引入完整编辑模式/工具栏/多段状态机 | 功能更全，但超出本阶段“轻量批量”的边界 |

**Installation:**
```bash
# 无需新增依赖，沿用现有 SwiftUI/AppKit/GRDB/KeyboardShortcuts
```

**Version verification:**
- `Package.resolved` 当前锁定：GRDB.swift 6.29.3，KeyboardShortcuts 2.4.0
- 官方仓库最新发布核验：GRDB.swift v7.10.0（2026-02-15），KeyboardShortcuts 2.4.0（2025-09-18）
- 本阶段不建议顺手升级依赖；规划应基于“当前锁定版本可完成需求”前提推进，升级应单独成项

## Architecture Patterns

### Recommended Project Structure
```text
Z-Paste/
├── App/
│   └── AppDelegate.swift           # 服务装配、窗口显示/隐藏、主动作后的焦点与关闭协调
├── Services/
│   ├── ClipboardService.swift      # 写回系统剪贴板、辅助功能权限检测、尝试粘贴封装
│   ├── DatabaseService.swift       # 收藏/删除/批量操作的持久化 API
│   └── WindowService.swift         # 面板显示/隐藏，避免粘贴前抢焦点
├── ViewModels/
│   └── ClipboardViewModel.swift    # 单项/批量交互编排、原地刷新、选中迁移
└── Views/MainWindow/
    ├── MainWindowView.swift        # 交互回调透传
    ├── CardListView.swift          # Enter/点击/批量入口/滚动同步
    └── ClipboardCardView.swift     # 卡片点击 + contextMenu + 视觉反馈
```

### Pattern 1: 主动作拆成“写回”与“尝试粘贴”两阶段
**What:** 先写入系统剪贴板，再在窗口关闭后尝试向当前前台应用发送粘贴快捷键。
**When to use:** 点击卡片、按 Enter、未来的“再次粘贴”快捷键。
**推荐方案：**
1. `ClipboardViewModel.performPrimaryAction(itemID:)`
2. 调 `ClipboardService.write(item)` 写回 `NSPasteboard.general`
3. 通知 `AppDelegate/WindowService` 关闭面板
4. 在主线程短延迟后，如果 `AXIsProcessTrusted()` 为真，则发送 Command+V；否则返回“仅已复制”结果

**Why:** Apple 文档明确 `NSPasteboard` 负责剪贴板读写，`CGEvent` 负责键盘事件，二者不是一个 API 层；把它们拆开，才容易做可回退设计。

**Example:**
```swift
let pasteboard = NSPasteboard.general
pasteboard.clearContents()
_ = pasteboard.setString(text, forType: .string)
```
Source: https://developer.apple.com/documentation/appkit/nspasteboard/clearcontents()
Source: https://developer.apple.com/documentation/appkit/nspasteboard/setstring(_:fortype:)

### Pattern 2: 对富类型走按类型写入，而不是一把梭纯文本
**What:** 文本用 `setString`，图片/文件/富文本走 `writeObjects(_:)` 或对应 data/type 组合写入。
**When to use:** `ClipboardService` 写回历史项到剪贴板。
**推荐方案：**
- `.text`: `setString(_:forType: .string)`
- `.rtf`: 同时写 `.string` 与 `.rtf` data，优先保留富文本能力
- `.image`: 将 `Data` 复原为 `NSImage` 后 `writeObjects([image])`
- `.file`: 将路径拆成 `[URL]` 后 `writeObjects(urls as [NSPasteboardWriting])`

**Why:** `ClipboardItem` 当前模型对文件仅存 `content` 字符串，对图片/RTF 存 `data`。如果统一只写字符串，会丢失图片、文件拖放和富文本格式。

**Example:**
```swift
let didWrite = pasteboard.writeObjects(objects)
```
Source: https://developer.apple.com/documentation/appkit/nspasteboard/writeobjects(_:)

### Pattern 3: 收藏/删除用 ViewModel 原地补丁，必要时再补全量重载
**What:** 交互后先同步更新 `items` 和 `selectedIndex`，数据库失败才回滚或报错。
**When to use:** 收藏切换、单项删除、批量删除、批量收藏。
**推荐方案：**
- 收藏：更新数据库成功后，直接修改 `items[index].isFavorite`
- 删除：数据库成功后，直接从 `items` 删除该元素，再计算新 `selectedIndex`
- 批量：先计算受影响索引集合，数据库成功后批量更新本地数组

**Why:** 当前 `ClipboardViewModel.loadItems()` 每次都会把 `selectedIndex` 重置为 0。若每次操作都 reload，会破坏继续操作流。

### Pattern 4: 右键菜单先挂在 `ClipboardCardView`，动作回调上抛
**What:** 菜单 UI 在卡片层承载，实际操作回调给 `CardListView` / `ClipboardViewModel`。
**When to use:** 复制、收藏/取消收藏、删除。
**推荐方案：** `ClipboardCardView` 增加 `onCopy` / `onToggleFavorite` / `onDelete` 闭包，并使用 `contextMenu`。
**Why:** Apple 官方文档说明 `contextMenu(menuItems:)` 可直接给任意视图添加上下文菜单，适合当前独立卡片结构。

**Example:**
```swift
SomeView()
    .contextMenu {
        Button("复制") { }
        Button("收藏") { }
        Button("删除") { }
    }
```
Source: https://developer.apple.com/documentation/swiftui/view/contextmenu(menuitems:)

### Pattern 5: 批量操作基于 `selectedIDs` 扩展，而不是推翻 `selectedIndex`
**What:** 保留现有单选主流程，新增一个可选的 `selectedIDs: Set<Int64>` 作为批量模式状态。
**When to use:** 低优先级批量收藏/删除。
**推荐方案：**
- 默认无批量模式：仍然由 `selectedIndex` 驱动单项操作
- 进入轻量批量模式后：卡片显示勾选态，但不改变主卡片布局
- 批量动作只出现在菜单/快捷键，不抢占单击即粘贴主流程

### Anti-Patterns to Avoid
- **把自动粘贴等同于剪贴板写入：** 写剪贴板成功不代表前台应用一定收到粘贴动作。
- **操作后一律 `loadItems()`：** 会让选择跳到第 0 项，破坏连贯交互。
- **右键菜单走 AppDelegate 全局事件分发：** 当前结构下过重，且会放大点击外部关闭逻辑冲突。
- **批量模式默认接管单击：** 会直接与锁定的“单击即主动作”冲突。
- **面板未隐藏就发送 Command+V：** 当前 `WindowService.showWindow()` 会 `NSApp.activate`，面板有机会抢焦点，导致粘贴目标错误。

## Don’t Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 系统剪贴板写回 | 自定义 pasteboard server 协议 | `NSPasteboard` | Apple 官方标准接口已覆盖文本、图片、URL、富文本 |
| 右键菜单承载 | 自绘浮层菜单 | SwiftUI `contextMenu` / AppKit `NSMenu` | 系统菜单有正确的鼠标行为、关闭行为和无障碍支持 |
| 自动粘贴 | 私有 API 或针对单应用脚本 hack | `CGEvent` + Accessibility 授权检测 | 官方公开 API，风险和权限模型清晰 |
| 列表刷新 | 操作后全量重建 ViewModel | ViewModel 原地数组补丁 | 选择迁移和滚动位置更稳定 |
| 批量选择 | 完整编辑模式状态机 | `selectedIDs` 最小扩展 | 本阶段范围有限，避免 UI/状态膨胀 |

**Key insight:** 这个领域最容易“手搓出一个看似能用、实则焦点错乱/权限失败/刷新跳动”的方案。应尽量依赖系统现成机制，把复杂度控制在状态编排，而不是发明新交互层。

## Common Pitfalls

### Pitfall 1: 写回剪贴板后被自己的监听器重新收录
**What goes wrong:** 用户点击历史项后，应用重新写入系统剪贴板，`ClipboardService` 的轮询监听再次把同一内容保存成新记录。
**Why it happens:** 当前 `ClipboardService` 监听 `NSPasteboard.general.changeCount` 并依赖 `lastContentHash` 去重；如果写回的数据表达形式与历史项原始表达稍有不同，仍可能被视作新内容。
**How to avoid:** 规划中应增加“程序化写回抑制窗口”或“下一次 changeCount 忽略标记”，由 `ClipboardService` 在自身发起写回后跳过一次监听。
**Warning signs:** 点击某卡片后，列表顶部马上出现一条相似的新记录。

### Pitfall 2: 面板抢焦点导致粘贴到错误目标
**What goes wrong:** 用户想粘贴到前台应用，但 Command+V 落在 Z-Paste 面板或根本没生效。
**Why it happens:** 当前 `WindowService.showWindow()` 调用 `NSApp.activate(ignoringOtherApps: true)`，而 `FloatingPanel` 可成为 key/main；若关闭与事件发送时机不对，前台焦点尚未回到目标应用。
**How to avoid:** 规划时要求“先 hide，再短延迟发送粘贴事件”，并把失败视为允许降级。必要时由 `AppDelegate` 记录唤起前 frontmost app。
**Warning signs:** 自动粘贴偶发失败，或粘贴到了错误窗口。

### Pitfall 3: 误把 Accessibility 权限当成可选提示，不做显式检查
**What goes wrong:** 自动粘贴在部分机器上无声失败。
**Why it happens:** `CGEvent` 能创建键盘事件不代表系统允许把它们可靠注入到其他应用；自动化链路依赖辅助功能信任。
**How to avoid:** 主动作必须先检测 `AXIsProcessTrusted()`；首次缺权时用 `AXIsProcessTrustedWithOptions(_:)` 触发授权提示或给出明确反馈。
**Warning signs:** 剪贴板写入成功，但前台应用没有任何粘贴结果，且没有错误提示。

### Pitfall 4: 收藏/删除后全量 reload 导致选中跳到最新项
**What goes wrong:** 用户连续管理多项时，每操作一次就回到第一张卡，无法高效批量处理。
**Why it happens:** 当前 `loadItems()` 会把 `selectedIndex` 重置为 0。
**How to avoid:** 规划中要明确“交互型刷新优先原地补丁；仅在外部通知或失配时才全量 reload”。
**Warning signs:** 删除第 8 项后光标回到第 1 项；连续收藏多项时滚动位置频繁跳变。

### Pitfall 5: 右键触发与点击外部关闭监视器冲突
**What goes wrong:** 右键刚弹出菜单，面板就被 `AppDelegate` 的全局/本地鼠标监视器判定为外部点击并隐藏。
**Why it happens:** 当前 `setupClickOutsideHandling()` 同时监听 `.leftMouseDown` 和 `.rightMouseDown`，可见状态下任何右键都有可能触发关闭判断。
**How to avoid:** planner 必须在方案中专门处理“上下文菜单弹出期间禁用外部点击关闭”或“对 panel/frame 内右键事件放行”。
**Warning signs:** 右键菜单闪一下就消失，或根本无法稳定出现。

### Pitfall 6: 文件项 current model 不是数组，回写时容易丢多文件语义
**What goes wrong:** 多文件复制历史被当成单一字符串路径写回，目标应用无法识别成文件集合。
**Why it happens:** 现在 `ClipboardItem.content` 对文件类型是换行拼接字符串。
**How to avoid:** 规划中应明确 Phase 3 如仅需“已有范围内尽量恢复”，就按换行拆回 `[URL]`；若发现原始语义不足，应列为开放问题，不要临时重构模型。
**Warning signs:** 文件卡片可复制文本路径，但在 Finder/编辑器中无法当文件粘贴。

## Code Examples

Verified patterns from official sources:

### 清空并写入通用剪贴板
```swift
let pasteboard = NSPasteboard.general
pasteboard.clearContents()
_ = pasteboard.setString(text, forType: .string)
```
Source: https://developer.apple.com/documentation/appkit/nspasteboard/clearcontents()
Source: https://developer.apple.com/documentation/appkit/nspasteboard/setstring(_:fortype:)

### 用对象写入图片、URL 等多类型内容
```swift
let pasteboard = NSPasteboard.general
pasteboard.clearContents()
let ok = pasteboard.writeObjects(objects)
```
Source: https://developer.apple.com/documentation/appkit/nspasteboard/writeobjects(_:)

### 给 SwiftUI 视图添加 macOS 右键菜单
```swift
ClipboardCardView(item: item)
    .contextMenu {
        Button("复制") { }
        Button(item.isFavorite ? "取消收藏" : "收藏") { }
        Button("删除") { }
    }
```
Source: https://developer.apple.com/documentation/swiftui/view/contextmenu(menuitems:)

### 发送键盘事件需要组合修饰键与目标键
```swift
let commandDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x37, keyDown: true)
let vDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true)
let vUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false)
let commandUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x37, keyDown: false)
```
Source: https://developer.apple.com/documentation/coregraphics/cgevent/init(keyboardeventsource:virtualkey:keydown:)

## Recommended Implementation Plan Inputs

### 推荐方案
1. **主动作链路**：`ClipboardViewModel` 新增统一主动作方法，供 `CardListView` 的点击与 Enter 共用。
2. **剪贴板写回**：在 `ClipboardService` 内新增按 `ItemType` 分支的写回 API，并加入“一次性忽略自身写回”的监听抑制机制。
3. **自动粘贴**：由 `AppDelegate` 或 `WindowService` 协调隐藏面板后再尝试发送 Command+V；未获 Accessibility 权限时退化为“仅复制成功”。
4. **右键菜单**：先在 `ClipboardCardView` 上用 SwiftUI `contextMenu`；菜单动作由闭包上抛给 `CardListView`/`ClipboardViewModel`。
5. **即时刷新**：收藏/删除后优先在 `ClipboardViewModel.items` 做原地补丁，避免 `loadItems()` 重置选择。
6. **选中迁移**：删除后优先保持原 index 指向后继元素；若删除的是末尾，则回退到前一项；列表空则 `selectedIndex = -1`。
7. **批量操作**：新增 `selectedIDs`，仅在轻量批量模式下启用；只做批量收藏/删除。

### 替代方案
- **替代方案 A：只写回剪贴板，不自动触发粘贴。**
  - 优点：最稳，权限最少。
  - 缺点：不满足锁定决策“立即尝试粘贴”。
- **替代方案 B：右键菜单走 AppKit `NSMenu` 桥接。**
  - 优点：更可控，能与 `NSEvent`/`menu(for:)` 深度联动。
  - 缺点：比 SwiftUI `contextMenu` 重，且对当前代码结构侵入更大。
- **替代方案 C：操作后统一全量 reload。**
  - 优点：简单。
  - 缺点：会破坏选择迁移和连续操作流，不推荐。

### Planner 必须避免的坑
- 不要把“自动粘贴”规划成始终可靠的硬保证，必须有无权限降级路径。
- 不要在主动作里先发 Command+V 再隐藏窗口，顺序应反过来。
- 不要默认每次收藏/删除后 `loadItems()`。
- 不要为批量操作引入全屏编辑模式、顶部工具栏或重排模型。
- 不要忽略 `AppDelegate` 现有点击外部关闭监视器对右键菜单的干扰。
- 不要把图片/文件/RTF 全部降级成纯文本写回，否则会与“所有已支持类型统一主动作”冲突。

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 把剪贴板历史工具做成“仅复制回剪贴板” | 复制回剪贴板后尝试自动粘贴，失败可降级 | 现代 macOS 辅助功能权限/自动化实践稳定后 | 交互更顺，但必须显式处理权限与焦点 |
| 每次数据变化全量刷新列表 | 交互型操作做局部状态补丁 | SwiftUI 列表状态管理成熟后 | 连续操作体验明显更好 |
| 上下文菜单走 AppKit 纯手工桥接 | SwiftUI `contextMenu` 直接承载大部分场景 | SwiftUI macOS 可用性成熟（10.15+） | 代码更轻，适合独立卡片视图 |
| 批量功能做重型编辑模式 | 小型工具优先做轻量多选集合 | 近年桌面工具对最小心智负担更重视 | 更贴合本项目“快速操作”定位 |

**Deprecated/outdated:**
- “点击卡片只做选中、再额外按按钮执行主动作”：不符合已锁定的单击即执行。
- “收藏即置顶”：与 Phase 2 已锁定的混排规则冲突。

## Open Questions

1. **自动粘贴是否需要记录唤起前 frontmost app 并显式回切？**
   - What we know: 当前 `WindowService.showWindow()` 会激活应用，隐藏后可能需要一点时间让焦点回流。
   - What's unclear: 仅靠 hide + 短延迟是否在所有目标应用都足够稳定。
   - Recommendation: 规划里把“必要时记录并验证前台 app 回流”作为 P1 风险缓冲，不要一开始就设计复杂回切流程。

2. **文件类型历史能否完整恢复多文件复制语义？**
   - What we know: 当前模型把文件写成换行字符串，而不是显式 `[URL]`。
   - What's unclear: 现有保存格式是否对所有多文件场景都可逆。
   - Recommendation: Phase 3 先按换行拆 URL 实现可用恢复；若验证发现不足，列入后续模型增强而非本阶段扩 scope。

3. **右键菜单期间点击外部关闭监视器如何最小修复？**
   - What we know: `AppDelegate` 当前同时监听 left/right mouse down。
   - What's unclear: 最小改动是“菜单期间暂时禁用监视器”还是“仅对 panel 内右键放行”更稳。
   - Recommendation: planner 应把这项列为右键菜单 plan 的明确子任务和手测点。

4. **批量模式入口放哪里最不打断主流程？**
   - What we know: 锁定决策要求批量功能低优先级、轻量、不可抢主流程。
   - What's unclear: 最合适入口是右键菜单中的“进入批量选择”、键盘修饰键多选，还是单独一个轻量按钮。
   - Recommendation: 优先选“显式进入/退出批量模式”的小入口，不要把普通单击语义改掉。

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest（Xcode / Swift Package 原生） |
| Config file | none — 依赖 Xcode/SwiftPM 默认测试发现 |
| Quick run command | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/DatabaseServiceTests` |
| Full suite command | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` |

### 当前测试基线
- 已存在：`/Users/longzhao/aicodes/Z-Paste/Tests/Z-PasteTests/DatabaseServiceTests.swift`
- 已存在：`/Users/longzhao/aicodes/Z-Paste/Tests/Z-PasteTests/ClipboardServiceTests.swift`
- 现状评估：数据库测试可复用；`ClipboardServiceTests.swift` 与当前实现明显失配（引用了不存在/不可访问接口），需要在 Wave 0 修正，否则本阶段测试基线不可信。

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FR-3.5 / ROADMAP-3.1 | 点击/Enter 统一触发主动作；写回剪贴板成功；失败可降级 | unit + manual smoke | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/ClipboardViewModelInteractionTests` | ❌ Wave 0 |
| FR-2.3 / ROADMAP-3.3 | 收藏状态即时切换且不改排序模型 | unit | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/ClipboardViewModelInteractionTests/testToggleFavoriteUpdatesItemInPlace` | ❌ Wave 0 |
| ROADMAP-3.4 | 删除后即时刷新并迁移选中项 | unit | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/ClipboardViewModelInteractionTests/testDeleteMovesSelectionToNeighbor` | ❌ Wave 0 |
| ROADMAP-3.2 | 右键菜单提供复制/收藏/删除且不触发主动作 | manual UI smoke | manual-only | ❌ Wave 0 |
| ROADMAP-3.5 | 批量收藏/删除仅在轻量模式下生效 | unit + manual smoke | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/ClipboardViewModelBatchTests` | ❌ Wave 0 |
| NFR-2 / 自动粘贴限制 | 未获 Accessibility 权限时退化为仅复制并提示 | unit + manual-only | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/ClipboardServiceWritebackTests` | ❌ Wave 0 |

### Recommended validation strategy for this phase
1. **单元测试覆盖 ViewModel 状态机。** 这是本阶段最该自动化的部分：收藏、删除、选中迁移、批量选择集合。
2. **服务层单元测试覆盖写回分支。** 重点验证 `ClipboardService` 针对 text / rtf / image / file 的写入分支、以及“忽略自己写回一次”的抑制逻辑。
3. **手工冒烟覆盖系统集成。** 自动粘贴、右键菜单弹出、焦点回流、Accessibility 权限提示都属于高系统耦合行为，必须保留人工验证。
4. **planner 后续生成 VALIDATION.md 时，应把“有权限 / 无权限”拆成两条独立场景。**

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/DatabaseServiceTests`
- **Per wave merge:** `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'`
- **Phase gate:** 全量测试通过 + 手工验证以下场景全部通过后再进入 `/gsd:verify-work`

### Manual validation checklist planners should preserve
- [ ] 点击文本卡片：前台应用收到粘贴；窗口自动关闭
- [ ] 未授予 Accessibility：点击文本卡片后至少完成“复制到剪贴板”，并有明确降级反馈
- [ ] 点击图片/文件/富文本卡片：目标应用尽量收到正确类型，而不是纯文本降级
- [ ] 右键卡片：菜单稳定出现，不会被外部点击关闭逻辑提前关掉
- [ ] 菜单中的复制不会触发自动粘贴
- [ ] 收藏/取消收藏即时更新星标，滚动位置与选中项稳定
- [ ] 删除当前选中项后，选择平滑迁移到相邻项；删除最后一项后进入空状态
- [ ] 轻量批量模式下，单项主流程仍不被破坏

### Wave 0 Gaps
- [ ] `/Users/longzhao/aicodes/Z-Paste/Tests/Z-PasteTests/ClipboardViewModelInteractionTests.swift` — 覆盖 FR-3.5、收藏/删除、选中迁移
- [ ] `/Users/longzhao/aicodes/Z-Paste/Tests/Z-PasteTests/ClipboardViewModelBatchTests.swift` — 覆盖轻量批量选择与批量管理动作
- [ ] `/Users/longzhao/aicodes/Z-Paste/Tests/Z-PasteTests/ClipboardServiceWritebackTests.swift` — 覆盖 text/rtf/image/file 写回与忽略自身写回逻辑
- [ ] 修复或重写 `/Users/longzhao/aicodes/Z-Paste/Tests/Z-PasteTests/ClipboardServiceTests.swift` — 当前与真实接口不匹配，不能作为可信基线
- [ ] 为 `ClipboardService` / `AppDelegate` 引入可注入依赖边界（如 pasteboard writer / accessibility checker / event sender 协议）以便测试

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — `NSPasteboard` overview and writing model: https://developer.apple.com/documentation/appkit/nspasteboard
- Apple Developer Documentation — `NSPasteboard.clearContents()`: https://developer.apple.com/documentation/appkit/nspasteboard/clearcontents()
- Apple Developer Documentation — `NSPasteboard.writeObjects(_:)`: https://developer.apple.com/documentation/appkit/nspasteboard/writeobjects(_:)
- Apple Developer Documentation — `NSPasteboard.setString(_:forType:)`: https://developer.apple.com/documentation/appkit/nspasteboard/setstring(_:fortype:)
- Apple Developer Documentation — SwiftUI `contextMenu(menuItems:)`: https://developer.apple.com/documentation/swiftui/view/contextmenu(menuitems:)
- Apple Developer Documentation — `NSView.menu(for:)`: https://developer.apple.com/documentation/appkit/nsview/menu(for:)
- Apple Developer Documentation — `NSMenu.popUpContextMenu(_:with:for:)`: https://developer.apple.com/documentation/appkit/nsmenu/popUpContextMenu(_:with:for:)
- Apple Developer Documentation — `AXIsProcessTrusted()`: https://developer.apple.com/documentation/applicationservices/1460720-axisprocesstrusted
- Apple Developer Documentation — `AXIsProcessTrustedWithOptions(_:)`: https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions
- Apple Developer Documentation — `CGEvent.init(keyboardEventSource:virtualKey:keyDown:)`: https://developer.apple.com/documentation/coregraphics/cgevent/init(keyboardeventsource:virtualkey:keydown:)
- Project code read on 2026-03-18:
  - `/Users/longzhao/aicodes/Z-Paste/Z-Paste/ViewModels/ClipboardViewModel.swift`
  - `/Users/longzhao/aicodes/Z-Paste/Z-Paste/Views/MainWindow/CardListView.swift`
  - `/Users/longzhao/aicodes/Z-Paste/Z-Paste/Views/MainWindow/ClipboardCardView.swift`
  - `/Users/longzhao/aicodes/Z-Paste/Z-Paste/Services/ClipboardService.swift`
  - `/Users/longzhao/aicodes/Z-Paste/Z-Paste/Services/DatabaseService.swift`
  - `/Users/longzhao/aicodes/Z-Paste/Z-Paste/Services/WindowService.swift`
  - `/Users/longzhao/aicodes/Z-Paste/Z-Paste/App/AppDelegate.swift`
  - `/Users/longzhao/aicodes/Z-Paste/Z-Paste/Views/MainWindow/MainWindowView.swift`

### Secondary (MEDIUM confidence)
- GitHub latest release — GRDB.swift v7.10.0 published 2026-02-15: https://github.com/groue/GRDB.swift/releases/latest
- GitHub latest release — KeyboardShortcuts 2.4.0 published 2025-09-18: https://github.com/sindresorhus/KeyboardShortcuts/releases/latest

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - 主要基于项目现有依赖与 Apple 官方 API 文档，可直接核验
- Architecture: MEDIUM - 基于现有代码结构和官方能力推导，仍需在真实 macOS 焦点/权限场景下验证
- Pitfalls: MEDIUM - 多数来自现有代码入口分析与 Apple 平台行为约束，系统级焦点问题仍需手测确认

**Research date:** 2026-03-18
**Valid until:** 2026-04-17
