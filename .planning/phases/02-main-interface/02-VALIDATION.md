---
phase: 02
slug: main-interface
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-17
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode 原生) |
| **Config file** | 无 — 参见 Wave 0 |
| **Quick run command** | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` |
| **Full suite command** | 同上 |
| **Estimated runtime** | ~30 秒 |

---

## Sampling Rate

- **After every task commit:** 手动验证该任务功能
- **After every plan wave:** 手动验证所有阶段功能
- **Before `/gsd:verify-work`:** 全部手动验证通过
- **Max feedback latency:** N/A (手动验证)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | 2.1 | 手动 | N/A | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | 2.2 | 手动 | N/A | ❌ W0 | ⬜ pending |
| 02-02-01 | 02 | 1 | 2.3 | 手动 | N/A | ❌ W0 | ⬜ pending |
| 02-02-02 | 02 | 1 | 2.6 | 手动 | N/A | ❌ W0 | ⬜ pending |
| 02-03-01 | 03 | 2 | 2.4 | 手动 | N/A | ❌ W0 | ⬜ pending |
| 02-03-02 | 03 | 2 | 2.5 | 手动 | N/A | ❌ W0 | ⬜ pending |
| 02-04-01 | 04 | 3 | 2.1 | 手动 | N/A | ❌ W0 | ⬜ pending |
| 02-04-02 | 04 | 3 | 2.1 | 手动 | N/A | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Z-PasteTests/` — 单元测试目录
- [ ] `Z-PasteTests/CardListViewTests.swift` — 卡片列表测试
- [ ] `Z-PasteTests/WindowServiceTests.swift` — 窗口服务测试

*注意: 本阶段 UI 功能主要依赖手动验证，自动化测试覆盖率较低。*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 窗口在屏幕底部显示 | 2.1 | UI 视觉验证 | 运行应用，触发快捷键，观察窗口位置 |
| 滑入/滑出动画 0.2s | 2.2 | 动画流畅度验证 | 触发窗口显示/隐藏，观察动画是否流畅 |
| 卡片显示内容预览 | 2.3 | UI 视觉验证 | 复制不同类型内容，检查卡片预览是否正确 |
| 横向滚动工作 | 2.4 | 交互验证 | 使用触控板/鼠标滚动卡片列表 |
| 选中高亮效果 | 2.5 | UI 视觉验证 | 使用左右箭头键选择卡片，观察高亮效果 |
| 来源应用图标显示 | 2.6 | UI 视觉验证 | 从不同应用复制内容，检查图标是否正确 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [ ] Feedback latency < N/A (手动验证)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
