---
phase: 01-project-foundation
plan: 05
subsystem: Services
tags: [exclusion, privacy, clipboard]
dependency_graph:
  requires: ["01-03"]
  provides: ["排除服务", "隐私保护"]
  affects: ["ClipboardService"]
tech_stack:
  added: []
  patterns: ["服务层模式", "UserDefaults 持久化"]
key_files:
  created:
    - path: "Z-Paste/Services/ExclusionService.swift"
      purpose: "应用排除服务"
  modified:
    - path: "Z-Paste/Services/ClipboardService.swift"
      purpose: "集成排除逻辑"
decisions:
  - "默认排除列表包含主流密码管理器 (1Password, Bitwarden, LastDashlane, Keychain)"
  - "使用 UserDefaults 存储用户配置的排除列表"
  - "排除检查在剪贴板提取前进行，避免不必要的处理"
metrics:
  duration_seconds: 120
  tasks_completed: 2
  files_created: 1
  files_modified: 1
  started: "2026-03-17T13:46:54Z"
  completed: "2026-03-17T13:47:50Z"
---

# Phase 01 Plan 05: 应用排除逻辑 Summary

**一句话总结：** 实现 ExclusionService 应用排除服务，默认排除密码管理器和安全应用，集成到 ClipboardService 实现隐私保护

---

## 执行概述

**任务完成：** 2/2
**执行模式：** 自动执行
**偏差：** 无

---

## 任务完成情况

### Task 1: 实现 ExclusionService

**文件：** `Z-Paste/Services/ExclusionService.swift`

**实现内容：**
- `ExclusionService` 类，管理排除应用列表
- 使用 `UserDefaults` 持久化用户配置
- 默认排除列表包含：
  - Finder (`com.apple.finder`)
  - 1Password 所有版本 (`com.1password.1password` 等)
  - Keychain Access (`com.apple.keychain`, `com.apple.Keychain-Access`)
  - 其他密码管理器 (Dashlane, LastPass, Bitwarden)
- 核心方法：
  - `isExcluded()` - 检查当前前台应用是否被排除
  - `add(bundleID:)` - 添加排除应用
  - `remove(bundleID:)` - 移除排除应用
  - `getCurrentAppBundleID()` - 获取前台应用 Bundle ID
  - `resetToDefaults()` - 重置为默认排除列表

**提交：** `6936bb9` - feat(01-05): 实现 ExclusionService 应用排除服务

---

### Task 2: 集成 ExclusionService 到 ClipboardService

**文件：** `Z-Paste/Services/ClipboardService.swift`

**修改内容：**
- 添加 `exclusionService` 属性
- 在 `checkClipboard()` 方法中首先调用 `exclusionService.isExcluded()`
- 如果返回 `true`，打印日志并跳过本次剪贴板检查
- 删除原有的内联排除逻辑（`excludedApps` 属性和相关方法），委托给 `ExclusionService`

**提交：** `e918ceb` - feat(01-05): 集成 ExclusionService 到 ClipboardService

---

## 决策记录

1. **默认排除列表范围**
   - 决定包含主流密码管理器（1Password, Bitwarden, LastPass, Dashlane）
   - 包含 Keychain Access 防止系统级敏感信息
   - 未包含 Chrome 等浏览器（避免过度排除影响用户体验）

2. **存储方案**
   - 使用 `UserDefaults` 而非 SQLite
   - 原因：排除列表是配置数据，数据量小，读取频繁

3. **检查时机**
   - 在 `checkClipboard()` 最开始进行排除检查
   - 避免对排除应用进行不必要的剪贴板提取和处理

---

## 验证结果

### 自动化验证

```bash
# ExclusionService 实现验证
grep -q "frontmostApplication" ExclusionService.swift && \
grep -q "excludedApps" ExclusionService.swift && \
echo "OK: ExclusionService implemented"

# ClipboardService 集成验证
grep -q "exclusionService" ClipboardService.swift && \
grep -q "isExcluded" ClipboardService.swift && \
echo "OK: ExclusionService integrated"
```

**结果：** 全部通过

---

## 成功标准核对

- [x] ExclusionService 实现完成
- [x] 默认排除 1Password 和 Keychain 应用
- [x] ClipboardService 在排除应用中不捕获剪贴板
- [x] 配置持久化到 UserDefaults

---

## 自检验证

### 文件存在性

```bash
[ -f "Z-Paste/Services/ExclusionService.swift" ] && echo "FOUND: ExclusionService.swift"
[ -f "Z-Paste/Services/ClipboardService.swift" ] && echo "FOUND: ClipboardService.swift"
```

### 提交存在性

```bash
git log --oneline --all | grep -q "6936bb9" && echo "FOUND: 6936bb9"
git log --oneline --all | grep -q "e918ceb" && echo "FOUND: e918ceb"
```

**自检验证：** PASSED

---

*执行完成时间：2026-03-17*
