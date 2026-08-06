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
    static let enableActiveDeviceDetection = text(
        "启用“当前活动设备检测”",
        "Enable Active Device Detection"
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
    static let activeDeviceDetectionSettings = text(
        "当前活动设备检测",
        "Active Device Detection"
    )
    static let activeDeviceDetectionSummary = text(
        "选择鼠标通过 Flow 离开当前设备时允许触发遮罩的桌面外侧边缘。",
        "Choose which outer desktop edges may trigger the overlay when "
            + "the pointer leaves this Mac through Flow."
    )
    static let triggerEdges = text("触发边缘", "Trigger Edges")
    static let leftEdge = text("左", "Left")
    static let rightEdge = text("右", "Right")
    static let topEdge = text("上", "Top")
    static let bottomEdge = text("下", "Bottom")

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
            + "所有显示器都会显示醒目的毛玻璃遮罩；鼠标连回时会提示位置。",
        "Make Logitech Flow handoffs visible. When the pointer leaves, "
            + "a prominent glass overlay appears on every display; when it "
            + "reconnects, a location alert reveals the pointer."
    )
    static let mainClosingNote = text(
        "关闭此窗口后应用仍会继续运行。你可以通过 Dock 或菜单栏图标"
            + "随时重新打开主界面。",
        "Closing this window keeps monitoring active. Reopen it anytime "
            + "from the Dock or menu bar."
    )
    static let overlaySettings = text("蒙层设置", "Overlay Settings")
    static let overlayTransparency = text(
        "蒙层透明度",
        "Overlay Transparency"
    )
    static let overlayTransparencyHelp = text(
        "仅调整深色蒙层，不改变系统毛玻璃",
        "Adjusts only the dark tint, without changing the system glass"
    )
    static let glassIntensity = text(
        "毛玻璃强度",
        "Glass Effect"
    )
    static let glassIntensityHelp = text(
        "按视觉响应非线性调整；50% 对应约 92% 系统毛玻璃",
        "Nonlinear visual response; 50% maps to about 92% system glass"
    )
    static let overlayMessage = text("蒙层文字", "Overlay Message")
    static let overlayMessagePlaceholder = text(
        "输入鼠标离开时显示的文字",
        "Enter the message shown when the pointer leaves"
    )
    static let resetDefaultMessage = text(
        "恢复默认文字",
        "Reset Default Message"
    )
    static let reconnectAlertSettings = text(
        "鼠标连回位置提醒",
        "Mouse Reconnect Location Alert"
    )
    static let reconnectAlertSummary = text(
        "鼠标连回当前设备时，短暂调暗所有屏幕，并用跟随指针的圆形亮区"
            + "帮助定位。",
        "When the pointer reconnects to this Mac, briefly dim every display "
            + "and reveal a circular highlight that follows the pointer."
    )
    static let enableReconnectAlert = text(
        "启用“鼠标连回位置提醒”",
        "Enable Mouse Reconnect Location Alert"
    )
    static let reconnectDimOpacity = text(
        "变暗程度",
        "Screen Dimming"
    )
    static let reconnectDuration = text(
        "持续时间",
        "Alert Duration"
    )
    static let reconnectRadius = text(
        "聚光半径",
        "Spotlight Radius"
    )
    static let reconnectFeather = text(
        "边缘羽化",
        "Edge Feathering"
    )
    static let reconnectSpotlightColor = text(
        "聚光颜色",
        "Spotlight Color"
    )
    static let reconnectDurationValueFormat = text("%.1f 秒", "%.1f s")
    static let previewReconnectAlert = text(
        "预览提醒",
        "Preview Alert"
    )
    static let dismissOverlay = text("关闭遮罩", "Dismiss Overlay")

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
