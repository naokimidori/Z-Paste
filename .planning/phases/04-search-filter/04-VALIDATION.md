---
phase: 04
slug: search-filter
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode 原生) |
| **Config file** | 无 — 使用 Xcode/SwiftPM 默认测试发现 |
| **Quick run command** | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` |
| **Full suite command** | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` |
| **Estimated runtime** | ~30 秒 |

---

## Sampling Rate

- **After every task commit:** 运行 `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'`
- **After every plan wave:** 运行 `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'`
- **Before `/gsd:verify-work`:** 全量测试必须通过
- **Max feedback latency:** 30 秒

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-00-01 | 00 | 0 | FR-4.1 / FR-4.2 / FR-4.3 | unit scaffold | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` | ❌ W0 | ⬜ pending |
| 04-01-01 | 01 | 1 | FR-4.1 | unit | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` | ❌ W0 | ⬜ pending |
| 04-01-02 | 01 | 1 | FR-4.2 | integration | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` | ❌ W0 | ⬜ pending |
| 04-02-01 | 02 | 2 | FR-4.1 / FR-4.2 | manual + integration | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` | ❌ W0 | ⬜ pending |
| 04-03-01 | 03 | 3 | FR-4.3 | unit + UI/manual | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Tests/Z-PasteTests/SearchFilterTests.swift` — 覆盖搜索词过滤、互斥筛选、无结果状态与高亮判定
- [ ] 为 `ClipboardViewModel` 暴露可测试的搜索/筛选状态边界，避免只能通过 UI 手工回归验证
- [ ] 如高亮逻辑拆分为独立 helper / formatter，为其补充纯单元测试入口

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 唤起窗口后搜索框自动聚焦，重新打开窗口时搜索词已清空 | FR-4.1 | 依赖窗口生命周期与焦点转移，单元测试难以可靠覆盖 | 关闭面板前输入关键词，隐藏后重新唤起，确认搜索框获得焦点且输入内容被清空 |
| 搜索框编辑时左右方向键优先移动文本光标，失焦后恢复卡片导航 | FR-4.1 / FR-4.2 | 涉及 SwiftUI 文本输入与现有键盘导航竞争 | 聚焦搜索框输入长文本，使用左右键确认光标移动；再失焦后使用左右键确认卡片选择恢复 |
| 筛选标签始终单层互斥，只保留一个激活条件，并与搜索词叠加生效 | FR-4.2 | 需要观察真实界面选中态与交互连续性 | 依次点击“收藏 / 链接 / 文本 / 图片 / 文件”，确认同一时刻仅一个标签激活，并且输入搜索词后结果继续收窄 |
| 无结果态与“历史为空”明确区分，且保留当前搜索词和筛选条件 | FR-4.2 | 需要验证界面文案与恢复动作 | 输入不存在的关键词或选择无匹配筛选，确认显示专用无结果态，并可通过清空搜索恢复 |
| 文本/富文本卡片展示匹配高亮，图片/文件卡片保持正常预览 | FR-4.3 | 高亮呈现属于视觉细节，需人工确认渲染效果 | 搜索命中文本与富文本内容，确认预览中出现高亮；搜索命中图片/文件时确认仍为普通预览、不出现异常标记 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
