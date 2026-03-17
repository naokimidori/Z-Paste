import Foundation
import AppKit

/// 剪贴板监听服务
/// 负责监听系统剪贴板变化，提取内容并保存
class ClipboardService {
    /// 数据库服务
    private let database: DatabaseService

    /// 是否正在监听
    private var isMonitoring: Bool = false

    /// 上次内容的哈希值，用于去重
    private var lastContentHash: String?

    /// 定时检查剪贴板的 Timer
    private var checkTimer: Timer?

    /// 新项回调
    var onNewItem: ((ClipboardItem) -> Void)?

    /// 排除的应用列表
    var excludedApps: Set<String> = []

    /// 初始化剪贴板服务
    /// - Parameter database: 数据库服务实例
    init(database: DatabaseService) {
        self.database = database
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// 开始监听剪贴板
    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        lastContentHash = nil

        // 使用 Timer 轮询（macOS 命令行环境不支持 NSPasteboard.changedNotification）
        startTimerPolling()

        print("ClipboardService: 开始监听剪贴板")
    }

    /// 停止监听剪贴板
    func stopMonitoring() {
        isMonitoring = false

        // 停止 Timer
        checkTimer?.invalidate()
        checkTimer = nil

        print("ClipboardService: 停止监听剪贴板")
    }

    // MARK: - Private Methods

    /// 启动 Timer 轮询
    private func startTimerPolling() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        RunLoop.current.add(checkTimer!, forMode: .common)
    }

    /// 检查剪贴板变化
    private func checkClipboard() {
        guard isMonitoring else { return }

        // 检查是否来自排除的应用
        if let frontApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           excludedApps.contains(frontApp) {
            return
        }

        guard let item = extractContent() else { return }

        // 去重检查
        if let lastHash = lastContentHash, lastHash == item.contentHash {
            return
        }

        // 更新哈希值
        lastContentHash = item.contentHash

        // 保存数据库
        do {
            try database.save(item)
            print("ClipboardService: 保存新记录 - \(item.itemType.rawValue), \(item.content.prefix(50))...")

            // 触发回调
            onNewItem?(item)
        } catch {
            print("ClipboardService: 保存失败 - \(error)")
        }
    }

    /// 从剪贴板提取内容
    private func extractContent() -> ClipboardItem? {
        let pasteboard = NSPasteboard.general
        let types = pasteboard.types ?? []

        // 获取来源应用
        let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let sourceAppIcon = getSourceAppIcon()

        // 按优先级判断内容类型
        if types.contains(.string) {
            // 文本类型
            if let string = pasteboard.string(forType: .string) {
                // 检查是否为 RTF 数据
                if types.contains(.rtf), let rtfData = pasteboard.data(forType: .rtf) {
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
        }

        if types.contains(.png), let imageData = pasteboard.data(forType: .png) {
            return ClipboardItem(
                content: "Image",
                itemType: .image,
                sourceApp: sourceApp,
                sourceAppIcon: sourceAppIcon,
                data: imageData
            )
        }

        if types.contains(.tiff), let tiffData = pasteboard.data(forType: .tiff) {
            return ClipboardItem(
                content: "Image",
                itemType: .image,
                sourceApp: sourceApp,
                sourceAppIcon: sourceAppIcon,
                data: tiffData
            )
        }

        if types.contains(.fileURL), let urls = pasteboard.propertyList(forType: .fileURL) as? [String] {
            return ClipboardItem(
                content: urls.joined(separator: "\n"),
                itemType: .file,
                sourceApp: sourceApp,
                sourceAppIcon: sourceAppIcon
            )
        }

        return nil
    }

    /// 获取前台应用图标
    private func getSourceAppIcon() -> Data? {
        guard let appURL = NSWorkspace.shared.frontmostApplication?.bundleURL else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: appURL.path)

        // 将图标转换为 Data
        guard let tiffData = icon.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        // 转换为 PNG 格式以减小存储大小
        return bitmap.representation(using: .png, properties: [:])
    }

    // MARK: - App Exclusion

    /// 添加排除应用
    /// - Parameter bundleID: 应用 Bundle ID
    func addExcludedApp(_ bundleID: String) {
        excludedApps.insert(bundleID)
    }

    /// 移除排除应用
    /// - Parameter bundleID: 应用 Bundle ID
    func removeExcludedApp(_ bundleID: String) {
        excludedApps.remove(bundleID)
    }

    /// 检查应用是否被排除
    /// - Parameter bundleID: 应用 Bundle ID
    /// - Returns: 是否被排除
    func isAppExcluded(_ bundleID: String) -> Bool {
        return excludedApps.contains(bundleID)
    }
}
