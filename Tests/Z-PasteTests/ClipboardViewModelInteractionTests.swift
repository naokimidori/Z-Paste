import XCTest
@testable import Z_Paste

@MainActor
final class ClipboardViewModelInteractionTests: XCTestCase {
    private var databaseService: DatabaseService!
    private var tempDBPath: String!

    override func setUpWithError() throws {
        tempDBPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_viewmodel_interaction_\(UUID().uuidString).db")
            .path
        databaseService = try DatabaseService(databasePath: tempDBPath)
    }

    override func tearDownWithError() throws {
        databaseService = nil
        if let tempDBPath {
            try? FileManager.default.removeItem(atPath: tempDBPath)
        }
    }

    func testCopySelectedRequestsPrimaryActionForSelectedItem() throws {
        try databaseService.save(ClipboardItem(content: "first", itemType: .text, createdAt: Date(timeIntervalSince1970: 10)))
        try databaseService.save(ClipboardItem(content: "second", itemType: .text, createdAt: Date(timeIntervalSince1970: 20)))

        let performer = MockPrimaryActionPerformer(result: .pasted)
        let viewModel = ClipboardViewModel(database: databaseService, primaryActionPerformer: performer)
        let callback = expectation(description: "primary action callback")
        viewModel.onPrimaryActionCompleted = { result in
            XCTAssertEqual(result, .pasted)
            callback.fulfill()
        }

        guard let index = viewModel.items.firstIndex(where: { $0.content == "first" }) else {
            return XCTFail("missing expected item")
        }

        viewModel.selectItem(at: index)
        viewModel.copySelected()

        XCTAssertEqual(performer.receivedPrimaryActionItems.map(\.content), ["first"])
        XCTAssertEqual(viewModel.lastPrimaryActionResult, .pasted)
        wait(for: [callback], timeout: 0.2)
    }

    func testCopySelectedDoesNothingWhenSelectionIsInvalid() {
        let performer = MockPrimaryActionPerformer(result: .pasted)
        let viewModel = ClipboardViewModel(database: databaseService, primaryActionPerformer: performer)
        viewModel.selectedIndex = -1

        viewModel.copySelected()

        XCTAssertTrue(performer.receivedPrimaryActionItems.isEmpty)
        XCTAssertNil(viewModel.lastPrimaryActionResult)
    }

    func testToggleFavoriteUpdatesItemInPlaceWithoutReordering() throws {
        try databaseService.save(ClipboardItem(content: "first", itemType: .text, createdAt: Date(timeIntervalSince1970: 10)))
        try databaseService.save(ClipboardItem(content: "second", itemType: .text, createdAt: Date(timeIntervalSince1970: 20)))
        let viewModel = ClipboardViewModel(database: databaseService, primaryActionPerformer: MockPrimaryActionPerformer(result: .pasted))

        guard let target = viewModel.items.first(where: { $0.content == "second" }) else {
            return XCTFail("missing target item")
        }

        viewModel.toggleFavorite(for: target)

        XCTAssertEqual(viewModel.items.map(\.content), ["second", "first"])
        XCTAssertEqual(viewModel.items.first?.isFavorite, true)
    }

    func testDeleteMovesSelectionToNextNeighborWhenAvailable() throws {
        try seedThreeItems()
        let viewModel = ClipboardViewModel(database: databaseService, primaryActionPerformer: MockPrimaryActionPerformer(result: .pasted))
        let target = viewModel.items[1]
        viewModel.selectItem(at: 1)

        viewModel.deleteItem(target)

        XCTAssertEqual(viewModel.items.map(\.content), ["third", "first"])
        XCTAssertEqual(viewModel.selectedIndex, 1)
        XCTAssertEqual(viewModel.selectedItem?.content, "first")
    }

    func testDeleteMovesSelectionBackwardWhenLastItemRemoved() throws {
        try seedThreeItems()
        let viewModel = ClipboardViewModel(database: databaseService, primaryActionPerformer: MockPrimaryActionPerformer(result: .pasted))
        let lastIndex = viewModel.items.count - 1
        let target = viewModel.items[lastIndex]
        viewModel.selectItem(at: lastIndex)

        viewModel.deleteItem(target)

        XCTAssertEqual(viewModel.selectedIndex, 1)
        XCTAssertEqual(viewModel.selectedItem?.content, "second")
    }

    func testDeleteSetsSelectedIndexToMinusOneWhenListBecomesEmpty() throws {
        try databaseService.save(ClipboardItem(content: "only", itemType: .text))
        let viewModel = ClipboardViewModel(database: databaseService, primaryActionPerformer: MockPrimaryActionPerformer(result: .pasted))
        guard let target = viewModel.items.first else {
            return XCTFail("missing only item")
        }

        viewModel.deleteItem(target)

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertEqual(viewModel.selectedIndex, -1)
    }

    func testCopyItemOnlyDoesNotTriggerPasteOrHide() throws {
        try databaseService.save(ClipboardItem(content: "copy-only", itemType: .text))
        let performer = MockPrimaryActionPerformer(result: .pasted)
        let viewModel = ClipboardViewModel(database: databaseService, primaryActionPerformer: performer)
        let target = try XCTUnwrap(viewModel.items.first)
        var callbackInvoked = false
        viewModel.onPrimaryActionCompleted = { _ in callbackInvoked = true }

        viewModel.copyItemOnly(target)

        XCTAssertEqual(performer.receivedWriteOnlyItems.map(\.content), ["copy-only"])
        XCTAssertTrue(performer.receivedPrimaryActionItems.isEmpty)
        XCTAssertFalse(callbackInvoked)
        XCTAssertNil(viewModel.lastPrimaryActionResult)
    }

    private func seedThreeItems() throws {
        try databaseService.save(ClipboardItem(content: "first", itemType: .text, createdAt: Date(timeIntervalSince1970: 10)))
        try databaseService.save(ClipboardItem(content: "second", itemType: .text, createdAt: Date(timeIntervalSince1970: 20)))
        try databaseService.save(ClipboardItem(content: "third", itemType: .text, createdAt: Date(timeIntervalSince1970: 30)))
    }
}

private final class MockPrimaryActionPerformer: ClipboardPrimaryActionPerforming {
    let result: PrimaryActionResult
    private(set) var receivedPrimaryActionItems: [ClipboardItem] = []
    private(set) var receivedWriteOnlyItems: [ClipboardItem] = []

    init(result: PrimaryActionResult) {
        self.result = result
    }

    func writeItemToPasteboard(_ item: ClipboardItem) throws {
        receivedWriteOnlyItems.append(item)
    }

    func performPrimaryAction(for item: ClipboardItem) -> PrimaryActionResult {
        receivedPrimaryActionItems.append(item)
        return result
    }
}
