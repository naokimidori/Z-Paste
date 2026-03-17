import SwiftUI

struct ImagePreview: View {
    let imageData: Data?

    var body: some View {
        if let data = imageData,
           let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
        }
    }
}
