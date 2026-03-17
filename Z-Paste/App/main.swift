import AppKit

// 创建应用实例
let app = NSApplication.shared

// 设置代理
let delegate = AppDelegate()
app.delegate = delegate

// 启动应用
app.run()
