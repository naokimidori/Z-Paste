# Phase 1: 项目基础架构 - 研究报告

**研究时间:** 2026-03-17
**研究员:** gsd-phase-researcher

---

## 1. macOS 剪贴板 API

### NSPasteboard 核心 API

```swift
import AppKit

// 获取通用剪贴板
let pasteboard = NSPasteboard.general

// 读取内容
let string = pasteboard.string(forType: .string)
let image = pasteboard.data(forType: .png)
let types = pasteboard.types  // 可用的数据类型

// 写入内容
pasteboard.clearContents()
pasteboard.setString("Hello", forType: .string)

// 监听剪贴板变化
NotificationCenter.default.addObserver(
    self,
    selector: #selector(clipboardChanged),
    name: NSPasteboard.changedNotification,
    object: nil
)
```

### 关键发现

1. **NSPasteboard.general** 是系统级单例，所有应用共享
2. **changedNotification** 可用于后台监听
3. **支持的数据类型**:
   - `.string` - 纯文本
   - `.rtf` / `.rtfd` - 富文本
   - `.png` / `.tiff` - 图片
   - `.fileURL` - 文件路径
   - 自定义 UTI 类型

### 最佳实践

- 在后台使用 timer 轮询 + notification 双重检测
- 读取前检查 `types` 避免类型错误
- 大图片数据需要异步处理

**来源:** Apple Developer Documentation - NSPasteboard

---

## 2. SQLite 存储方案

### 推荐库：GRDB.swift

```swift
import GRDB

// 数据库配置
let dbQueue = try DatabaseQueue(path: dbPath)

// 定义记录模型
struct ClipboardItem: FetchableRecord, PersistableRecord, Codable {
    var id: Int64?
    var content: String
    var itemType: String  // text, image, file, rtf
    var sourceApp: String?
    var createdAt: Date
    var isFavorite: Bool
}

// 创建表
try dbQueue.write { db in
    try db.create(table: "clipboard_items") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("content", .text).notNull()
        t.column("item_type", .text).notNull()
        t.column("source_app", .text)
        t.column("created_at", .datetime).notNull()
        t.column("is_favorite", .boolean).defaults(to: false)
        t.column("data", .blob)  // 存储图片等二进制数据
    }
    t.index(on: ["created_at"])
    t.index(on: ["is_favorite"])
}

// CRUD 操作
try dbQueue.write { db in
    try item.insert(db)
    try item.update(db)
    try item.delete(db)
}
```

### 替代方案对比

| 方案 | 优点 | 缺点 |
|------|------|------|
| **GRDB.swift** | 高性能、类型安全、活跃维护 | 需要学习 SQL |
| CoreData | Apple 原生、图形化工具 | 较重、性能一般 |
| Realm | 简单易用 | 包体积大 |
| UserDefaults | 简单 | 仅适合小数据量 |

**推荐：GRDB.swift** - 轻量、高性能、适合剪贴板历史场景

**来源:** GRDB.swift GitHub Repository

---

## 3. 全局快捷键实现

### 方案一：MASLocalShortcut (推荐)

```swift
import Magnet

// 注册全局快捷键
HotKeyCenter.shared.register(with: "PasteToggle") {
    toggleMainWindow()
}

// 在 Info.plist 配置快捷键
// 或使用系统偏好设置
```

### 方案二：KeyboardShortcuts (最流行)

```swift
import KeyboardShortcuts

// 注册快捷键
KeyboardShortcuts.onKeyDown(for: .togglePaste) {
    toggleMainWindow()
}

// 定义快捷键
extension KeyboardShortcuts.Name {
    static let togglePaste = Self("togglePaste")
}

// 在设置界面使用内置组件
KeyboardShortcuts.Recorder("快捷键:", name: .togglePaste)
```

### 方案三：系统级别 (需要辅助功能权限)

```swift
// 需要 Info.plist 添加：
// NSAccessibilityUsageDescription
```

**推荐：KeyboardShortcuts** - 简洁 API、内置设置界面组件、活跃维护

**来源:** KeyboardShortcuts GitHub (mxcl)

---

## 4. 应用排除机制

### 获取前台应用

```swift
import AppKit

// 获取当前激活的应用
if let app = NSWorkspace.shared.frontmostApplication {
    let bundleID = app.bundleIdentifier
    let appName = app.localizedName
}

// 监听应用切换
NotificationCenter.default.addObserver(
    self,
    selector: #selector(appChanged),
    name: NSWorkspace.didActivateApplicationNotification,
    object: nil
)
```

### 排除逻辑实现

```swift
class ClipboardMonitor {
    var excludedApps: Set<String> = ["com.apple.finder", "com.1password.1password"]

    func shouldCapture() -> Bool {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return true
        }
        return !excludedApps.contains(bundleID)
    }
}
```

---

## 5. 来源应用图标获取

```swift
func getAppIcon(for bundleID: String) -> NSImage? {
    guard let appURL = NSWorkspace.shared.urlForApplication(
        withBundleIdentifier: bundleID
    ) else { return nil }

    let bundle = Bundle(url: appURL)
    // 方法 1: 使用应用图标
    return NSWorkspace.shared.icon(forFile: appURL.path)
}
```

---

## 6. 项目结构建议

```
Z-Paste/
├── Z-Paste.xcodeproj
├── Z-Paste/
│   ├── App/
│   │   ├── Z_PasteApp.swift
│   │   └── AppDelegate.swift
│   ├── Models/
│   │   └── ClipboardItem.swift
│   ├── Services/
│   │   ├── ClipboardService.swift
│   │   ├── DatabaseService.swift
│   │   └── HotkeyService.swift
│   ├── ViewModels/
│   │   └── ClipboardViewModel.swift
│   ├── Views/
│   │   ├── MainWindow.swift
│   │   └── SettingsView.swift
│   └── Resources/
│       └── Assets.xcassets
├── Package.swift
└── .planning/
```

---

## 7. 依赖项汇总

| 依赖 | 用途 | 安装方式 |
|------|------|----------|
| GRDB.swift | SQLite 数据库 | SPM |
| KeyboardShortcuts | 全局快捷键 | SPM |
| SettingsUI | 设置界面 (可选) | SPM |

---

## 8. 潜在风险与注意事项

### ⚠️ 权限问题
- 需要「辅助功能」权限才能监听全局快捷键
- Info.plist 需添加 `NSAccessibilityUsageDescription`

### ⚠️ 内存管理
- 图片数据可能很大，需要限制单条记录大小
- 建议图片超过 5MB 时生成缩略图存储

### ⚠️ 并发安全
- 剪贴板监听在主线程外进行
- 数据库操作需要队列保证线程安全

### ⚠️ 隐私合规
- 密码管理器内容需要自动排除
- 提供明确的隐私政策说明

---

## 验证架构

### 验证标准 (来自 ROADMAP.md)

- [ ] 能正确捕获剪贴板变化
- [ ] 数据持久化到 SQLite
- [ ] 快捷键唤起窗口

### 测试命令

```bash
# 1. 构建测试
xcodebuild -project Z-Paste.xcodeproj -scheme Z-Paste build

# 2. 运行后测试剪贴板
# - 复制文本，检查是否出现在历史
# - 复制图片，检查是否正确存储
# - 按快捷键，检查窗口是否弹出
```

---

*研究完成时间：2026-03-17*
