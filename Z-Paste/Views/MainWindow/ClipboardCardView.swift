import SwiftUI

struct ClipboardCardView: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let isBatchSelected: Bool
    let onTap: (() -> Void)?
    let onCopy: (() -> Void)?
    let onToggleFavorite: (() -> Void)?
    let onDelete: (() -> Void)?
    let onContextMenuStateChanged: ((Bool) -> Void)?

    init(
        item: ClipboardItem,
        isSelected: Bool = false,
        isMultiSelectMode: Bool = false,
        isBatchSelected: Bool = false,
        onTap: (() -> Void)? = nil,
        onCopy: (() -> Void)? = nil,
        onToggleFavorite: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onContextMenuStateChanged: ((Bool) -> Void)? = nil
    ) {
        self.item = item
        self.isSelected = isSelected
        self.isMultiSelectMode = isMultiSelectMode
        self.isBatchSelected = isBatchSelected
        self.onTap = onTap
        self.onCopy = onCopy
        self.onToggleFavorite = onToggleFavorite
        self.onDelete = onDelete
        self.onContextMenuStateChanged = onContextMenuStateChanged
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            contentView
                .frame(maxHeight: .infinity)
            footerView
        }
        .frame(width: 250, height: 250)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(cardOverlay)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            onTap?()
        }
        .contextMenu {
            Button("复制") {
                onContextMenuStateChanged?(false)
                onCopy?()
            }

            Button(item.isFavorite ? "取消收藏" : "收藏") {
                onContextMenuStateChanged?(false)
                onToggleFavorite?()
            }

            Button("删除", role: .destructive) {
                onContextMenuStateChanged?(false)
                onDelete?()
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
            onContextMenuStateChanged?(isPressing)
        }, perform: {})
    }

    private var cardOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(borderColor, lineWidth: 2)
            .overlay(alignment: .topTrailing) {
                if isMultiSelectMode {
                    Image(systemName: isBatchSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isBatchSelected ? .accentColor : .secondary.opacity(0.7))
                        .padding(10)
                }
            }
    }

    private var borderColor: Color {
        if isBatchSelected {
            return .accentColor
        }

        return isSelected ? .accentColor : .clear
    }

    private var headerView: some View {
        HStack {
            Text(typeLabel)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if item.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding(8)
    }

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

    private var footerView: some View {
        HStack(spacing: 4) {
            if let iconData = item.sourceAppIcon,
               let nsImage = NSImage(data: iconData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: 16, height: 16)
            }

            Text(item.createdAt.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            Text(contentSize)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
    }

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
            let firstPath = item.content.split(separator: "\n").first.map(String.init) ?? item.content
            let url = URL(fileURLWithPath: firstPath)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
            return "未知大小"
        }
    }
}
