import Foundation
import AppKit
import ApplicationServices

extension Notification.Name {
    static let clipboardItemsDidChange = Notification.Name("clipboardItemsDidChange")
}

protocol PasteboardWriting: AnyObject {
    var changeCount: Int { get }
    func clearContents()
    @discardableResult func setString(_ string: String, forType type: NSPasteboard.PasteboardType) -> Bool
    @discardableResult func setData(_ data: Data, forType type: NSPasteboard.PasteboardType) -> Bool
    @discardableResult func writeObjects(_ objects: [NSPasteboardWriting]) -> Bool
    func types() -> [NSPasteboard.PasteboardType]
    func string(forType type: NSPasteboard.PasteboardType) -> String?
    func data(forType type: NSPasteboard.PasteboardType) -> Data?
    func propertyList(forType type: NSPasteboard.PasteboardType) -> Any?
}

protocol AccessibilityTrustChecking {
    func isTrusted() -> Bool
}

protocol PasteEventSending {
    func sendCommandV()
}

final class SystemPasteboardWriter: PasteboardWriting {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    var changeCount: Int { pasteboard.changeCount }

    func clearContents() {
        pasteboard.clearContents()
    }

    @discardableResult
    func setString(_ string: String, forType type: NSPasteboard.PasteboardType) -> Bool {
        pasteboard.setString(string, forType: type)
    }

    @discardableResult
    func setData(_ data: Data, forType type: NSPasteboard.PasteboardType) -> Bool {
        pasteboard.setData(data, forType: type)
    }

    @discardableResult
    func writeObjects(_ objects: [NSPasteboardWriting]) -> Bool {
        pasteboard.writeObjects(objects)
    }

    func types() -> [NSPasteboard.PasteboardType] {
        pasteboard.types ?? []
    }

    func string(forType type: NSPasteboard.PasteboardType) -> String? {
        pasteboard.string(forType: type)
    }

    func data(forType type: NSPasteboard.PasteboardType) -> Data? {
        pasteboard.data(forType: type)
    }

    func propertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        pasteboard.propertyList(forType: type)
    }
}

struct SystemAccessibilityTrustChecker: AccessibilityTrustChecking {
    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }
}

struct SystemPasteEventSender: PasteEventSending {
    func sendCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

/// 剪贴板监听服务
/// 负责监听系统剪贴板变化，提取内容并保存
class ClipboardService {
    private let database: DatabaseService
    private let exclusionService = ExclusionService()
    private let pasteboardWriter: PasteboardWriting
    private let accessibilityChecker: AccessibilityTrustChecking
    private let pasteEventSender: PasteEventSending

    private var isMonitoring: Bool = false
    private var lastContentHash: String?
    private var lastChangeCount: Int?
    private var pendingSelfWriteChangeCount: Int?
    private var appIconCache: [String: Data] = [:]
    private var checkTimer: Timer?

    private static let maxImageBytes = 5 * 1024 * 1024
    private static let maxThumbnailDimension: CGFloat = 512

    var onNewItem: ((ClipboardItem) -> Void)?

    init(
        database: DatabaseService,
        pasteboardWriter: PasteboardWriting = SystemPasteboardWriter(),
        accessibilityChecker: AccessibilityTrustChecking = SystemAccessibilityTrustChecker(),
        pasteEventSender: PasteEventSending = SystemPasteEventSender()
    ) {
        self.database = database
        self.pasteboardWriter = pasteboardWriter
        self.accessibilityChecker = accessibilityChecker
        self.pasteEventSender = pasteEventSender
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        lastContentHash = nil
        lastChangeCount = pasteboardWriter.changeCount
        startTimerPolling()

        print("ClipboardService: 开始监听剪贴板")
    }

    func stopMonitoring() {
        isMonitoring = false
        checkTimer?.invalidate()
        checkTimer = nil

        print("ClipboardService: 停止监听剪贴板")
    }

    func writeItemToPasteboard(_ item: ClipboardItem) throws {
        pasteboardWriter.clearContents()

        switch item.itemType {
        case .text:
            guard pasteboardWriter.setString(item.content, forType: .string) else {
                throw ClipboardActionError.writeFailed(item.itemType)
            }
        case .rtf:
            guard let data = item.data else {
                throw ClipboardActionError.missingData(item.itemType)
            }
            guard pasteboardWriter.setData(data, forType: .rtf),
                  pasteboardWriter.setString(item.content, forType: .string) else {
                throw ClipboardActionError.writeFailed(item.itemType)
            }
        case .image:
            guard let data = item.data else {
                throw ClipboardActionError.missingData(item.itemType)
            }
            if !pasteboardWriter.setData(data, forType: .png) && !pasteboardWriter.setData(data, forType: .tiff) {
                throw ClipboardActionError.writeFailed(item.itemType)
            }
        case .file:
            let objects = item.content
                .split(separator: "\n")
                .map(String.init)
                .filter { !$0.isEmpty }
                .map { URL(fileURLWithPath: $0) as NSPasteboardWriting }

            guard !objects.isEmpty, pasteboardWriter.writeObjects(objects) else {
                throw ClipboardActionError.writeFailed(item.itemType)
            }
        }

        markNextMonitorSaveToSkip()
    }

    func attemptPasteAfterWindowHide() -> PrimaryActionResult {
        guard accessibilityChecker.isTrusted() else {
            return .copiedOnly
        }

        pasteEventSender.sendCommandV()
        return .pasted
    }

