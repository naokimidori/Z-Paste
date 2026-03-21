import XCTest
@testable import Z_Paste

@MainActor
final class SearchFilterTests: XCTestCase {
    private var databaseService: DatabaseService!
    private var tempDBPath: String!

    override func setUpWithError() throws {
        tempDBPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_search_filter_\(UUID().uuidString).db")
            .path
        databaseService = try DatabaseService(databasePath: tempDBPath)
    }

    override func tearDownWithError() throws {
        databaseService = nil
        if let tempDBPath {
            try? FileManager.default.removeItem(atPath: tempDBPath)
        }
    }

    func testSearchQueryAndFilterCombine() {
        let items = sampleItems()
        let results = items.filter {
            ClipboardSearchFilter.all.matches(item: $0, query: "swift")
        }

        XCTAssertEqual(results.map(\.content), [
            "Swift clipboard notes",
            "Rich Swift snippet",
            "/tmp/SwiftGuide.pdf"
        ])
    }

    func testLinksFilterUsesSystemOpenableURLRule() {
        let items = sampleItems()
        let results = items.filter {
            ClipboardSearchFilter.links.matches(item: $0, query: "")
        }

        XCTAssertEqual(results.map(\.content), [
            "https://example.com/docs"
        ])
    }

    func testTextFilterIncludesRTFItems() {
        let items = sampleItems()
        let results = items.filter {
            ClipboardSearchFilter.text.matches(item: $0, query: "")
        }

        XCTAssertEqual(results.map(\.itemType), [.text, .rtf])
    }

    func testPrepareForPresentationResetsSearchState() {
        let viewModel = ClipboardViewModel(database: databaseService)
        viewModel.searchQuery = "swift"
        viewModel.activeFilter = .links
        viewModel.isSearchFieldFocused = false

        viewModel.prepareForPresentation()

        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertEqual(viewModel.activeFilter, .all)
        XCTAssertTrue(viewModel.isSearchFieldFocused)
    }

    func testFavoritesFilterMatchesOnlyFavorites() {
        let items = sampleItems()
        let results = items.filter {
            ClipboardSearchFilter.favorites.matches(item: $0, query: "")
        }

        XCTAssertEqual(results.map(\.content), [
            "Swift clipboard notes"
        ])
    }

    private func sampleItems() -> [ClipboardItem] {
        [
            ClipboardItem(content: "Swift clipboard notes", itemType: .text, isFavorite: true),
            ClipboardItem(content: "Rich Swift snippet", itemType: .rtf),
            ClipboardItem(content: "https://example.com/docs", itemType: .text),
            ClipboardItem(content: "not a link value", itemType: .text),
            ClipboardItem(content: "/tmp/SwiftGuide.pdf", itemType: .file),
            ClipboardItem(content: "image-placeholder", itemType: .image)
        ]
    }
}
