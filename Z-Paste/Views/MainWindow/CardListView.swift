import AppKit
import SwiftUI

struct CardListView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    var onPrimaryActionCompleted: ((PrimaryActionResult) -> Void)?
    var onHide: (() -> Void)?
    var onContextMenuStateChanged: ((Bool) -> Void)?

    var body: some View {
        Group {
            if viewModel.isEmpty {
                emptyStateView
            } else {
                cardScrollView
            }
        }
        .onAppear {
            viewModel.onPrimaryActionCompleted = onPrimaryActionCompleted
        }
        .background(
            KeyEventHandlingView(
                onLeftArrow: { viewModel.selectPrevious() },
                onRightArrow: { viewModel.selectNext() },
                onReturn: {
                    if !viewModel.isMultiSelectMode {
                        runPrimaryActionForCurrentSelection()
                    }
                },
                onEscape: {
                    if viewModel.isMultiSelectMode {
                        viewModel.toggleMultiSelectMode()
                    } else {
                        onHide?()
                    }
                }
            )
        )
    }

    private func runPrimaryActionForCurrentSelection() {
        viewModel.copySelected()
    }

    private var cardScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        ClipboardCardView(
                            item: item,
                            isSelected: index == viewModel.selectedIndex,
                            isMultiSelectMode: viewModel.isMultiSelectMode,
                            isBatchSelected: item.id.map { viewModel.selectedItemIDs.contains($0) } ?? false,
                            onTap: {
                                viewModel.selectItem(at: index)
                                if viewModel.isMultiSelectMode {
                                    viewModel.toggleBatchSelection(for: item)
                                } else {
                                    runPrimaryActionForCurrentSelection()
                                }
                            },
                            onCopy: {
                                viewModel.selectItem(at: index)
                                viewModel.copyItemOnly(item)
                            },
                            onToggleFavorite: {
                                viewModel.selectItem(at: index)
                                viewModel.toggleFavorite(for: item)
                            },
                            onDelete: {
                                viewModel.selectItem(at: index)
                                viewModel.deleteItem(item)
                            },
                            onContextMenuStateChanged: onContextMenuStateChanged
                        )
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.selectedIndex) { newIndex in
                if let id = viewModel.items[safe: newIndex]?.id {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

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

private struct KeyEventHandlingView: NSViewRepresentable {
    let onLeftArrow: () -> Void
    let onRightArrow: () -> Void
    let onReturn: () -> Void
    let onEscape: () -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onLeftArrow = onLeftArrow
        view.onRightArrow = onRightArrow
        view.onReturn = onReturn
        view.onEscape = onEscape
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onLeftArrow = onLeftArrow
        nsView.onRightArrow = onRightArrow
        nsView.onReturn = onReturn
        nsView.onEscape = onEscape
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

private final class KeyCaptureView: NSView {
    var onLeftArrow: (() -> Void)?
    var onRightArrow: (() -> Void)?
    var onReturn: (() -> Void)?
    var onEscape: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123:
            onLeftArrow?()
        case 124:
            onRightArrow?()
        case 36:
            onReturn?()
        case 53:
            onEscape?()
        default:
            super.keyDown(with: event)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
