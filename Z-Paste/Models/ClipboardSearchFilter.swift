import Foundation
import AppKit

enum ClipboardSearchFilter: String, CaseIterable, Equatable {
    case all, favorites, links, text, image, file

    var title: String {
        switch self {
        case .all:
            return "All"
        case .favorites:
            return "Favorites"
        case .links:
            return "Links"
        case .text:
            return "Text"
        case .image:
            return "Images"
        case .file:
            return "Files"
        }
    }

    func matches(item: ClipboardItem) -> Bool {
        switch self {
        case .all:
            return true
        case .favorites:
            return item.isFavorite
        case .links:
            guard item.itemType == .text || item.itemType == .rtf else { return false }
            return ClipboardSearchFilter.isSystemOpenableLink(item.content)
        case .text:
            return item.itemType == .text || item.itemType == .rtf
        case .image:
            return item.itemType == .image
        case .file:
            return item.itemType == .file
        }
    }

    func matches(item: ClipboardItem, query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard matches(item: item) else { return false }
        guard !trimmedQuery.isEmpty else { return true }

        switch item.itemType {
        case .text, .rtf:
            return item.content.localizedCaseInsensitiveContains(trimmedQuery)
        case .file:
            let firstPath = item.content.split(separator: "\n").first.map(String.init) ?? ""
            let filename = URL(fileURLWithPath: firstPath).lastPathComponent
            return filename.localizedCaseInsensitiveContains(trimmedQuery)
        case .image:
            return false
        }
    }

    static func isSystemOpenableLink(_ content: String) -> Bool {
        guard let url = URL(string: content) else { return false }
        return NSWorkspace.shared.urlForApplication(toOpen: url) != nil
    }
}
