import SwiftUI

/// 主窗口视图
/// 作为窗口的根视图容器，组合 CardListView 并管理窗口关闭回调
struct MainWindowView: View {
    @StateObject private var viewModel: ClipboardViewModel
    var onHide: (() -> Void)?

    /// 初始化器接收 DatabaseService 依赖
    init(database: DatabaseService, onHide: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: ClipboardViewModel(database: database))
        self.onHide = onHide
    }

    var body: some View {
        ZStack {
            // 背景 - 毛玻璃效果 (WindowService 已处理，这里可透明)
            Color.clear

            // 内容区域
            VStack(spacing: 0) {
                CardListView(
                    viewModel: viewModel,
                    onItemCopied: { [weak onHide] in
                        // 复制后关闭窗口
                        onHide?()
                    },
                    onHide: onHide
                )
            }
        }
        .frame(minWidth: 800, minHeight: 280)  // 最小窗口尺寸
        .onAppear {
            // 每次显示时重新加载数据
            viewModel.loadItems()
        }
    }
}

// MARK: - Preview
#Preview {
    // 预览使用模拟数据
    MainWindowView(database: try! DatabaseService(databasePath: ":memory:"))
        .frame(width: 1000, height: 280)
}
