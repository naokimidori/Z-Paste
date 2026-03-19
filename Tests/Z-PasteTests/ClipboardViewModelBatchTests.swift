import XCTest
@testable import Z_Paste

@MainActor
final class ClipboardViewModelBatchTests: XCTestCase {
    private var databaseService: DatabaseService!
    private var tempDBPath: String!

    override func setUpWithError() throws {
        tempDBPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_viewmodel_batch_\(UUID().uuidString).db")
            .path
        databaseService = try DatabaseService(databasePath: tempDBPath)
        try databaseService.save(ClipboardItem(content: "first", itemType: .text, createdAt: Date(timeIntervalSince1970: 10)))
        try databaseService.save(ClipboardItem(content: "second", itemType: .text, createdAt: Date(timeIntervalSince1970: 20)))
        try databaseService.save(ClipboardItem(content: "third", itemType: .text, createdAt: Date(timeIntervalSince1970: 30)))
    }

    override func tearDownWithError() throws {
        databaseService = nil
        if let tempDBPath {
            try? FileManager.default.removeItem(atPath: tempDBPath)
        }
    }

    func testToggleMultiSelectModeClearsSelectionWhenTurningOff() {
        let viewModel = makeViewModel()
        let first = try! XCTUnwrap(viewModel.items.first)

        viewModel.toggleMultiSelectMode()
        viewModel.toggleBatchSelection(for: first)
        XCTAssertFalse(viewModel.selectedItemIDs.isEmpty)

        viewModel.toggleMultiSelectMode()

        XCTAssertFalse(viewModel.isMultiSelectMode)
        XCTAssertTrue(viewModel.selectedItemIDs.isEmpty)
    }

    func testToggleBatchSelectionAddsAndRemovesIDs() {
        let viewModel = makeViewModel()
        let first = try! XCTUnwrap(viewModel.items.first)
        viewModel.toggleMultiSelectMode()

        viewModel.toggleBatchSelection(for: first)
        XCTAssertEqual(viewModel.selectedItemIDs, [first.id!])

        viewModel.toggleBatchSelection(for: first)
        XCTAssertTrue(viewModel.selectedItemIDs.isEmpty)
    }

    func testFavoriteSelectedItemsUpdatesOnlySelectedItems() {
        let viewModel = makeViewModel()
        let first = viewModel.items[0]
        let third = viewModel.items[2]
        viewModel.toggleMultiSelectMode()
        viewModel.toggleBatchSelection(for: first)
        viewModel.toggleBatchSelection(for: third)

        viewModel.favoriteSelectedItems()

        XCTAssertTrue(viewModel.items[0].isFavorite)
        XCTAssertFalse(viewModel.items[1].isFavorite)
        XCTAssertTrue(viewModel.items[2].isFavorite)
    }

    func testDeleteSelectedItemsRemovesItemsAndKeepsValidSelection() {
        let viewModel = makeViewModel()
        let first = viewModel.items[0]
        let second = viewModel.items[1]
        viewModel.selectItem(at: 1)
        viewModel.toggleMultiSelectMode()
        viewModel.toggleBatchSelection(for: first)
        viewModel.toggleBatchSelection(for: second)

        viewModel.deleteSelectedItems()

        XCTAssertEqual(viewModel.items.map(\.content), ["first"])
        XCTAssertTrue(viewModel.selectedItemIDs.isEmpty)
        XCTAssertEqual(viewModel.selectedIndex, 0)
        XCTAssertEqual(viewModel.selectedItem?.content, "first")
    }

    private func makeViewModel() -> ClipboardViewModel {
        ClipboardViewModel(database: databaseService, primaryActionPerformer: BatchMockPrimaryActionPerformer())
    }
}

private final class BatchMockPrimaryActionPerformer: ClipboardPrimaryActionPerforming {
    func writeItemToPasteboard(_ item: ClipboardItem) throws {}

    func performPrimaryAction(for item: ClipboardItem) -> PrimaryActionResult {
        .pasted
    }
}
