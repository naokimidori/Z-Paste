---
phase: 03
slug: interaction-features
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode 原生) |
| **Config file** | 无 — 使用 Xcode/SwiftPM 默认测试发现 |
| **Quick run command** | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/DatabaseServiceTests` |
| **Full suite command** | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` |
| **Estimated runtime** | ~30 秒 |

---

## Sampling Rate

- **After every task commit:** 运行 `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/DatabaseServiceTests`
- **After every plan wave:** 运行 `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'`
- **Before `/gsd:verify-work`:** 全量测试必须通过
- **Max feedback latency:** 30 秒

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | FR-3.5 / ROADMAP-3.1 | unit + manual | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/ClipboardViewModelInteractionTests` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | NFR-2 | unit + manual | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/ClipboardServiceWritebackTests` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 1 | ROADMAP-3.2 | 手动 | manual-only | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 1 | FR-2.3 / ROADMAP-3.3 | unit | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/ClipboardViewModelInteractionTests/testToggleFavoriteUpdatesItemInPlace` | ❌ W0 | ⬜ pending |
| 03-02-03 | 02 | 1 | ROADMAP-3.4 | unit | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/ClipboardViewModelInteractionTests/testDeleteMovesSelectionToNeighbor` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | ROADMAP-3.5 | unit + manual | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS' -only-testing:Z-PasteTests/ClipboardViewModelBatchTests` | ❌ W0 | ⬜ pending |
| 03-03-02 | 03 | 2 | FR-3.5 / FR-2.3 / ROADMAP-3.4 | 手动 | manual-only | ❌ W0 | ⬜ pending |
| 03-04-01 | 04 | 3 | 全部 | 手动 + 全量 | `xcodebuild test -scheme Z-Paste -destination 'platform=macOS'` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Tests/Z-PasteTests/ClipboardViewModelInteractionTests.swift` — 覆盖主动作、收藏、删除与选中迁移
- [ ] `Tests/Z-PasteTests/ClipboardViewModelBatchTests.swift` — 覆盖轻量批量选择与批量管理动作
- [ ] `Tests/Z-PasteTests/ClipboardServiceWritebackTests.swift` — 覆盖 text/rtf/image/file 写回与忽略自身写回逻辑
- [ ] 修复或重写 `Tests/Z-PasteTests/ClipboardServiceTests.swift` — 当前与真实接口不匹配，不能作为可信基线
- [ ] 为 `ClipboardService` / `AppDelegate` 引入可注入依赖边界（如 pasteboard writer / accessibility checker / event sender 协议）以便测试

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 点击文本卡片后前台应用收到粘贴且窗口自动关闭 | FR-3.5 / ROADMAP-3.1 | 涉及系统焦点回流与前台应用集成 | 先授予 Accessibility，打开任意文本输入应用，唤起窗口后点击文本卡片，确认目标应用收到粘贴且面板关闭 |
| 未授予 Accessibility 时退化为仅复制成功并给出反馈 | NFR-2 | 系统权限状态只能手工切换验证 | 关闭辅助功能授权，点击文本卡片，确认未自动粘贴但剪贴板已更新且界面有降级反馈 |
| 右键菜单稳定出现且不被外部点击关闭逻辑提前关掉 | ROADMAP-3.2 | 依赖 AppKit 事件监视与系统菜单行为 | 唤起窗口后对卡片右键，确认菜单稳定显示，可连续操作菜单项 |
| 菜单中的复制不会触发自动粘贴 | ROADMAP-3.2 | 需要区分主动作与次级菜单动作 | 对卡片右键后选择“复制”，确认只更新剪贴板，不向前台应用发送粘贴 |
| 收藏/取消收藏即时更新星标且不改变混排顺序 | FR-2.3 / ROADMAP-3.3 | 视觉与交互连续性验证 | 对多个卡片执行收藏/取消收藏，确认星标即时变化、列表顺序不跳变 |
| 删除当前选中项后选择平滑迁移到相邻项，删空后进入空状态 | ROADMAP-3.4 | 需要观察选择与滚动位置 | 选择中间项和最后一项分别执行删除，确认选择迁移规则正确；删空后显示空状态 |
| 轻量批量模式不破坏单击即粘贴主流程 | ROADMAP-3.5 | 需要验证模式切换与主流程并存 | 进入批量模式执行批量收藏/删除后退出，确认普通模式下单击仍直接执行主动作 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
