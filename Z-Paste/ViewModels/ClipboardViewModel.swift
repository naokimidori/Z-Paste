import SwiftUI
import Combine

enum PrimaryActionResult: Equatable {
    case pasted
    case copiedOnly
    case failed(String)
}

protocol ClipboardPrimaryActionPerforming {
    func writeItemToPasteboard(_ item: ClipboardItem) throws
    func performPrimaryAction(for item: ClipboardItem) -> PrimaryActionResult
}

extension ClipboardService: ClipboardPrimaryActionPerforming {}

@MainActor
class ClipboardViewModel: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var selectedIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastPrimaryActionResult: PrimaryActionResult?
    @Published var isMultiSelectMode: Bool = false
    @Published var selectedItemIDs: Set<Int64> = []

    private let database: DatabaseService
    private let primaryActionPerformer: ClipboardPrimaryActionPerforming
    private var cancellables = Set<AnyCancellable>()

    var onPrimaryActionCompleted: ((PrimaryActionResult) -> Void)?

    var selectedItem: ClipboardItem? {
        guard selectedIndex >= 0 && selectedIndex < items.count else { return nil }
        return items[selectedIndex]
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    init(database: DatabaseService, primaryActionPerformer: ClipboardPrimaryActionPerforming? = nil) {
        self.database = database
        self.primaryActionPerformer = primaryActionPerformer ?? ClipboardService(database: database)

        NotificationCenter.default.publisher(for: .clipboardItemsDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadItems()
            }
            .store(in: &cancellables)

        loadItems()
    }

    func loadItems() {
        isLoading = true
        errorMessage = nil

        do {
            items = try database.fetchRecent(limit: 100)
            selectedIndex = items.isEmpty ? -1 : 0
        } catch {
            errorMessage = "无法加载剪贴板历史: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func selectNext() {
        guard !items.isEmpty else { return }
        if selectedIndex < items.count - 1 {
            selectedIndex += 1
        } else {
            selectedIndex = 0
        }
    }

    func selectPrevious() {
        guard !items.isEmpty else { return }
        if selectedIndex > 0 {
            selectedIndex -= 1
        } else {
            selectedIndex = items.count - 1
        }
    }

    func selectItem(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        selectedIndex = index
    }

    func selectItem(id: Int64) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            selectedIndex = index
        }
    }

    func copySelected() {
        guard let item = selectedItem else { return }
        performPrimaryAction(for: item)
    }

    func performPrimaryAction(for item: ClipboardItem) {
        syncSelection(with: item)

        let result = primaryActionPerformer.performPrimaryAction(for: item)
        lastPrimaryActionResult = result
        onPrimaryActionCompleted?(result)
    }

    func copyItemOnly(_ item: ClipboardItem) {
        syncSelection(with: item)

        do {
            try primaryActionPerformer.writeItemToPasteboard(item)
        } catch {
            errorMessage = "无法复制内容: \(error.localizedDescription)"
        }
    }

    func toggleFavorite(for item: ClipboardItem) {
        guard let id = item.id,
              let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        let isFavorite = !items[index].isFavorite

        do {
            try database.toggleFavorite(id: id, isFavorite: isFavorite)
            items[index].isFavorite = isFavorite
        } catch {
            errorMessage = "无法更新收藏状态: \(error.localizedDescription)"
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        guard let id = item.id,
              let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        do {
            try database.delete(id: id)
            items.remove(at: index)
            selectedItemIDs.remove(id)
            reselectAfterDeletion(removedIndex: index)
        } catch {
            errorMessage = "无法删除记录: \(error.localizedDescription)"
        }
    }

    func reselectAfterDeletion(removedIndex: Int) {
        guard !items.isEmpty else {
            selectedIndex = -1
            return
        }

        selectedIndex = min(removedIndex, items.count - 1)
    }

    func toggleMultiSelectMode() {
        isMultiSelectMode.toggle()

        if !isMultiSelectMode {
            selectedItemIDs.removeAll()
        }
    }

    func toggleBatchSelection(for item: ClipboardItem) {
        guard isMultiSelectMode,
              let id = item.id else {
            return
        }

        syncSelection(with: item)

        if selectedItemIDs.contains(id) {
            selectedItemIDs.remove(id)
        } else {
            selectedItemIDs.insert(id)
        }
    }

    func favoriteSelectedItems() {
        guard !selectedItemIDs.isEmpty else { return }

        do {
            for index in items.indices {
                guard let id = items[index].id,
                      selectedItemIDs.contains(id),
                      !items[index].isFavorite else {
                    continue
                }

                try database.toggleFavorite(id: id, isFavorite: true)
                items[index].isFavorite = true
            }
        } catch {
            errorMessage = "无法批量收藏: \(error.localizedDescription)"
        }
    }

    func deleteSelectedItems() {
        let idsToDelete = selectedItemIDs
        guard !idsToDelete.isEmpty else { return }

        let removedIndex = items.firstIndex {
            guard let id = $0.id else { return false }
            return idsToDelete.contains(id)
        } ?? max(selectedIndex, 0)

        do {
            for id in idsToDelete {
                try database.delete(id: id)
            }

            items.removeAll {
                guard let id = $0.id else { return false }
                return idsToDelete.contains(id)
            }
            selectedItemIDs.removeAll()
            reselectAfterDeletion(removedIndex: removedIndex)
        } catch {
            errorMessage = "无法批量删除: \(error.localizedDescription)"
        }
    }

    private func syncSelection(with item: ClipboardItem) {
        if let id = item.id {
            selectItem(id: id)
        } else if let index = items.firstIndex(of: item) {
            selectItem(at: index)
        }
    }
}
