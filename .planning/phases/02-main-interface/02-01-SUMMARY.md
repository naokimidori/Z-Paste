---
phase: 02-main-interface
plan: 01
status: complete
completed_at: 2026-03-18
duration_minutes: 5
---

# Plan 02-01: WindowService - Complete

## Summary

创建了 WindowService 单例服务，实现 NSPanel 底部弹出窗口的创建、显示、隐藏和滑入/滑出动画。

## What Was Built

### WindowService.swift
- **NSPanel 配置**: borderless、nonactivatingPanel、floating 层级
- **滑入/滑出动画**: 0.2秒 easeInEaseOut timing function
- **多显示器支持**: 通过鼠标位置检测当前显示器
- **毛玻璃背景**: NSVisualEffectView with hudWindow material
- **窗口位置**: 屏幕底部中央，宽度等于屏幕宽度

## Key Implementation Details

1. **窗口高度**: 280px (卡片高度 250 + padding)
2. **动画参数**: duration=0.2s, timingFunction=easeInEaseOut
3. **位置计算**: 使用 `visibleFrame` 而非 `frame` 避免 Dock 遮挡
4. **多显示器**: `NSEvent.mouseLocation` + `NSScreen.screens.first(where:)`

## Files Created

| File | Purpose |
|------|---------|
| `Z-Paste/Services/WindowService.swift` | NSPanel 窗口管理和动画服务 |

## Commits

- `073204f`: feat(02-01): create WindowService with slide animation

## Verification

- [x] WindowService.swift 存在
- [x] 包含 `NSAnimationContext.runAnimationGroup`
- [x] 包含 `context.duration = 0.2`
- [x] 包含 `easeInEaseOut` timingFunction
- [x] 包含 `createPanel(with:)` 方法
- [x] 包含 `showWindow()` 方法
- [x] 包含 `hideWindow()` 方法
- [x] 包含 `toggleWindow()` 方法
- [x] 使用 `visibleFrame` 计算位置

## Next Steps

Wave 2 将使用 WindowService 创建 CardListView 和 ClipboardViewModel。
