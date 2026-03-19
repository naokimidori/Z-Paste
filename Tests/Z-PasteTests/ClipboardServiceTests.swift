import XCTest
@testable import Z_Paste

final class ClipboardServiceTests: XCTestCase {
    private var databaseService: DatabaseService!
    private var tempDBPath: String!

    override func setUpWithError() throws {
        tempDBPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_clipboard_\(UUID().uuidString).db")
            .path
        databaseService = try DatabaseService(databasePath: tempDBPath)
    }

    override func tearDownWithError() throws {
        databaseService = nil
        if let tempDBPath {
            try? FileManager.default.removeItem(atPath: tempDBPath)
        }
    }

    func testPerformPrimaryActionReturnsFailedForMissingImageData() {
        let service = ClipboardService(database: databaseService)
        let item = ClipboardItem(content: "Image", itemType: .image, data: nil)

        let result = service.performPrimaryAction(for: item)

        guard case .failed = result else {
            return XCTFail("expected failure result")
        }
    }

    func testAttemptPasteAfterWindowHideReturnsCopiedOnlyWithoutAccessibilityPermission() {
        let service = ClipboardService(
            database: databaseService,
            pasteboardWriter: ClipboardServiceTestsPasteboard(changeCount: 1),
            accessibilityChecker: ClipboardServiceTestsAccessibility(isTrusted: false),
            pasteEventSender: ClipboardServiceTestsEvents()
        )

        XCTAssertEqual(service.attemptPasteAfterWindowHide(), .copiedOnly)
    }
}

private final class ClipboardServiceTestsPasteboard: PasteboardWriting {
    var changeCount: Int

    init(changeCount: Int) {
        self.changeCount = changeCount
    }

    func clearContents() {}
    func setString(_ string: String, forType type: NSPasteboard.PasteboardType) -> Bool { true }
    func setData(_ data: Data, forType type: NSPasteboard.PasteboardType) -> Bool { true }
    func writeObjects(_ objects: [NSPasteboardWriting]) -> Bool { true }
    func types() -> [NSPasteboard.PasteboardType] { [] }
    func string(forType type: NSPasteboard.PasteboardType) -> String? { nil }
    func data(forType type: NSPasteboard.PasteboardType) -> Data? { nil }
    func propertyList(forType type: NSPasteboard.PasteboardType) -> Any? { nil }
}

private struct ClipboardServiceTestsAccessibility: AccessibilityTrustChecking {
    let trusted: Bool

    init(isTrusted: Bool) {
        self.trusted = isTrusted
    }

    func isTrusted() -> Bool { trusted }
}

private final class ClipboardServiceTestsEvents: PasteEventSending {
    func sendCommandV() {}
}
