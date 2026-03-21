import Foundation
import GRDB

// Search filter model is defined in Models/ClipboardSearchFilter.swift

/// 剪贴板数据库服务
/// 负责剪贴板记录的持久化存储和检索
class DatabaseService {
    /// 数据库队列，线程安全
    private let dbQueue: DatabaseQueue

    /// 初始化数据库服务
    /// - Parameter databasePath: 数据库文件路径
    init(databasePath: String) throws {
        self.dbQueue = try DatabaseQueue(path: databasePath)
        try createTables()
    }

    // MARK: - Table Management

    /// 创建数据库表结构
    private func createTables() throws {
        try dbQueue.write { db in
            try ClipboardItem.createTable(db: db)
        }
    }

    /// 检查表是否存在（用于测试）
    func tableExists(_ tableName: String) throws -> Bool {
        return try dbQueue.read { db in
            try db.tableExists(tableName)
        }
    }

    // MARK: - CRUD Operations

    /// 保存剪贴板记录
    /// - Parameter item: 剪贴板项
    func save(_ item: ClipboardItem) throws {
        try dbQueue.write { db in
            try item.insert(db)
        }
    }

    /// 获取最近的剪贴板记录
    /// - Parameter limit: 返回数量限制
    /// - Returns: 剪贴板项数组，按创建时间倒序
    func fetchRecent(limit: Int) throws -> [ClipboardItem] {
        return try dbQueue.read { db in
            try ClipboardItem
                .order(Column("created_at").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    /// 获取匹配查询与筛选条件的剪贴板记录
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - filter: 互斥筛选条件
    ///   - limit: 返回数量限制
    /// - Returns: 匹配的剪贴板项数组，保持创建时间倒序
    func fetchMatchingItems(query: String, filter: ClipboardSearchFilter, limit: Int = 100) throws -> [ClipboardItem] {
        let recentItems = try fetchRecent(limit: limit)
        return recentItems.filter { item in
            filter.matches(item: item, query: query)
        }
    }

    /// 删除剪贴板记录
    /// - Parameter item: 剪贴板项
    func delete(_ item: ClipboardItem) throws {
        guard let id = item.id else { return }
        try delete(id: id)
    }

    /// 按 ID 删除剪贴板记录
    /// - Parameter id: 记录 ID
    func delete(id: Int64) throws {
        try dbQueue.write { db in
            try ClipboardItem.deleteOne(db, key: id)
        }
    }

    /// 切换收藏状态
    /// - Parameters:
    ///   - id: 记录 ID
    ///   - isFavorite: 是否收藏
    func toggleFavorite(id: Int64, isFavorite: Bool) throws {
        try dbQueue.write { db in
            if var item = try ClipboardItem.fetchOne(db, key: id) {
                item.isFavorite = isFavorite
                try item.update(db)
            }
        }
    }

    /// 搜索剪贴板记录
    /// - Parameter query: 搜索关键词
    /// - Returns: 匹配的剪贴板项数组
    func search(query: String) throws -> [ClipboardItem] {
        return try dbQueue.read { db in
            try ClipboardItem
                .filter(Column("content").like("%\(query)%"))
                .order(Column("created_at").desc)
                .fetchAll(db)
        }
    }

    /// 清理超出限制的记录
    /// - Parameter limit: 保留的最大记录数（不包括收藏项）
    func cleanup(limit: Int) throws {
        try dbQueue.write { db in
            // 获取所有非收藏记录，按时间倒序
            let nonFavoriteItems = try ClipboardItem
                .filter(Column("is_favorite") == false)
                .order(Column("created_at").desc)
                .fetchAll(db)

            // 如果超出限制，删除多余的
            if nonFavoriteItems.count > limit {
                let itemsToDelete = Array(nonFavoriteItems.suffix(from: limit))
                for item in itemsToDelete {
                    if let id = item.id {
                        try ClipboardItem.deleteOne(db, key: id)
                    }
                }
            }
        }
    }

    /// 获取所有收藏项
    /// - Returns: 收藏的剪贴板项数组
    func fetchFavorites() throws -> [ClipboardItem] {
        return try dbQueue.read { db in
            try ClipboardItem
                .filter(Column("is_favorite") == true)
                .order(Column("created_at").desc)
                .fetchAll(db)
        }
    }

    /// 获取记录总数
    /// - Returns: 数据库中的记录总数
    func count() throws -> Int {
        return try dbQueue.read { db in
            try ClipboardItem.fetchCount(db)
        }
    }

    /// 获取非收藏记录数量
    /// - Returns: 非收藏记录数量
    func nonFavoriteCount() throws -> Int {
        return try dbQueue.read { db in
            try ClipboardItem
                .filter(Column("is_favorite") == false)
                .fetchCount(db)
        }
    }
}
