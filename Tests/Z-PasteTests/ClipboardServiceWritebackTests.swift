import XCTest
@testable import Z_Paste

final class ClipboardServiceWritebackTests: XCTestCase {
    private var databaseService: DatabaseService!
    private var tempDBPath: String!

    override func setUpWithError() throws {
        tempDBPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_clipboard_writeback_\(UUID().uuidString).db")
            .path
        databaseService = try DatabaseService(databasePath: tempDBPath)
    }

    override func tearDownWithError() throws {
        databaseService = nil
        if let tempDBPath {
            try? FileManager.default.removeItem(atPath: tempDBPath)
        }
    }

    func testWriteItemToPasteboardWritesTextAndSkipsNextMonitorSave() throws {
        let pasteboard = MockPasteboardWriter(changeCount: 7)
        let service = makeService(pasteboard: pasteboard)
        let item = ClipboardItem(content: "hello", itemType: .text)

        try service.writeItemToPasteboard(item)

        XCTAssertTrue(pasteboard.didClearContents)
        XCTAssertEqual(pasteboard.strings[.string], "hello")
        XCTAssertTrue(service.consumePendingSelfWriteSuppression(changeCount: 7))
        XCTAssertFalse(service.consumePendingSelfWriteSuppression(changeCount: 7))
    }

    func testWriteItemToPasteboardWritesRTFAndPlainTextFallback() throws {
        let pasteboard = MockPasteboardWriter(changeCount: 3)
        let service = makeService(pasteboard: pasteboard)
        let rtfData = Data("{\\rtf1 test}".utf8)
        let item = ClipboardItem(content: "test", itemType: .rtf, data: rtfData)

        try service.writeItemToPasteboard(item)

        XCTAssertEqual(pasteboard.dataByType[.rtf], rtfData)
        XCTAssertEqual(pasteboard.strings[.string], "test")
    }

    func testWriteItemToPasteboardWritesImageData() throws {
        let pasteboard = MockPasteboardWriter(changeCount: 4)
        let service = makeService(pasteboard: pasteboard)
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let item = ClipboardItem(content: "Image", itemType: .image, data: imageData)

        try service.writeItemToPasteboard(item)

        XCTAssertEqual(pasteboard.dataByType[.png], imageData)
    }

    func testWriteItemToPasteboardWritesFileURLsFromNewlineSeparatedPaths() throws {
        let pasteboard = MockPasteboardWriter(changeCount: 5)
        let service = makeService(pasteboard: pasteboard)
        let item = ClipboardItem(content: "/tmp/a.txt\n/tmp/b.txt", itemType: .file)

        try service.writeItemToPasteboard(item)

        XCTAssertEqual(pasteboard.writtenURLs.map(\.path), ["/tmp/a.txt", "/tmp/b.txt"])
    }

    func testPerformPrimaryActionReturnsCopiedOnlyWhenAccessibilityIsUnavailable() {
        let pasteboard = MockPasteboardWriter(changeCount: 9)
        let accessibility = MockAccessibilityTrustChecker(isTrusted: false)
        let events = MockPasteEventSender()
        let service = makeService(pasteboard: pasteboard, accessibility: accessibility, events: events)
        let item = ClipboardItem(content: "hello", itemType: .text)

        let result = service.performPrimaryAction(for: item)

        XCTAssertEqual(result, .copiedOnly)
        XCTAssertEqual(pasteboard.strings[.string], "hello")
        XCTAssertEqual(events.sendCount, 0)
    }

    private func makeService(
        pasteboard: MockPasteboardWriter,
        accessibility: MockAccessibilityTrustChecker = MockAccessibilityTrustChecker(isTrusted: true),
        events: MockPasteEventSender = MockPasteEventSender()
    ) -> ClipboardService {
        ClipboardService(
            database: databaseService,
            pasteboardWriter: pasteboard,
            accessibilityChecker: accessibility,
            pasteEventSender: events
        )
    }
}

private final class MockPasteboardWriter: PasteboardWriting {
    var changeCount: Int
    var strings: [NSPasteboard.PasteboardType: String] = [:]
    var dataByType: [NSPasteboard.PasteboardType: Data] = [:]
    var writtenURLs: [URL] = []
    var didClearContents = false

    init(changeCount: Int) {
        self.changeCount = changeCount
    }

    func clearContents() {
        didClearContents = true
    }

    func setString(_ string: String, forType type: NSPasteboard.PasteboardType) -> Bool {
        strings[type] = string
        return true
    }

    func setData(_ data: Data, forType type: NSPasteboard.PasteboardType) -> Bool {
        dataByType[type] = data
        return true
    }

    func writeObjects(_ objects: [NSPasteboardWriting]) -> Bool {
        writtenURLs = objects.compactMap { $0 as? URL }
        return !writtenURLs.isEmpty
    }

    func types() -> [NSPasteboard.PasteboardType] {
        Array(Set(strings.keys).union(dataByType.keys))
    }

    func string(forType type: NSPasteboard.PasteboardType) -> String? {
        strings[type]
    }

    func data(forType type: NSPasteboard.PasteboardType) -> Data? {
        dataByType[type]
    }

    func propertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        if type == .fileURL {
            return writtenURLs.map(\.absoluteString)
        }
        return nil
    }
}

private struct MockAccessibilityTrustChecker: AccessibilityTrustChecking {
    let isTrustedValue: Bool

    init(isTrusted: Bool) {
        self.isTrustedValue = isTrusted
    }

    func isTrusted() -> Bool {
        isTrustedValue
    }
}

private final class MockPasteEventSender: PasteEventSending {
    private(set) var sendCount = 0

    func sendCommandV() {
        sendCount += 1
    }
}