    func performPrimaryAction(for item: ClipboardItem) -> PrimaryActionResult {
        do {
            try writeItemToPasteboard(item)
            return accessibilityChecker.isTrusted() ? .pasted : .copiedOnly
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    @discardableResult
    func consumePendingSelfWriteSuppression(changeCount: Int) -> Bool {
        guard pendingSelfWriteChangeCount == changeCount else {
            return false
        }

        pendingSelfWriteChangeCount = nil
        lastChangeCount = changeCount
        return true
    }

    private func startTimerPolling() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        RunLoop.current.add(checkTimer!, forMode: .common)
    }

    private func checkClipboard() {
        guard isMonitoring else { return }

        let changeCount = pasteboardWriter.changeCount
        guard lastChangeCount != changeCount else { return }

        if consumePendingSelfWriteSuppression(changeCount: changeCount) {
            return
        }

        lastChangeCount = changeCount

        if exclusionService.isExcluded() {
            if let bundleID = exclusionService.getCurrentAppBundleID() {
                print("ClipboardService: 跳过排除应用的剪贴板 - \(bundleID)")
            }
            return
        }

        guard let item = extractContent() else { return }

        if let lastHash = lastContentHash, lastHash == item.contentHash {
            return
        }

        lastContentHash = item.contentHash

        do {
            try database.save(item)
            print("ClipboardService: 保存新记录 - \(item.itemType.rawValue), \(item.content.prefix(50))...")
            onNewItem?(item)
            NotificationCenter.default.post(name: .clipboardItemsDidChange, object: nil)
        } catch {
            print("ClipboardService: 保存失败 - \(error)")
        }
    }

    private func markNextMonitorSaveToSkip() {
        pendingSelfWriteChangeCount = pasteboardWriter.changeCount
    }

    private func extractContent() -> ClipboardItem? {
        let types = pasteboardWriter.types()
        let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let sourceAppIcon = getSourceAppIcon(bundleID: sourceApp)

        if types.contains(.string), let string = pasteboardWriter.string(forType: .string) {
            if types.contains(.rtf), let rtfData = pasteboardWriter.data(forType: .rtf) {
                return ClipboardItem(
                    content: string,
                    itemType: .rtf,
                    sourceApp: sourceApp,
                    sourceAppIcon: sourceAppIcon,
                    data: rtfData
                )
            }
            return ClipboardItem(
                content: string,
                itemType: .text,
                sourceApp: sourceApp,
                sourceAppIcon: sourceAppIcon
            )
        }

        if types.contains(.png), let imageData = pasteboardWriter.data(forType: .png) {
            return makeImageItem(from: imageData, sourceApp: sourceApp, sourceAppIcon: sourceAppIcon)
        }

        if types.contains(.tiff), let tiffData = pasteboardWriter.data(forType: .tiff) {
            return makeImageItem(from: tiffData, sourceApp: sourceApp, sourceAppIcon: sourceAppIcon)
        }

        if types.contains(.fileURL), let urls = pasteboardWriter.propertyList(forType: .fileURL) as? [String] {
            return ClipboardItem(
                content: urls.joined(separator: "\n"),
                itemType: .file,
                sourceApp: sourceApp,
                sourceAppIcon: sourceAppIcon
            )
        }

        return nil
    }

    private func makeImageItem(from data: Data, sourceApp: String?, sourceAppIcon: Data?) -> ClipboardItem? {
        let storedData = imageDataForStorage(data)
        return ClipboardItem(
            content: "Image",
            itemType: .image,
            sourceApp: sourceApp,
            sourceAppIcon: sourceAppIcon,
            data: storedData
        )
    }

    private func imageDataForStorage(_ data: Data) -> Data? {
        guard data.count > ClipboardService.maxImageBytes else {
            return data
        }

        guard let image = NSImage(data: data) else {
            return data
        }

        guard let thumbnail = makeThumbnail(from: image) else {
            return data
        }

        guard let tiffData = thumbnail.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return data
        }

        return pngData
    }

    private func makeThumbnail(from image: NSImage) -> NSImage? {
        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else {
            return nil
        }

        let maxDimension = ClipboardService.maxThumbnailDimension
        let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height, 1)
        let targetSize = NSSize(width: originalSize.width * scale, height: originalSize.height * scale)

        let thumbnail = NSImage(size: targetSize)
        thumbnail.lockFocus()
        defer { thumbnail.unlockFocus() }

        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: NSRect(origin: .zero, size: originalSize),
                   operation: .copy,
                   fraction: 1)
        return thumbnail
    }

    private func getSourceAppIcon(bundleID: String?) -> Data? {
        guard let bundleID else {
            return nil
        }

        if let cachedIcon = appIconCache[bundleID] {
            return cachedIcon
        }

        guard let appURL = NSWorkspace.shared.frontmostApplication?.bundleURL else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: appURL.path)

        guard let tiffData = icon.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        appIconCache[bundleID] = pngData
        return pngData
    }
}

enum ClipboardActionError: LocalizedError {
    case writeFailed(ItemType)
    case missingData(ItemType)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let type):
            return "无法写回 \(type.rawValue) 到系统剪贴板"
        case .missingData(let type):
            return "缺少 \(type.rawValue) 所需的二进制数据"
        }
    }
}
