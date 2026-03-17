---
phase: 01-project-foundation
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - Z-Paste.xcodeproj
  - Z-Paste/App/Z_PasteApp.swift
  - Z-Paste/App/AppDelegate.swift
  - Z-Paste/Info.plist
  - Package.swift
autonomous: true
requirements:
  - "1.1: 创建 Xcode 项目和基础目录结构"
must_haves:
  truths:
    - "Xcode 项目能成功编译"
    - "目录结构符合 MVVM 组织"
    - "SPM 依赖可正确解析"
  artifacts:
    - path: "Z-Paste.xcodeproj"
      provides: "Xcode 项目配置"
      contains: "Z-Paste scheme"
    - path: "Z-Paste/App/Z_PasteApp.swift"
      provides: "应用入口"
      contains: "@main"
    - path: "Package.swift"
      provides: "SPM 依赖配置"
      contains: "GRDB, KeyboardShortcuts"
  key_links:
    - from: "Z_PasteApp.swift"
      to: "AppDelegate.swift"
      via: "@NSApplicationDelegateAdaptor"
      pattern: "@NSApplicationDelegateAdaptor.*AppDelegate"
---

<objective>
创建 Xcode 项目结构和 SPM 依赖配置

Purpose: 建立 macOS 应用的基础工程框架，配置必要的权限和依赖
Output: 可编译的 Xcode 项目，包含目录结构和 SPM 依赖
</objective>

<execution_context>
@/Users/longzhao/.claude/get-shit-done/workflows/execute-plan.md
@/Users/longzhao/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/REQUIREMENTS.md
@.planning/ROADMAP.md
@.planning/phases/01-project-foundation/01-CONTEXT.md
@.planning/phases/01-project-foundation/01-RESEARCH.md
</context>

