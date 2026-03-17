import SwiftUI
import Combine

/// 剪贴板视图模型
/// 负责管理剪贴板数据绑定和状态
@MainActor
class ClipboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var items: [ClipboardItem] = []
    @Published var selectedIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let database: DatabaseService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var selectedItem: ClipboardItem? {
        guard selectedIndex >= 0 && selectedIndex < items.count else { return nil }
        return items[selectedIndex]
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    // MARK: - Initialization
    init(database: DatabaseService) {
        self.database = database
        loadItems()
    }

    // MARK: - Data Loading
    func loadItems() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                items = try database.fetchRecent(limit: 100)
                // 默认选中第一个（最新的）
                selectedIndex = items.isEmpty ? -1 : 0
            } catch {
                errorMessage = "无法加载剪贴板历史: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    // MARK: - Navigation
    func selectNext() {
        guard !items.isEmpty else { return }
        if selectedIndex < items.count - 1 {
            selectedIndex += 1
        } else {
            // Wrap to first
            selectedIndex = 0
        }
    }

    func selectPrevious() {
        guard !items.isEmpty else { return }
        if selectedIndex > 0 {
            selectedIndex -= 1
        } else {
            // Wrap to last
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

    // MARK: - Actions (Phase 3 will implement)
    func copySelected() {
        guard let item = selectedItem else { return }
        // TODO: Phase 3 - 实现复制到剪贴板
        print("Copy selected: \(item.content)")
    }
}
