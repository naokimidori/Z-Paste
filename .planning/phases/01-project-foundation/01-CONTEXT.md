# Phase 1: 项目基础架构 - Context

**Gathered:** 2026-03-17
**Status:** Ready for planning
**Source:** Manual creation for Z-Paste project

<domain>
## Phase Boundary

Phase 1 目标：建立 macOS 剪贴板管理器的核心基础架构

**交付内容:**
1. Xcode 项目结构和基础目录
2. 剪贴板监听服务 (ClipboardService)
3. SQLite 数据库存储 (DatabaseService)
4. 全局快捷键服务 (HotkeyService)
5. 数据模型 (ClipboardItem)
6. 应用排除逻辑

**不包含:**
- UI 界面实现 (Phase 2)
- 搜索功能 (Phase 4)
- 设置界面 (Phase 5)

</domain>

<decisions>
## Implementation Decisions

### 技术栈决策
- **平台:** macOS 13.0+
- **语言:** Swift 5.9+
- **UI 框架:** SwiftUI
- **架构:** MVVM

### 依赖库决策
- **数据库:** GRDB.swift (SPM 安装)
- **快捷键:** KeyboardShortcuts (SPM 安装)
- **无其他外部依赖** (保持轻量)

### 数据存储决策
- SQLite 存储剪贴板历史
- UserDefaults 存储配置
- 图片数据限制 5MB，超出生成缩略图

### 隐私安全决策
- 默认排除密码管理器 (1Password, Keychain 访问的应用)
- 所有数据本地存储，无网络请求
- 辅助功能权限用于全局快捷键

### Claude's Discretion
- 具体代码组织方式
- 函数/类命名约定
- 错误处理细节
- 日志级别和格式

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 项目需求
- `.planning/REQUIREMENTS.md` — 完整功能需求和非功能需求
- `.planning/ROADMAP.md` — Phase 1 目标和验证标准

### 技术研究
- `.planning/phases/01-project-foundation/01-RESEARCH.md` — 技术调研和 API 参考

</canonical_refs>

<specifics>
## Specific Ideas

### 目录结构
```
Z-Paste/
├── Z-Paste.xcodeproj
├── Z-Paste/
│   ├── App/
│   ├── Models/
│   ├── Services/
│   ├── ViewModels/
│   ├── Views/
│   └── Resources/
└── .planning/
```

### 关键 API
- `NSPasteboard.general` - 系统剪贴板
- `NSPasteboard.changedNotification` - 变化通知
- `KeyboardShortcuts` - 全局快捷键
- `GRDB.DatabaseQueue` - 数据库操作

</specifics>

<deferred>
## Deferred Ideas

- 搜索功能 (Phase 4)
- 设置界面 (Phase 5)
- iCloud 同步 (未来版本)
- 跨平台支持 (未来版本)

</deferred>

---

*Phase: 01-project-foundation*
*Context gathered: 2026-03-17*
