import SwiftUI

struct TextPreview: View {
    let content: String

    var body: some View {
        Text(content)
            .font(.body)
            .lineLimit(4)  // 多行预览，最多4行
            .truncationMode(.tail)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 16)
    }
}
