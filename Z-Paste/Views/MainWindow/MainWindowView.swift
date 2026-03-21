import SwiftUI

struct MainWindowView: View {
    @StateObject private var viewModel: ClipboardViewModel
    @FocusState private var isSearchFieldFocused: Bool
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
            searchableToolbar
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
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            viewModel.prepareForPresentation()
        }
        .onChange(of: isSearchFieldFocused) { newValue in
            if viewModel.isSearchFieldFocused != newValue {
                viewModel.isSearchFieldFocused = newValue
            }
        }
        .onChange(of: viewModel.isSearchFieldFocused) { newValue in
            if isSearchFieldFocused != newValue {
                isSearchFieldFocused = newValue
            }
        }
    }

    private var searchableToolbar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clipboard history", text: Binding(
                    get: { viewModel.searchQuery },
                    set: { viewModel.setSearchQuery($0) }
                ))
                .focused($isSearchFieldFocused)
                .frame(minHeight: 28)
                .frame(minWidth: 240)

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.clearSearchQuery()
                        viewModel.isSearchFieldFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSearchFieldFocused ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(ClipboardSearchFilter.allCases, id: \.self) { filter in
                    Button(filter.title) {
                        viewModel.setActiveFilter(filter)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .frame(height: 28)
                    .background(viewModel.activeFilter == filter ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(viewModel.isMultiSelectMode ? "完成" : "批量操作") {
                    viewModel.toggleMultiSelectMode()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    MainWindowView(database: try! DatabaseService(databasePath: ":memory:"))
        .frame(width: 1000, height: 320)
}
