# Z-Paste - 项目状态

## 当前阶段

**Phase:** 2 - 主界面实现 🔄 进行中

**时间：** 2026-03-17

## 阶段进度

| 阶段 | 状态 | 描述 |
|------|------|------|
| 0. 项目初始化 | ✅ 完成 | 创建 PROJECT.md, config.json, STATE.md |
| 1. 需求分析 | ✅ 完成 | 创建 REQUIREMENTS.md, ROADMAP.md |
| 2. 路线图 | ✅ 完成 | ROADMAP.md 已创建 |
| 3. 执行 Phase 1 | ✅ 完成 | Phase 1 所有计划完成，验证通过 |
| 4. 执行 Phase 2 | 🔄 进行中 | 卡片组件已完成 |

## 当前计划进度

**Phase 1 Plans:**
- [x] 01-project-foundation-01 — 创建 Xcode 项目结构 ✅ (SUMMARY.md 已创建)
- [x] 01-project-foundation-02 — ClipboardItem 数据模型 ✅ (SUMMARY.md 已创建)
- [x] 01-project-foundation-03 — ClipboardService 和 DatabaseService ✅ (SUMMARY.md 已创建)
- [x] 01-project-foundation-04 — HotkeyService 全局快捷键 ✅ (SUMMARY.md 已创建)
- [x] 01-project-foundation-05 — 应用排除逻辑 ✅ (SUMMARY.md 已创建)

**Phase 2 Plans:**
- [x] 02-main-interface-02 — ClipboardCardView 卡片组件 ✅ (SUMMARY.md 已创建)
- [ ] 02-main-interface-03 — 待执行
- [ ] 02-main-interface-04 — 待执行
- [ ] 02-main-interface-05 — 待执行

**验证状态：** Phase 1 ✅ passed (4/4 must-haves verified)
**验证报告：** `.planning/phases/01-project-foundation/01-VERIFICATION.md`

## 上下文恢复

### 项目信息
- **名称：** Z-Paste
- **平台：** macOS 13.0+
- **技术栈：** Swift 5.9+ / SwiftUI
- **参考产品：** Paste (https://pasteapp.io/)

### 核心需求
1. 底部弹出式窗口 (Option + ` 快捷键)
2. 卡片式横向滚动布局
3. 支持文本/图片/文件/富文本
4. 500-1000 条历史记录
5. 基础搜索 + 收藏功能
6. 应用排除功能

### 最新决策
- 使用 CryptoKit 进行 SHA256 哈希（而非 CommonCrypto）
- 数据库扩展代码分离到独立文件
- 使用 Timer 轮询监听剪贴板（而非 NSPasteboard.changedNotification）
- KeyboardShortcuts 库已集成并启用
- 默认排除列表包含主流密码管理器（1Password, Bitwarden, LastPass, Dashlane, Keychain）
- Card size locked at 250x250px as specified in UI-SPEC.md (Phase 2)
- Three-section layout: header (type label + favorite), content preview, footer (app icon + timestamp + size) (Phase 2)
- Glass morphism background using .ultraThinMaterial (Phase 2)

### 下一步
继续执行 Phase 2 计划：CardListView 和 MainWindowView 组件
