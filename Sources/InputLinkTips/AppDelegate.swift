import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlay = OverlayController()
    private let deviceMonitor = LogitechDeviceMonitor()
    private var edgeDetector = FlowEdgeDetector(
        delay: UserDefaults.standard.object(forKey: "flowDelay") as? Double ?? 0.4
    )
    private var pollTimer: Timer?
    private var statusItem: NSStatusItem?
    private var statusMenuItem: NSMenuItem?
    private var edgeMenuItem: NSMenuItem?
    private var delayItems: [NSMenuItem] = []

    private var hasSeenLogitechPointer = false
    private var flowAway = false
    private var manualPreview = false
    private var connectedNames: [String] = []
    private var lastOptionsRunningState: Bool?

    private var edgeDetectionEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "edgeDetectionEnabled") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "edgeDetectionEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "edgeDetectionEnabled")
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        DiagnosticLog.write(
            "launch screens=\(NSScreen.screens.map { NSStringFromRect($0.frame) })"
        )
        configureStatusItem()
        configureDeviceMonitor()
        startCursorPolling()
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(runDiagnosticPreview),
            name: Notification.Name("io.github.leo4stone.InputLinkTips.preview"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        pollTimer?.invalidate()
        deviceMonitor.stop()
        DistributedNotificationCenter.default().removeObserver(self)
    }

    private func configureDeviceMonitor() {
        deviceMonitor.onChange = { [weak self] snapshot in
            DispatchQueue.main.async {
                self?.handleDeviceSnapshot(snapshot)
            }
        }
        deviceMonitor.onPointerInput = { [weak self] in
            DispatchQueue.main.async {
                self?.handleLogitechInput()
            }
        }
        deviceMonitor.start()
    }

    private func startCursorPolling() {
        pollTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 30.0,
            repeats: true
        ) { [weak self] _ in
            self?.sampleCursor()
        }
        if let pollTimer {
            RunLoop.main.add(pollTimer, forMode: .common)
        }
    }

    private func sampleCursor() {
        if FileManager.default.fileExists(atPath: DiagnosticLog.previewTriggerPath) {
            try? FileManager.default.removeItem(atPath: DiagnosticLog.previewTriggerPath)
            runDiagnosticPreview(Notification(
                name: Notification.Name("io.github.leo4stone.InputLinkTips.preview")
            ))
        }

        let optionsRunning = isLogiOptionsPlusRunning
        if optionsRunning != lastOptionsRunningState {
            lastOptionsRunningState = optionsRunning
            DiagnosticLog.write("optionsPlusRunning=\(optionsRunning)")
        }

        guard edgeDetectionEnabled,
              optionsRunning
        else {
            if flowAway {
                flowAway = false
                edgeDetector.reset()
                updatePresentation()
            }
            return
        }

        let screenFrames = NSScreen.screens.map(\.frame)
        let wasArmed = edgeDetector.isArmed
        let event = edgeDetector.observe(
            point: NSEvent.mouseLocation,
            screens: screenFrames,
            at: ProcessInfo.processInfo.systemUptime
        )
        if !wasArmed && edgeDetector.isArmed {
            DiagnosticLog.write(
                "flowCandidate point=\(NSStringFromPoint(NSEvent.mouseLocation))"
            )
        }

        switch event {
        case .leftComputer:
            DiagnosticLog.write("flowAway")
            flowAway = true
            updatePresentation()
        case .returned:
            DiagnosticLog.write("flowReturned")
            flowAway = false
            updatePresentation()
        case nil:
            break
        }
    }

    private func handleDeviceSnapshot(_ snapshot: LogitechDeviceMonitor.Snapshot) {
        connectedNames = snapshot.names
        DiagnosticLog.write(
            "hidPointers=\(snapshot.connectedPointerCount) names=\(snapshot.names)"
        )

        if snapshot.connectedPointerCount > 0 {
            hasSeenLogitechPointer = true
        }

        updateMenu()
    }

    private func handleLogitechInput() {
        guard flowAway else { return }
        flowAway = false
        edgeDetector.reset()
        updatePresentation()
    }

    private func updatePresentation() {
        let shouldShow = flowAway || manualPreview
        if shouldShow {
            overlay.show()
        } else {
            overlay.hide()
        }
        updateMenu()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "cursorarrow.motionlines",
            accessibilityDescription: "InputLinkTips"
        )

        let menu = NSMenu()
        let status = NSMenuItem(title: "状态：正在检测…", action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        statusMenuItem = status

        menu.addItem(.separator())

        let preview = NSMenuItem(
            title: "预览遮罩",
            action: #selector(togglePreview),
            keyEquivalent: ""
        )
        preview.target = self
        menu.addItem(preview)

        let edge = NSMenuItem(
            title: "启用 Flow 边缘检测",
            action: #selector(toggleEdgeDetection),
            keyEquivalent: ""
        )
        edge.target = self
        menu.addItem(edge)
        edgeMenuItem = edge

        let delayMenu = NSMenu()
        for value in [0.2, 0.4, 0.8] {
            let delayItem = NSMenuItem(
                title: String(format: "%.1f 秒", value),
                action: #selector(selectDelay(_:)),
                keyEquivalent: ""
            )
            delayItem.target = self
            delayItem.representedObject = value
            delayMenu.addItem(delayItem)
            delayItems.append(delayItem)
        }
        let delayRoot = NSMenuItem(title: "触发延迟", action: nil, keyEquivalent: "")
        delayRoot.submenu = delayMenu
        menu.addItem(delayRoot)

        let diagnostic = NSMenuItem(
            title: "打开诊断日志",
            action: #selector(openDiagnosticLog),
            keyEquivalent: ""
        )
        diagnostic.target = self
        menu.addItem(diagnostic)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "退出 InputLinkTips",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
        updateMenu()
    }

    private func updateMenu() {
        if flowAway {
            statusMenuItem?.title = "状态：Flow 已切换到另一台设备"
            statusItem?.button?.image = NSImage(
                systemSymbolName: "cursorarrow.slash",
                accessibilityDescription: "鼠标已离开"
            )
        } else if hasSeenLogitechPointer {
            let name = connectedNames.first ?? "Logitech 鼠标"
            if isLogiOptionsPlusRunning {
                statusMenuItem?.title = "状态：\(name) · Flow 监测中"
            } else {
                statusMenuItem?.title = "状态：等待 Logi Options+"
            }
            statusItem?.button?.image = NSImage(
                systemSymbolName: "cursorarrow.motionlines",
                accessibilityDescription: "鼠标已连接"
            )
        } else {
            statusMenuItem?.title = "状态：等待 Logitech 鼠标"
        }

        edgeMenuItem?.state = edgeDetectionEnabled ? .on : .off
        delayItems.forEach { item in
            guard let value = item.representedObject as? Double else { return }
            item.state = abs(value - edgeDetector.delay) < 0.01 ? .on : .off
        }
    }

    @objc private func togglePreview() {
        manualPreview.toggle()
        updatePresentation()

        if manualPreview {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self, self.manualPreview else { return }
                self.manualPreview = false
                self.updatePresentation()
            }
        }
    }

    @objc private func toggleEdgeDetection() {
        edgeDetectionEnabled.toggle()
        if !edgeDetectionEnabled {
            flowAway = false
            edgeDetector.reset()
            updatePresentation()
        }
        updateMenu()
    }

    @objc private func selectDelay(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        UserDefaults.standard.set(value, forKey: "flowDelay")
        edgeDetector.delay = value
        edgeDetector.reset()
        flowAway = false
        updatePresentation()
    }

    @objc private func quitApplication() {
        NSApp.terminate(nil)
    }

    @objc private func openDiagnosticLog() {
        NSWorkspace.shared.open(URL(fileURLWithPath: DiagnosticLog.path))
    }

    @objc private func runDiagnosticPreview(_ notification: Notification) {
        manualPreview = true
        updatePresentation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self else { return }
            self.manualPreview = false
            self.updatePresentation()
        }
    }

    private var isLogiOptionsPlusRunning: Bool {
        !NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.logi.optionsplus"
        ).isEmpty
    }
}
