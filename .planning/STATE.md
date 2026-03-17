# Z-Paste - 项目状态

## 当前阶段

**Phase:** 1 - 项目基础架构 🚧 进行中

**时间：** 2026-03-17

## 阶段进度

| 阶段 | 状态 | 描述 |
|------|------|------|
| 0. 项目初始化 | ✅ 完成 | 创建 PROJECT.md, config.json, STATE.md |
| 1. 需求分析 | ✅ 完成 | 创建 REQUIREMENTS.md, ROADMAP.md |
| 2. 路线图 | ✅ 完成 | ROADMAP.md 已创建 |
| 3. 执行 | 🚧 进行中 | Plan 02 完成：ClipboardItem 数据模型 |

## 当前计划进度

**Phase 1 Plans:**
- [x] 01-project-foundation-01 — 创建 Xcode 项目结构
- [x] 01-project-foundation-02 — ClipboardItem 数据模型 ✅
- [ ] 01-project-foundation-03 — ClipboardService 和 DatabaseService
- [ ] 01-project-foundation-04 — HotkeyService 全局快捷键
- [ ] 01-project-foundation-05 — 应用排除逻辑

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

### 下一步
继续执行 Plan 03：实现 ClipboardService 和 DatabaseService 核心服务
