# 03-01 SUMMARY

## 完成内容
- 在 `ClipboardService` 中加入主动作能力：`writeItemToPasteboard(_:)`、`attemptPasteAfterWindowHide()`、`performPrimaryAction(for:)`。
- 为主动作链路引入可测试边界：`PasteboardWriting`、`AccessibilityTrustChecking`、`PasteEventSending`。
- 在 `ClipboardViewModel` 中统一主动作入口，保留 `copySelected()`，并通过 `onPrimaryActionCompleted` 上抛 `PrimaryActionResult`。
- 在 `CardListView` 中统一单击卡片与 Enter 键行为，二者都走同一条主动作链路。
- 在 `MainWindowView` / `AppDelegate` / `WindowService` 中接入“先隐藏窗口，再尝试粘贴”的收尾顺序，并保留 `copiedOnly` 降级结果。
- 增加写回与交互测试，覆盖 text / rtf / image / file 四类写回、缺少辅助功能权限时的降级路径，以及 ViewModel 的统一动作触发。

## 关键文件
- `Z-Paste/Services/ClipboardService.swift`
- `Z-Paste/ViewModels/ClipboardViewModel.swift`
- `Z-Paste/Views/MainWindow/CardListView.swift`
- `Z-Paste/Views/MainWindow/MainWindowView.swift`
- `Z-Paste/App/AppDelegate.swift`
- `Z-Paste/Services/WindowService.swift`
- `Tests/Z-PasteTests/ClipboardServiceTests.swift`
- `Tests/Z-PasteTests/ClipboardServiceWritebackTests.swift`
- `Tests/Z-PasteTests/ClipboardViewModelInteractionTests.swift`

## 验证
- `swift test --package-path "/Users/longzhao/aicodes/Z-Paste"`
- 结果：通过（28 tests, 0 failures）

## 行为结果
- 单击卡片与按 Enter 不再分叉，都会触发同一条主动作逻辑。
- 主动作会先把历史项写回系统剪贴板，再在窗口隐藏后尝试向前台应用发送粘贴。
- 缺少辅助功能权限时不会中断主流程，而是返回 `copiedOnly` 作为可用降级结果。
- 程序化写回会抑制下一次监听入库，避免把主动写回再次记录成新的历史项。
