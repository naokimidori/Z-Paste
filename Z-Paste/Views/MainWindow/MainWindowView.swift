import SwiftUI

struct MainWindowView: View {
    @StateObject private var viewModel: ClipboardViewModel
    var onPrimaryActionCompleted: ((PrimaryActionResult) -> Void)?
    var onHide: (() -> Void)?
    var onContextMenuStateChanged: ((Bool) -> Void)?

    init(
        database: DatabaseService,
        primaryActionPerformer: ClipboardPrimaryActionPerforming? = nil,
        onPrimaryActionCompleted: ((PrimaryActionResult) -> Void)? = nil,
        onHide: (() -> Void)? = nil,
        onContextMenuStateChanged: ((Bool) -> Void)? = nil
    ) {
        self._viewModel = StateObject(
            wrappedValue: ClipboardViewModel(
                database: database,
                primaryActionPerformer: primaryActionPerformer
            )
        )
        self.onPrimaryActionCompleted = onPrimaryActionCompleted
        self.onHide = onHide
        self.onContextMenuStateChanged = onContextMenuStateChanged
    }

    var body: some View {
        VStack(spacing: 0) {
            batchToolbar
            CardListView(
                viewModel: viewModel,
                onPrimaryActionCompleted: onPrimaryActionCompleted,
                onHide: onHide,
                onContextMenuStateChanged: onContextMenuStateChanged
            )
        }
        .frame(minWidth: 800, minHeight: 280)
        .onAppear {
            viewModel.loadItems()
        }
    }

    private var batchToolbar: some View {
        HStack(spacing: 12) {
            Button(viewModel.isMultiSelectMode ? "完成" : "批量操作") {
                viewModel.toggleMultiSelectMode()
            }

            if viewModel.isMultiSelectMode {
                Button("批量收藏") {
                    viewModel.favoriteSelectedItems()
                }
                .disabled(viewModel.selectedItemIDs.isEmpty)

                Button("批量删除") {
                    viewModel.deleteSelectedItems()
                }
                .disabled(viewModel.selectedItemIDs.isEmpty)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

#Preview {
    MainWindowView(database: try! DatabaseService(databasePath: ":memory:"))
        .frame(width: 1000, height: 320)
}
