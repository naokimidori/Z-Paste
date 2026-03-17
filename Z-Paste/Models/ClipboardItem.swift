import Foundation
import CryptoKit

/// 剪贴板项类型枚举
enum ItemType: String, Codable, CaseIterable {
    case text  // 纯文本
    case image // 图片
    case file  // 文件
    case rtf   // 富文本
}

/// 剪贴板记录数据模型
struct ClipboardItem: Codable, Identifiable, Equatable, Hashable {
    /// 数据库主键
    var id: Int64?

    /// 文本内容或文件路径
    var content: String

    /// 剪贴板类型
    var itemType: ItemType

    /// 来源应用 BundleID
    var sourceApp: String?

    /// 来源应用图标数据
    var sourceAppIcon: Data?

    /// 创建时间
    var createdAt: Date

    /// 是否收藏
    var isFavorite: Bool

    /// 二进制数据 (如图片数据)
    var data: Data?

    /// 自定义构造器
    init(
        id: Int64? = nil,
        content: String,
        itemType: ItemType,
        sourceApp: String? = nil,
        sourceAppIcon: Data? = nil,
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        data: Data? = nil
    ) {
        self.id = id
        self.content = content
        self.itemType = itemType
        self.sourceApp = sourceApp
        self.sourceAppIcon = sourceAppIcon
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.data = data
    }

    /// 内容哈希值，用于去重判断
    var contentHash: String {
        let combined = "\(content):\(itemType.rawValue):\(data?.base64EncodedString() ?? "")"
        return combined.sha256()
    }
}

// MARK: - String Extension for SHA256
extension String {
    func sha256() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
