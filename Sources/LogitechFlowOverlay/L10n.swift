import Foundation

enum AppLanguage: Equatable {
    case chinese
    case english

    static func resolve(preferredLanguages: [String]) -> AppLanguage {
        guard let primary = preferredLanguages.first?.lowercased() else {
            return .english
        }
        return primary.hasPrefix("zh") ? .chinese : .english
    }
}

enum L10n {
    static let language = AppLanguage.resolve(
        preferredLanguages: Locale.preferredLanguages
    )

    static func text(_ chinese: String, _ english: String) -> String {
        language == .chinese ? chinese : english
    }

    static let openMainWindow = text("打开主界面", "Open Main Window")
    static let detectingStatus = text("状态：正在检测…", "Status: Detecting…")
    static let previewOverlay = text("预览遮罩", "Preview Overlay")
    static let enableEdgeDetection = text(
        "启用 Flow 边缘检测",
        "Enable Flow Edge Detection"
    )
    static let delaySecondsFormat = text("%.1f 秒", "%.1f seconds")
    static let triggerDelay = text("触发延迟", "Trigger Delay")
    static let openDiagnosticLog = text(
        "打开诊断日志",
        "Open Diagnostic Log"
    )
    static let quitApplication = text(
        "退出 Logitech Flow Overlay",
        "Quit Logitech Flow Overlay"
    )
    static let statusFormat = text("状态：%@", "Status: %@")

    static let flowAwayTitle = text(
        "Flow 已切换到另一台设备",
        "Flow switched to another device"
    )
    static let flowAwayDetail = text(
        "鼠标返回此 Mac 后，遮罩会立即消失。",
        "The overlay disappears as soon as the pointer returns to this Mac."
    )
    static let logitechMouse = text("Logitech 鼠标", "Logitech mouse")
    static func monitoringTitle(deviceName: String) -> String {
        text(
            "\(deviceName) · Flow 监测中",
            "\(deviceName) · Monitoring Flow"
        )
    }
    static let monitoringDetail = text(
        "应用正在监测桌面外侧边缘和 Logitech 鼠标输入。",
        "Monitoring outer desktop edges and Logitech pointer input."
    )
    static let waitingForOptionsTitle = text(
        "等待 Logi Options+",
        "Waiting for Logi Options+"
    )
    static let waitingForOptionsDetail = text(
        "请启动 Logi Options+ 并确认 Flow 已完成配置。",
        "Start Logi Options+ and confirm that Flow is configured."
    )
    static let waitingForMouseTitle = text(
        "等待 Logitech 鼠标",
        "Waiting for a Logitech mouse"
    )
    static let waitingForMouseDetail = text(
        "连接支持 Flow 的 Logitech 鼠标后会自动开始监测。",
        "Connect a Flow-compatible Logitech mouse to start monitoring."
    )

    static let mainInitialStatus = text("正在检测…", "Detecting…")
    static let mainInitialDetail = text(
        "正在检查 Logitech 鼠标和 Logi Options+。",
        "Checking for a Logitech mouse and Logi Options+."
    )
    static let mainSummary = text(
        "让 Logitech Flow 的跨设备切换状态清晰可见。鼠标离开时，"
            + "所有显示器都会显示醒目的毛玻璃遮罩。",
        "Make Logitech Flow handoffs visible. When the pointer leaves, "
            + "a prominent glass overlay appears on every display."
    )
    static let mainClosingNote = text(
        "关闭此窗口后应用仍会继续运行。你可以通过 Dock 或菜单栏图标"
            + "随时重新打开主界面。",
        "Closing this window keeps monitoring active. Reopen it anytime "
            + "from the Dock or menu bar."
    )

    static let overlayAccessibility = text("鼠标已离开", "Pointer left this Mac")
    static let overlayTitle = text(
        "鼠标已切换到另一台设备",
        "Pointer switched to another device"
    )
    static let overlaySubtitle = text(
        "Logitech Flow · 返回此设备后提示会自动消失",
        "Logitech Flow · This overlay disappears when the pointer returns"
    )
}
