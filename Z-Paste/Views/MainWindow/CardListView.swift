import SwiftUI

struct CardListView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    @FocusState private var isFocused: Bool
    var onItemCopied: (() -> Void)?
    var onHide: (() -> Void)?

    var body: some View {
        Group {
            if viewModel.isEmpty {
                emptyStateView
            } else {
                cardScrollView
            }
        }
        .focused($isFocused)
        .onKeyPress(.leftArrow) {
            viewModel.selectPrevious()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            viewModel.selectNext()
            return .handled
        }
        .onKeyPress(.return) {
            viewModel.copySelected()
            onItemCopied?()
            return .handled
        }
        .onKeyPress(.escape) {
            onHide?()
            return .handled
        }
        .onAppear {
            isFocused = true
        }
    }

    // MARK: - Card Scroll View
    private var cardScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        ClipboardCardView(
                            item: item,
                            isSelected: index == viewModel.selectedIndex
                        ) {
                            viewModel.selectItem(at: index)
                        }
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.selectedIndex) { _, newIndex in
                if let id = viewModel.items[safe: newIndex]?.id {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Clipboard History")
                .font(.headline)

            Text("Copy something to see it appear here.\nPress Escape to close.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Array Extension
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
