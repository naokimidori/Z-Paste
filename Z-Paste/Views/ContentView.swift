import SwiftUI

/// 主窗口占位符视图
/// TODO: 后续计划将实现完整的卡片式横向滚动布局
struct ContentView: View {
    var body: some View {
        VStack {
            Text("Z-Paste - 剪贴板管理器")
                .font(.headline)
            Text("按 Option + ` 唤起窗口")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 400, height: 200)
    }
}
