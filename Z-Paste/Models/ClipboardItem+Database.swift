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
        case itemType
        case sourceApp
        case sourceAppIcon
        case createdAt
        case isFavorite
        case data
    }
}

// MARK: - FetchableRecord
extension ClipboardItem: FetchableRecord {
    /// 从数据库行读取
    init(row: Row) throws {
        id = row[Columns.id]
        content = row[Columns.content]
        itemType = try row.decode(Columns.itemType)
        sourceApp = row[Columns.sourceApp]
        sourceAppIcon = row[Columns.sourceAppIcon]
        createdAt = row[Columns.createdAt]
        isFavorite = row[Columns.isFavorite]
        data = row[Columns.data]
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
        try db.drop(table: databaseTableName, ifExists: true)
    }
}
