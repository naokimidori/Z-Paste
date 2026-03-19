import Foundation
import GRDB

// MARK: - TableRecord
extension ClipboardItem: TableRecord {
    /// 数据库表名
    static let databaseTableName = "clipboard_items"

    /// 列名映射
    enum Columns: String, ColumnExpression {
        case id
        case content
        case itemType = "item_type"
        case sourceApp = "source_app"
        case sourceAppIcon = "source_app_icon"
        case createdAt = "created_at"
        case isFavorite = "is_favorite"
        case data
    }
}

// MARK: - FetchableRecord
extension ClipboardItem: FetchableRecord {
    /// 从数据库行读取
    init(row: Row) throws {
        id = row["id"]
        content = row["content"]
        let itemTypeRaw: String = row["item_type"]
        itemType = ItemType(rawValue: itemTypeRaw) ?? .text
        sourceApp = row["source_app"]
        sourceAppIcon = row["source_app_icon"]
        createdAt = row["created_at"]
        isFavorite = row["is_favorite"]
        data = row["data"]
    }
}

// MARK: - PersistableRecord
extension ClipboardItem: PersistableRecord {
    /// 编码到数据库
    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.content] = content
        container[Columns.itemType] = itemType.rawValue
        container[Columns.sourceApp] = sourceApp
        container[Columns.sourceAppIcon] = sourceAppIcon
        container[Columns.createdAt] = createdAt
        container[Columns.isFavorite] = isFavorite
        container[Columns.data] = data
    }

    /// 保存后回调
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Database Schema
extension ClipboardItem {
    /// 创建数据库表
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("content", .text).notNull()
            t.column("item_type", .text).notNull()
            t.column("source_app", .text)
            t.column("source_app_icon", .blob)
            t.column("created_at", .datetime).notNull().defaults(to: Date())
            t.column("is_favorite", .boolean).notNull().defaults(to: false)
            t.column("data", .blob)
        }

        // 创建索引
        try db.create(index: "idx_clipboard_items_created_at",
                      on: databaseTableName,
                      columns: ["created_at"],
                      ifNotExists: true)

        try db.create(index: "idx_clipboard_items_is_favorite",
                      on: databaseTableName,
                      columns: ["is_favorite"],
                      ifNotExists: true)

        try db.create(index: "idx_clipboard_items_item_type",
                      on: databaseTableName,
                      columns: ["item_type"],
                      ifNotExists: true)
    }

    /// 删除表
    static func dropTable(db: Database) throws {
        try db.drop(table: databaseTableName)
    }
}