<interfaces>
<!-- 本计划创建的基础结构，后续计划会使用 -->
<!-- 无类型定义，仅有目录结构 -->
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: 创建目录结构</name>
  <files>Z-Paste/App/, Z-Paste/Models/, Z-Paste/Services/, Z-Paste/ViewModels/, Z-Paste/Views/, Z-Paste/Resources/</files>
  <read_first>
    - .planning/phases/01-project-foundation/01-CONTEXT.md (目录结构定义)
    - .planning/phases/01-project-foundation/01-RESEARCH.md (项目结构建议)
  </read_first>
  <action>
    在 Z-Paste/ 目录下创建以下目录：
    - App/ — 应用入口和代理
    - Models/ — 数据模型
    - Services/ — 业务服务
    - ViewModels/ — MVVM 视图模型
    - Views/ — SwiftUI 视图
    - Resources/ — 资源和 Assets.xcassets

    每个目录创建空的 .gitkeep 文件保持目录跟踪。
  </action>
  <verify>
    <automated>ls -d Z-Paste/*/ 2>/dev/null | wc -l | grep -q "6" && echo "OK: 6 directories created"</automated>
  </verify>
  <done>6 个目录创建完成，每个包含 .gitkeep</done>
</task>

<task type="auto">
  <name>Task 2: 创建 Xcode 项目和应用入口</name>
  <files>Z-Paste.xcodeproj, Z-Paste/App/Z_PasteApp.swift, Z-Paste/App/AppDelegate.swift</files>
  <read_first>
    - .planning/REQUIREMENTS.md (NFR-3: macOS 13.0+)
    - .planning/phases/01-project-foundation/01-CONTEXT.md (技术栈决策)
  </read_first>
  <action>
    创建 Xcode 项目配置：
    - Product Name: Z-Paste
    - Bundle Identifier: com.user.zpaste
    - Deployment Target: macOS 13.0
    - Interface: SwiftUI
    - Language: Swift

    创建 Z_PasteApp.swift：
    - @main 入口
    - @NSApplicationDelegateAdaptor 连接 AppDelegate
    - 窗口配置 (隐藏标题栏，自定义外观)

    创建 AppDelegate.swift：
    - NSApplicationDelegate 协议实现
    - 应用启动回调
  </action>
  <verify>
    <automated>xcodebuild -project Z-Paste.xcodeproj -scheme Z-Paste -destination 'platform=macOS' build 2>&1 | grep -q "BUILD SUCCEEDED" || echo "BUILD FAILED - check logs"</automated>
  </verify>
  <done>Xcode 项目可成功编译，无错误</done>
</task>

<task type="auto">
  <name>Task 3: 配置 Info.plist 和 SPM 依赖</name>
  <files>Z-Paste/Info.plist, Package.swift</files>
  <read_first>
    - .planning/phases/01-project-foundation/01-RESEARCH.md (权限要求和依赖库)
    - .planning/REQUIREMENTS.md (NFR-2: 隐私要求)
  </read_first>
  <action>
    配置 Info.plist：
    - NSAccessibilityUsageDescription: "Z-Paste 需要辅助功能权限以监听全局快捷键"
    - 应用类别配置

    创建 Package.swift 添加 SPM 依赖：
    - GRDB.swift (数据库)
    - KeyboardShortcuts (全局快捷键)

    在 Xcode 项目中添加 SPM 包依赖引用。
  </action>
  <verify>
    <automated>grep -q "NSAccessibilityUsageDescription" Z-Paste/Info.plist && grep -q "GRDB" Package.swift && grep -q "KeyboardShortcuts" Package.swift && echo "OK: Info.plist and Package.swift configured"</automated>
  </verify>
  <done>Info.plist 包含辅助功能权限说明，Package.swift 包含 GRDB 和 KeyboardShortcuts 依赖</done>
</task>

</tasks>

<verification>
- Xcode 项目可成功编译
- 目录结构符合约定
- SPM 依赖正确配置
- Info.plist 包含必要的权限说明
</verification>

<success_criteria>
- 6 个目录创建完成
- xcodebuild 编译成功
- Info.plist 包含 NSAccessibilityUsageDescription
- Package.swift 包含 GRDB 和 KeyboardShortcuts
</success_criteria>

<output>
After completion, create `.planning/phases/01-project-foundation/01-01-SUMMARY.md`
</output>

---
---
phase: 01-project-foundation
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - Z-Paste/Models/ClipboardItem.swift
  - Z-Paste/Models/ClipboardItem+Database.swift
autonomous: true
requirements:
  - "1.5: 创建数据模型 ClipboardItem"
must_haves:
  truths:
    - "ClipboardItem 可序列化/反序列化"
    - "支持文本/图片/文件/富文本类型"
    - "模型可直接映射到数据库表"
  artifacts:
    - path: "Z-Paste/Models/ClipboardItem.swift"
      provides: "数据模型定义"
      contains: "struct ClipboardItem, enum ItemType"
    - path: "Z-Paste/Models/ClipboardItem+Database.swift"
      provides: "GRDB 协议实现"
      contains: "FetchableRecord, PersistableRecord"
  key_links:
    - from: "ClipboardItem"
      to: "Database table"
      via: "PersistableRecord.insert(db)"
      pattern: "try.*insert\\(db\\)"
---

<objective>
创建 ClipboardItem 数据模型

Purpose: 定义剪贴板记录的数据结构，支持文本/图片/文件/富文本类型
Output: 可持久化的数据模型，符合 GRDB 协议
</objective>

<execution_context>
@/Users/longzhao/.claude/get-shit-done/workflows/execute-plan.md
@/Users/longzhao/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/REQUIREMENTS.md (FR-1: 剪贴板监听，FR-2: 历史管理)
@.planning/phases/01-project-foundation/01-RESEARCH.md (SQLite 存储方案)
</context>

<interfaces>
<!-- 本计划创建的类型，后续计划会引用 -->
```swift
struct ClipboardItem: Codable, Identifiable {
    var id: Int64?
    var content: String
    var itemType: ItemType
    var sourceApp: String?
    var sourceAppIcon: Data?
    var createdAt: Date
    var isFavorite: Bool
    var data: Data?
}

enum ItemType: String, Codable {
    case text, image, file, rtf
}
```
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: 定义 ClipboardItem 模型和类型枚举</name>
  <files>Z-Paste/Models/ClipboardItem.swift</files>
  <read_first>
    - .planning/phases/01-project-foundation/01-RESEARCH.md (GRDB 模型定义示例)
    - .planning/REQUIREMENTS.md (FR-1.2: 支持的数据类型)
  </read_first>
  <action>
    创建 ClipboardItem.swift：

    定义 ItemType 枚举：
    - case text (纯文本)
    - case image (图片)
    - case file (文件)
    - case rtf (富文本)

    定义 ClipboardItem 结构体：
    - id: Int64? (数据库主键)
    - content: String (文本内容或文件路径)
    - itemType: ItemType
    - sourceApp: String? (来源应用 BundleID)
    - sourceAppIcon: Data? (来源应用图标)
    - createdAt: Date
    - isFavorite: Bool
    - data: Data? (二进制数据，如图片)

    遵循的协议：
    - Codable (序列化)
    - Identifiable (SwiftUI 列表)
    - Equatable (去重比较)
    - Hashable (集合操作)

    实现自定义 init(content:itemType:...) 构造器。
    实现自定义 contentHash 计算属性用于去重判断。
  </action>
  <verify>
    <automated>swiftc -typecheck Z-Paste/Models/ClipboardItem.swift -swift-version 5 2>&1 | grep -q "error:" && echo "TYPECHECK FAILED" || echo "OK: No type errors"</automated>
  </verify>
  <done>ClipboardItem 模型定义完成，无编译错误</done>
</task>

<task type="auto">
  <name>Task 2: 扩展 GRDB 协议支持</name>
  <files>Z-Paste/Models/ClipboardItem+Database.swift</files>
  <read_first>
    - .planning/phases/01-project-foundation/01-RESEARCH.md (GRDB FetchableRecord, PersistableRecord)
  </read_first>
  <action>
    创建扩展文件 ClipboardItem+Database.swift：

    扩展 ClipboardItem 遵循：
    - FetchableRecord (从数据库读取)
    - PersistableRecord (写入数据库)
    - TableRecord (表名映射)

    实现 databaseTableName: "clipboard_items"

    实现 columnMapping 如果需要自定义列名映射。

    添加静态方法 dbCreate(db:) 用于创建表结构：
    - id: INTEGER PRIMARY KEY AUTOINCREMENT
    - content: TEXT NOT NULL
    - item_type: TEXT NOT NULL
    - source_app: TEXT
    - source_app_icon: BLOB
    - created_at: DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    - is_favorite: BOOLEAN NOT NULL DEFAULT 0
    - data: BLOB

    添加索引：
    - created_at (时间排序)
    - is_favorite (收藏过滤)
    - content_hash (去重检查)
  </action>
  <verify>
    <automated>grep -q "FetchableRecord" Z-Paste/Models/ClipboardItem+Database.swift && grep -q "PersistableRecord" Z-Paste/Models/ClipboardItem+Database.swift && echo "OK: GRDB protocols implemented"</automated>
  </verify>
  <done>GRDB 协议实现完成，表结构定义完整</done>
</task>

</tasks>

<verification>
- ClipboardItem 模型可编译
- GRDB 协议正确实现
- 表结构包含所有必要字段
</verification>

<success_criteria>
- ClipboardItem.swift 编译无错误
- ItemType 枚举覆盖所有类型
- GRDB FetchableRecord 和 PersistableRecord 已实现
- 表创建方法包含所有字段和索引
</success_criteria>

<output>
After completion, create `.planning/phases/01-project-foundation/01-02-SUMMARY.md`
</output>

---
---
phase: 01-project-foundation
plan: 03
type: execute
wave: 2
depends_on: ["01-01", "01-02"]
files_modified:
  - Z-Paste/Services/ClipboardService.swift
  - Z-Paste/Services/DatabaseService.swift
autonomous: true
requirements:
  - "1.2: 实现 ClipboardService - 剪贴板监听"
  - "1.3: 实现 StorageService - SQLite 存储"
must_haves:
  truths:
    - "剪贴板变化能被检测到"
    - "新记录保存到数据库"
    - "相同内容不重复保存"
  artifacts:
    - path: "Z-Paste/Services/DatabaseService.swift"
      provides: "数据库操作服务"
      exports: ["save", "fetchRecent", "delete", "cleanup"]
    - path: "Z-Paste/Services/ClipboardService.swift"
      provides: "剪贴板监听服务"
      exports: ["startMonitoring", "stopMonitoring", "onNewItem"]
  key_links:
    - from: "ClipboardService.checkClipboard()"
      to: "DatabaseService.save()"
      via: "保存新记录"
      pattern: "try.*database\\.save"
    - from: "ClipboardService"
      to: "NSPasteboard.general"
      via: "读取剪贴板"
      pattern: "NSPasteboard\\.general"
---

<objective>
实现 ClipboardService 和 DatabaseService 核心服务

Purpose: 监听剪贴板变化并持久化记录到 SQLite
Output: 可运行的后台监听服务和数据库服务
</objective>

<execution_context>
@/Users/longzhao/.claude/get-shit-done/workflows/execute-plan.md
@/Users/longzhao/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/REQUIREMENTS.md (FR-1: 剪贴板监听，FR-2: 历史管理)
@.planning/phases/01-project-foundation/01-RESEARCH.md (NSPasteboard API, GRDB 使用)
</context>

<interfaces>
<!-- 本计划创建的服务，后续计划会引用 -->
```swift
class DatabaseService {
    func save(_ item: ClipboardItem) throws
    func fetchRecent(limit: Int) throws -> [ClipboardItem]
    func delete(_ item: ClipboardItem) throws
    func cleanup(limit: Int) throws
}

class ClipboardService {
    func startMonitoring()
    func stopMonitoring()
    var onNewItem: ((ClipboardItem) -> Void)?
}
```
</interfaces>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: 实现 DatabaseService</name>
  <files>Z-Paste/Services/DatabaseService.swift, Z-Paste/Services/DatabaseService+Tests.swift</files>
  <read_first>
    - .planning/phases/01-project-foundation/01-RESEARCH.md (GRDB API 参考)
    - Z-Paste/Models/ClipboardItem.swift
    - Z-Paste/Models/ClipboardItem+Database.swift
  </read_first>
  <behavior>
    - Test 1: 创建数据库后，表 clipboard_items 存在
    - Test 2: save(item) 后，fetchRecent 能返回该记录
    - Test 3: delete(item) 后，记录不存在
    - Test 4: cleanup(limit: 1000) 保留最近 1000 条，删除更旧的
    - Test 5: 并发写入不崩溃
  </behavior>
  <action>
    创建 DatabaseService.swift：

    属性：
    - dbQueue: DatabaseQueue (懒加载初始化)

    方法：
    - init(databasePath: String) - 初始化数据库路径
    - createTables() - 创建表结构
    - save(_ item: ClipboardItem) throws - 插入记录
    - fetchRecent(limit: Int) throws -> [ClipboardItem] - 按时间倒序获取
    - delete(_ item: ClipboardItem) throws - 删除记录
    - delete(id: Int64) throws - 按 ID 删除
    - cleanup(limit: Int) throws - 清理超出限制的记录（排除收藏项）
    - search(query: String) throws -> [ClipboardItem] - 文本搜索

    实现细节：
    - 使用 dbQueue.write 进行写操作
    - 使用 dbQueue.read 进行读操作
    - 在初始化时自动创建表
    - cleanup 时保留 is_favorite=true 的记录
  </action>
  <verify>
    <automated>swift test --filter DatabaseService 2>&1 | grep -q "passed" && echo "OK: Tests passed" || echo "TESTS FAILED"</automated>
  </verify>
  <done>DatabaseService 实现并通过所有单元测试</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: 实现 ClipboardService</name>
  <files>Z-Paste/Services/ClipboardService.swift, Z-Paste/Services/ClipboardService+Tests.swift</files>
  <read_first>
    - .planning/phases/01-project-foundation/01-RESEARCH.md (NSPasteboard API)
    - Z-Paste/Models/ClipboardItem.swift
    - Z-Paste/Services/DatabaseService.swift
  </read_first>
  <behavior>
    - Test 1: startMonitoring 后，剪贴板变化会触发回调
    - Test 2: 相同内容不重复触发 (去重)
    - Test 3: 文本内容正确提取
    - Test 4: 图片内容正确提取
    - Test 5: 来源应用 BundleID 正确获取
    - Test 6: stopMonitoring 后不再触发
  </behavior>
  <action>
    创建 ClipboardService.swift：

    属性：
    - private var isMonitoring: Bool
    - private var lastContentHash: String?
    - private let database: DatabaseService
    - public var onNewItem: ((ClipboardItem) -> Void)?

    方法：
    - init(database: DatabaseService)
    - startMonitoring() - 开始监听
    - stopMonitoring() - 停止监听
    - private func checkClipboard() - 检查剪贴板变化
    - private func extractContent() -> ClipboardItem? - 提取内容

    实现细节：
    - 使用 Timer 每 0.5 秒轮询
    - 监听 NSPasteboard.changedNotification
    - 通过 contentHash 去重
    - 根据 pasteboard.types 判断内容类型
    - 获取 frontmostApplication 作为来源
    - 捕获后保存到数据库
  </action>
  <verify>
    <automated>swift test --filter ClipboardService 2>&1 | grep -q "passed" && echo "OK: Tests passed" || echo "TESTS FAILED"</automated>
  </verify>
  <done>ClipboardService 实现并通过所有单元测试</done>
</task>

</tasks>

<verification>
- DatabaseService 可独立测试
- ClipboardService 能检测剪贴板变化
- 去重逻辑正常工作
- 数据库持久化正常
</verification>

<success_criteria>
- DatabaseService 单元测试全部通过
- ClipboardService 单元测试全部通过
- 剪贴板变化能在 0.5 秒内检测到
- 相同内容不重复保存
</success_criteria>

<output>
After completion, create `.planning/phases/01-project-foundation/01-03-SUMMARY.md`
</output>

---
---
phase: 01-project-foundation
plan: 04
type: execute
wave: 2
depends_on: ["01-01", "01-02"]
files_modified:
  - Z-Paste/Services/HotkeyService.swift
  - Z-Paste/App/AppDelegate.swift
autonomous: true
requirements:
  - "1.4: 实现 HotkeyService - 全局快捷键"
must_haves:
  truths:
    - "默认快捷键 Option + ` 可注册"
    - "按下快捷键触发回调"
    - "回调可绑定到窗口切换"
  artifacts:
    - path: "Z-Paste/Services/HotkeyService.swift"
      provides: "快捷键服务"
      exports: ["register", "onToggleWindow"]
    - path: "Z-Paste/App/AppDelegate.swift"
      provides: "快捷键集成"
      contains: "hotkeyService.register()"
  key_links:
    - from: "KeyboardShortcuts.onKeyDown"
      to: "onToggleWindow callback"
      via: "快捷键按下事件"
      pattern: "onKeyDown.*onToggleWindow"
---

<objective>
实现 HotkeyService 全局快捷键服务

Purpose: 使用 KeyboardShortcuts 库注册全局快捷键用于唤起窗口
Output: 可注册和响应全局快捷键的服务
</objective>

<execution_context>
@/Users/longzhao/.claude/get-shit-done/workflows/execute-plan.md
@/Users/longzhao/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/REQUIREMENTS.md (FR-5: 快捷键)
@.planning/phases/01-project-foundation/01-RESEARCH.md (KeyboardShortcuts API)
</context>

<interfaces>
<!-- 本计划创建的服务，后续计划会引用 -->
```swift
class HotkeyService {
    var onToggleWindow: (() -> Void)?
    func register()
    func unregister()
}
```
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: 实现 HotkeyService</name>
  <files>Z-Paste/Services/HotkeyService.swift</files>
  <read_first>
    - .planning/phases/01-project-foundation/01-RESEARCH.md (KeyboardShortcuts 使用示例)
    - .planning/REQUIREMENTS.md (FR-5.1: 默认 Option + `)
  </read_first>
  <action>
    创建 HotkeyService.swift：

    属性：
    - public var onToggleWindow: (() -> Void)?

    方法：
    - init() - 注册快捷键回调
    - func register() - 注册快捷键
    - func unregister() - 注销快捷键

    实现细节：
    - 使用 KeyboardShortcuts.Name 定义快捷键名称
    - 默认快捷键：Option + `
    - 使用 KeyboardShortcuts.onKeyDown 监听按下事件
    - 回调触发 onToggleWindow 闭包

    注意：
    - 需要在 Info.plist 中添加辅助功能权限
    - 快捷键注册在应用启动时进行
  </action>
  <verify>
    <automated>grep -q "KeyboardShortcuts" Z-Paste/Services/HotkeyService.swift && grep -q "onKeyDown" Z-Paste/Services/HotkeyService.swift && echo "OK: HotkeyService uses KeyboardShortcuts"</automated>
  </verify>
  <done>HotkeyService 使用 KeyboardShortcuts 实现，默认快捷键 Option + `</done>
</task>

<task type="auto">
  <name>Task 2: 集成 HotkeyService 到应用入口</name>
  <files>Z-Paste/App/Z_PasteApp.swift, Z-Paste/App/AppDelegate.swift</files>
  <read_first>
    - Z-Paste/App/Z_PasteApp.swift
    - Z-Paste/Services/HotkeyService.swift
  </read_first>
  <action>
    修改 AppDelegate.swift：

    添加属性：
    - private let hotkeyService = HotkeyService()

    在 applicationDidFinishLaunching 中：
    - hotkeyService.register()
    - hotkeyService.onToggleWindow = { [weak self] in self?.toggleWindow() }

    实现 toggleWindow() 方法（暂时打印日志）。

    修改 Z_PasteApp.swift：
    - 确保窗口初始状态为隐藏或显示
  </action>
  <verify>
    <automated>grep -q "hotkeyService" Z-Paste/App/AppDelegate.swift && xcodebuild -project Z-Paste.xcodeproj -scheme Z-Paste build 2>&1 | grep -q "BUILD SUCCEEDED" && echo "OK: Integration successful"</automated>
  </verify>
  <done>HotkeyService 集成到应用入口，快捷键注册并绑定回调</done>
</task>

</tasks>

<verification>
- 快捷键注册成功
- 按下快捷键触发回调
- 回调可正确绑定到窗口切换逻辑
</verification>

<success_criteria>
- HotkeyService 编译无错误
- KeyboardShortcuts 正确集成
- 快捷键回调能触发
- 应用可编译
</success_criteria>

<output>
After completion, create `.planning/phases/01-project-foundation/01-04-SUMMARY.md`
</output>

---
---
phase: 01-project-foundation
plan: 05
type: execute
wave: 3
depends_on: ["01-03"]
files_modified:
  - Z-Paste/Services/ClipboardService.swift
  - Z-Paste/Services/ExclusionService.swift
autonomous: true
requirements:
  - "1.6: 实现应用排除逻辑"
must_haves:
  truths:
    - "密码管理器的内容不会被记录"
    - "排除列表可配置"
    - "配置持久化"
  artifacts:
    - path: "Z-Paste/Services/ExclusionService.swift"
      provides: "排除服务"
      exports: ["isExcluded", "add", "remove"]
    - path: "Z-Paste/Services/ClipboardService.swift"
      provides: "集成排除逻辑"
      contains: "exclusionService.isExcluded()"
  key_links:
    - from: "ClipboardService.checkClipboard()"
      to: "ExclusionService.isExcluded()"
      via: "排除检查"
      pattern: "exclusionService\\.isExcluded\\(\\)"
---

<objective>
实现应用排除逻辑

Purpose: 允许用户配置排除应用列表，这些应用中的剪贴板内容不会被记录
Output: 可配置和检查的排除服务
</objective>

<execution_context>
@/Users/longzhao/.claude/get-shit-done/workflows/execute-plan.md
@/Users/longzhao/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/REQUIREMENTS.md (FR-1.3: 可配置排除应用列表)
@.planning/phases/01-project-foundation/01-RESEARCH.md (获取前台应用 API)
</context>

<interfaces>
<!-- 本计划创建的服务，后续计划会引用 -->
```swift
class ExclusionService {
    var excludedApps: Set<String>
    func isExcluded() -> Bool
    func add(bundleID: String)
    func remove(bundleID: String)
}
```
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: 实现 ExclusionService</name>
  <files>Z-Paste/Services/ExclusionService.swift</files>
  <read_first>
    - .planning/phases/01-project-foundation/01-RESEARCH.md (获取前台应用 API)
    - .planning/REQUIREMENTS.md (FR-1.3: 排除应用)
  </read_first>
  <action>
    创建 ExclusionService.swift：

    属性：
    - private let defaults = UserDefaults.standard
    - private let exclusionKey = "excludedApps"
    - public var excludedApps: Set<String> (计算属性，读写 UserDefaults)

    方法：
    - init() - 初始化默认排除列表
    - func isExcluded() -> Bool - 检查当前应用是否被排除
    - func add(bundleID: String) - 添加排除应用
    - func remove(bundleID: String) - 移除排除应用
    - func getCurrentAppBundleID() -> String? - 获取当前前台应用

    默认排除的应用：
    - com.apple.finder (Finder)
    - com.1password.1password (1Password)
    - com.apple.keychain (Keychain 访问)

    实现细节：
    - 使用 NSWorkspace.shared.frontmostApplication 获取前台应用
    - 使用 UserDefaults 持久化配置
  </action>
  <verify>
    <automated>grep -q "frontmostApplication" Z-Paste/Services/ExclusionService.swift && grep -q "excludedApps" Z-Paste/Services/ExclusionService.swift && echo "OK: ExclusionService implemented"</automated>
  </verify>
  <done>ExclusionService 实现完成，可检查和配置排除应用</done>
</task>

<task type="auto">
  <name>Task 2: 集成 ExclusionService 到 ClipboardService</name>
  <files>Z-Paste/Services/ClipboardService.swift</files>
  <read_first>
    - Z-Paste/Services/ClipboardService.swift
    - Z-Paste/Services/ExclusionService.swift
  </read_first>
  <action>
    修改 ClipboardService.swift：

    添加属性：
    - private let exclusionService = ExclusionService()

    在 checkClipboard() 方法中：
    - 首先调用 exclusionService.isExcluded()
    - 如果返回 true，直接返回不记录
    - 否则继续正常的剪贴板处理流程

    添加日志：
    - 当检测到排除应用时，打印 "Skipping clipboard from excluded app: {bundleID}"
  </action>
  <verify>
    <automated>grep -q "exclusionService" Z-Paste/Services/ClipboardService.swift && grep -q "isExcluded" Z-Paste/Services/ClipboardService.swift && echo "OK: ExclusionService integrated"</automated>
  </verify>
  <done>ExclusionService 集成到 ClipboardService，排除应用的剪贴板内容不会被记录</done>
</task>

</tasks>

<verification>
- 默认排除应用配置正确
- 排除检查在剪贴板处理前进行
- 排除应用的剪贴板不会被保存
</verification>

<success_criteria>
- ExclusionService 实现完成
- 默认排除 1Password 和 Keychain 应用
- ClipboardService 在排除应用中不捕获剪贴板
- 配置持久化到 UserDefaults
</success_criteria>

<output>
After completion, create `.planning/phases/01-project-foundation/01-05-SUMMARY.md`
</output>
