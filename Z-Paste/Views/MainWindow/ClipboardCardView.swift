import SwiftUI

struct ClipboardCardView: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onTap: (() -> Void)?

    init(item: ClipboardItem, isSelected: Bool = false, onTap: (() -> Void)? = nil) {
        self.item = item
        self.isSelected = isSelected
        self.onTap = onTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: 类型标签 + 收藏标记
            headerView

            // Content: 内容预览
            contentView
                .frame(maxHeight: .infinity)

            // Footer: 来源图标 + 时间戳 + 大小
            footerView
        }
        .frame(width: 250, height: 250)  // 锁定尺寸
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap?()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            // 类型标签
            Text(typeLabel)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            // 收藏标记
            if item.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding(8)
    }

    // MARK: - Content
    @ViewBuilder
    private var contentView: some View {
        switch item.itemType {
        case .text, .rtf:
            TextPreview(content: item.content)
        case .image:
            ImagePreview(imageData: item.data)
        case .file:
            FilePreview(content: item.content)
        }
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack(spacing: 4) {
            // 来源应用图标
            if let iconData = item.sourceAppIcon,
               let nsImage = NSImage(data: iconData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: 16, height: 16)
            }

            // 时间戳
            Text(item.createdAt.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            // 内容大小
            Text(contentSize)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
    }

    // MARK: - Helpers
    private var typeLabel: String {
        switch item.itemType {
        case .text: return "文本"
        case .image: return "图片"
        case .file: return "文件"
        case .rtf: return "富文本"
        }
    }

    private var contentSize: String {
        switch item.itemType {
        case .text, .rtf:
            return "\(item.content.count) 字符"
        case .image:
            if let data = item.data {
                return ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
            }
            return "未知大小"
        case .file:
            // 尝试获取文件大小
            let url = URL(fileURLWithPath: item.content)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
            return "未知大小"
        }
    }
}
