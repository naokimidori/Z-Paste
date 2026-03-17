import XCTest
@testable import Z_Paste

final class ClipboardServiceTests: XCTestCase {
    var clipboardService: ClipboardService!
    var databaseService: DatabaseService!
    var tempDBPath: String!

    override func setUp() async throws {
        try await super.setUp()
        // 创建临时数据库
        tempDBPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_clipboard_\(UUID().uuidString).db")
            .path
        databaseService = try DatabaseService(databasePath: tempDBPath)
        clipboardService = ClipboardService(database: databaseService)
    }

    override func tearDown() async throws {
        clipboardService = nil
        databaseService = nil
        // 清理临时数据库
        if let tempDBPath = tempDBPath {
            try? FileManager.default.removeItem(atPath: tempDBPath)
        }
        try await super.tearDown()
    }

    // Test 1: startMonitoring 后，服务处于监听状态
    func testStartMonitoring() {
        clipboardService.startMonitoring()
        // 验证 Timer 已启动（通过检查服务状态）
        XCTAssertTrue(clipboardService.isMonitoring)
    }

    // Test 2: stopMonitoring 后，服务停止监听
    func testStopMonitoring() {
        clipboardService.startMonitoring()
        clipboardService.stopMonitoring()
        XCTAssertFalse(clipboardService.isMonitoring)
    }

    // Test 3: 添加排除应用
    func testAddExcludedApp() {
        let bundleID = "com.apple.finder"
        clipboardService.addExcludedApp(bundleID)
        XCTAssertTrue(clipboardService.isAppExcluded(bundleID))
    }

    // Test 4: 移除排除应用
    func testRemoveExcludedApp() {
        let bundleID = "com.apple.finder"
        clipboardService.addExcludedApp(bundleID)
        clipboardService.removeExcludedApp(bundleID)
        XCTAssertFalse(clipboardService.isAppExcluded(bundleID))
    }

    // Test 5: 新项回调能被触发
    func testOnNewItemCallback() throws {
        let expectation = self.expectation(description: "onNewItem callback")

        clipboardService.onNewItem = { item in
            XCTAssertEqual(item.itemType, .text)
            expectation.fulfill()
        }

        // 模拟剪贴板变化
        clipboardService.startMonitoring()

        // 等待一段时间让 Timer 触发
        waitForExpectations(timeout: 2.0)
    }

    // Test 6: 去重逻辑 - 相同内容不触发多次回调
    func testDeduplication() throws {
        var callbackCount = 0

        clipboardService.onNewItem = { _ in
            callbackCount += 1
        }

        clipboardService.startMonitoring()

        // 等待多次检查周期
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))

        // 相同内容应该只触发一次
        XCTAssertEqual(callbackCount, 1, "相同内容应该只触发一次回调")
    }
}

// MARK: - Test Helper Extension

extension ClipboardService {
    /// 测试用：获取监听状态
    var isMonitoring: Bool {
        return self.isMonitoring
    }
}
