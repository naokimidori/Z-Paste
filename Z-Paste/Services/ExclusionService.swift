import Foundation
import AppKit

/// 应用排除服务
/// 允许用户配置排除应用列表，这些应用中的剪贴板内容不会被记录
class ExclusionService {
    /// UserDefaults 存储键
    private let defaults = UserDefaults.standard
    private let exclusionKey = "excludedApps"

    /// 默认排除的应用列表
    private let defaultExcludedApps: Set<String> = [
        "com.apple.finder",                    // Finder
        "com.1password.1password",             // 1Password
        "com.1password.1password.alpha",       // 1Password Alpha
        "com.1password.1password.beta",        // 1Password Beta
        "com.apple.keychain",                  // Keychain 访问
        "com.apple.Keychain-Access",           // Keychain Access
        "com.agilebits.onepassword-osx",       // 1Password (旧版本)
        "com.dashlane.dashlaneapp",            // Dashlane
        "com.lastpass.lastpass",               // LastPass
        "com.bitwarden.desktop",               // Bitwarden
        "com.nordvpn.macos",                   // NordVPN
        "com.google.Chrome",                   // Chrome (可选，防止敏感信息)
    ]

    /// 排除的应用列表（计算属性，读写 UserDefaults）
    var excludedApps: Set<String> {
        get {
            let stored = defaults.object(forKey: exclusionKey) as? Set<String> ?? defaultExcludedApps
            return stored
        }
        set {
            defaults.set(newValue, forKey: exclusionKey)
            defaults.synchronize()
        }
    }

    /// 初始化 - 读取或创建默认排除列表
    init() {
        // 确保 UserDefaults 中有默认值
        if defaults.object(forKey: exclusionKey) == nil {
            excludedApps = defaultExcludedApps
        }
    }

    // MARK: - Public Methods

    /// 检查当前前台应用是否被排除
    /// - Returns: 如果当前应用被排除返回 true，否则返回 false
    func isExcluded() -> Bool {
        guard let bundleID = getCurrentAppBundleID() else {
            // 无法获取 bundleID 时，不排除（允许捕获）
            return false
        }
        return excludedApps.contains(bundleID)
    }

    /// 添加排除应用
    /// - Parameter bundleID: 应用 Bundle ID
    func add(bundleID: String) {
        var apps = excludedApps
        apps.insert(bundleID)
        excludedApps = apps
        print("ExclusionService: 已添加排除应用 '\(bundleID)'")
    }

    /// 移除排除应用
    /// - Parameter bundleID: 应用 Bundle ID
    func remove(bundleID: String) {
        var apps = excludedApps
        apps.remove(bundleID)
        excludedApps = apps
        print("ExclusionService: 已移除排除应用 '\(bundleID)'")
    }

    /// 获取当前前台应用的 Bundle ID
    /// - Returns: 前台应用的 Bundle ID，无法获取时返回 nil
    func getCurrentAppBundleID() -> String? {
        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    /// 获取当前前台应用名称
    /// - Returns: 前台应用名称，无法获取时返回 nil
    func getCurrentAppName() -> String? {
        return NSWorkspace.shared.frontmostApplication?.localizedName
    }

    /// 重置为默认排除列表
    func resetToDefaults() {
        excludedApps = defaultExcludedApps
        print("ExclusionService: 已重置为默认排除列表")
    }

    /// 检查特定 Bundle ID 是否在排除列表中
    /// - Parameter bundleID: 应用 Bundle ID
    /// - Returns: 是否在排除列表中
    func isBundleIDExcluded(_ bundleID: String) -> Bool {
        return excludedApps.contains(bundleID)
    }

    /// 获取所有排除的应用列表
    /// - Returns: 排除的应用 Bundle ID 集合
    func getAllExcludedApps() -> Set<String> {
        return excludedApps
    }
}
