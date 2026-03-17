import XCTest
import GRDB
@testable import Z_Paste

final class DatabaseServiceTests: XCTestCase {
    var dbService: DatabaseService!
    var tempDBPath: String!

    override func setUp() async throws {
        try await super.setUp()
        // 创建临时数据库路径
        tempDBPath = FileManager.default.temporaryDirectory.appendingPathComponent("test_clipboard_\(UUID().uuidString).db").path
        dbService = try DatabaseService(databasePath: tempDBPath)
    }

    override func tearDown() async throws {
        // 清理临时数据库文件
        if let tempDBPath = tempDBPath {
            try? FileManager.default.removeItem(atPath: tempDBPath)
        }
        dbService = nil
        try await super.tearDown()
    }

    // Test 1: 创建数据库后，表 clipboard_items 存在
    func testTableExists() throws {
        let exists = try dbService.tableExists("clipboard_items")
        XCTAssertTrue(exists, "clipboard_items 表应该存在")
    }

    // Test 2: save(item) 后，fetchRecent 能返回该记录
    func testSaveAndFetchRecent() throws {
        let item = ClipboardItem(
            content: "Test content",
            itemType: .text,
            sourceApp: "com.apple.TextEdit"
        )

        try dbService.save(item)

        let fetched = try dbService.fetchRecent(limit: 10)
        XCTAssertEqual(fetched.count, 1, "应该返回 1 条记录")
        XCTAssertEqual(fetched[0].content, "Test content")
        XCTAssertEqual(fetched[0].itemType, .text)
        XCTAssertEqual(fetched[0].sourceApp, "com.apple.TextEdit")
    }

    // Test 3: delete(item) 后，记录不存在
    func testDeleteItem() throws {
        var item = ClipboardItem(
            content: "To be deleted",
            itemType: .text
        )

        try dbService.save(item)

        // 获取保存后的 ID
        let fetched = try dbService.fetchRecent(limit: 1)
        guard let savedId = fetched.first?.id else {
            XCTFail("应该能获取到保存的 ID")
            return
        }

        // 删除
        try dbService.delete(id: savedId)

        let afterDelete = try dbService.fetchRecent(limit: 10)
        XCTAssertEqual(afterDelete.count, 0, "删除后应该没有记录")
    }

    // Test 4: cleanup(limit: 1000) 保留最近 1000 条，删除更旧的
    func testCleanupRespectsLimit() throws {
        // 创建 1005 条记录
        for i in 0..<1005 {
            var item = ClipboardItem(
                content: "Item \(i)",
                itemType: .text
            )
            item.createdAt = Date().addingTimeInterval(Double(i) * -1) // 时间递减
            try dbService.save(item)
        }

        // 执行清理
        try dbService.cleanup(limit: 1000)

        let remaining = try dbService.fetchRecent(limit: 2000)
        XCTAssertEqual(remaining.count, 1000, "cleanup 后应该保留 1000 条记录")
    }

    // Test 4b: cleanup 保留收藏项
    func testCleanupPreservesFavorites() throws {
        // 创建 5 条普通记录和 3 条收藏记录
        for i in 0..<5 {
            var item = ClipboardItem(
                content: "Normal \(i)",
                itemType: .text
            )
            item.createdAt = Date().addingTimeInterval(Double(i) * -1000)
            try dbService.save(item)
        }

        for i in 0..<3 {
            var item = ClipboardItem(
                content: "Favorite \(i)",
                itemType: .text
            )
            item.isFavorite = true
            item.createdAt = Date().addingTimeInterval(Double(i) * -10000) // 更早的时间
            try dbService.save(item)
        }

        // 清理限制为 2 条
        try dbService.cleanup(limit: 2)

        let remaining = try dbService.fetchRecent(limit: 100)
        // 应该保留 2 条最新的普通记录 + 3 条收藏记录 = 5 条
        XCTAssertGreaterThanOrEqual(remaining.count, 3, "应该至少保留所有收藏项")

        // 验证所有收藏项都被保留
        let favorites = remaining.filter { $0.isFavorite }
        XCTAssertEqual(favorites.count, 3, "所有收藏项都应该被保留")
    }

    // Test 5: 并发写入不崩溃
    func testConcurrentWrites() throws {
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        let expectation = self.expectation(description: "Concurrent writes")
        expectation.expectedFulfillmentCount = 10

        var successCount = 0
        let lock = NSLock()

        for i in 0..<10 {
            queue.async {
                do {
                    var item = ClipboardItem(
                        content: "Concurrent item \(i)",
                        itemType: .text
                    )
                    try self.dbService.save(item)
                    lock.lock()
                    successCount += 1
                    lock.unlock()
                    expectation.fulfill()
                } catch {
                    XCTFail("并发写入失败：\(error)")
                }
            }
        }

        waitForExpectations(timeout: 10.0)
        XCTAssertEqual(successCount, 10, "所有并发写入都应该成功")

        // 验证所有记录都存在
        let all = try dbService.fetchRecent(limit: 100)
        XCTAssertEqual(all.count, 10, "应该能获取所有 10 条记录")
    }

    // Test: 搜索功能
    func testSearch() throws {
        try dbService.save(ClipboardItem(content: "Hello world", itemType: .text))
        try dbService.save(ClipboardItem(content: "Swift programming", itemType: .text))
        try dbService.save(ClipboardItem(content: "Hello Swift", itemType: .text))

        let results = try dbService.search(query: "Swift")
        XCTAssertEqual(results.count, 2, "应该找到 2 条包含 'Swift' 的记录")
    }

    // Test: 收藏功能
    func testFavoriteToggle() throws {
        var item = ClipboardItem(content: "Favorite test", itemType: .text)
        try dbService.save(item)

        let fetched = try dbService.fetchRecent(limit: 1).first!
        try dbService.toggleFavorite(id: fetched.id!, isFavorite: true)

        let updated = try dbService.fetchRecent(limit: 1).first!
        XCTAssertTrue(updated.isFavorite, "收藏状态应该被设置为 true")
    }
}
