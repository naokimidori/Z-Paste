import SwiftUI

struct FilePreview: View {
    let content: String  // 文件路径

    var body: some View {
        VStack(spacing: 8) {
            // 文件图标
            Image(systemName: fileIcon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            // 文件名
            Text(fileName)
                .font(.caption)
                .lineLimit(2)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fileName: String {
        URL(fileURLWithPath: content).lastPathComponent
    }

    private var fileIcon: String {
        let ext = URL(fileURLWithPath: content).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.text.fill"
        case "doc", "docx": return "doc.fill"
        case "xls", "xlsx": return "chart.bar.fill"
        case "zip", "rar": return "doc.zipper"
        default: return "doc.fill"
        }
    }
}
