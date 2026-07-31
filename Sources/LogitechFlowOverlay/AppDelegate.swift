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
    private var activeDeviceDetectionMenuItem: NSMenuItem?
    private var delayItems: [NSMenuItem] = []
    private var mainWindowController: MainWindowController?

    private var hasSeenLogitechPointer = false
    private var flowAway = false
    private var manualPreview = false
    private var settingsPreviewActive = false
    private var connectedNames: [String] = []
    private var lastOptionsRunningState: Bool?

    private var activeDeviceDetectionEnabled: Bool {
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

    private var savedOverlaySettings: OverlaySettings {
        let defaults = UserDefaults.standard
        let transparency = defaults.object(
            forKey: "overlayTransparency"
        ) as? Double ?? OverlaySettings.defaultTransparency
        let glassIntensity = defaults.object(
            forKey: "overlayGlassIntensity"
        ) as? Double ?? OverlaySettings.defaultGlassIntensity
        let message = defaults.string(
            forKey: "overlayMessage"
        ) ?? L10n.overlayTitle
        return OverlaySettings(
            transparency: transparency,
            glassIntensity: glassIntensity,
            message: message
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        overlay.updateSettings(savedOverlaySettings)
        overlay.onDismiss = { [weak self] in
            self?.dismissCurrentOverlay()
        }
        DiagnosticLog.write(
            "launch screens=\(NSScreen.screens.map { NSStringFromRect($0.frame) })"
        )
        configureStatusItem()
        configureMainWindow()
        configureDeviceMonitor()
        startCursorPolling()
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(runDiagnosticPreview),
            name: Notification.Name(
                "io.github.leo4stone.LogitechFlowOverlay.preview"
            ),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        mainWindowController?.present()
    }

    func applicationWillTerminate(_ notification: Notification) {
        pollTimer?.invalidate()
        deviceMonitor.stop()
        DistributedNotificationCenter.default().removeObserver(self)
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        mainWindowController?.present()
        return true
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
                name: Notification.Name(
                    "io.github.leo4stone.LogitechFlowOverlay.preview"
                )
            ))
        }

        let optionsRunning = isLogiOptionsPlusRunning
        if optionsRunning != lastOptionsRunningState {
            lastOptionsRunningState = optionsRunning
            DiagnosticLog.write("optionsPlusRunning=\(optionsRunning)")
        }

        guard activeDeviceDetectionEnabled,
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
        let shouldShow = flowAway || manualPreview || settingsPreviewActive
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
            accessibilityDescription: "Logitech Flow Overlay"
        )

        let menu = NSMenu()
        let openWindow = NSMenuItem(
            title: L10n.openMainWindow,
            action: #selector(showMainWindow),
            keyEquivalent: ""
        )
        openWindow.target = self
        menu.addItem(openWindow)
        menu.addItem(.separator())

        let status = NSMenuItem(
            title: L10n.detectingStatus,
            action: nil,
            keyEquivalent: ""
        )
        status.isEnabled = false
        menu.addItem(status)
        statusMenuItem = status

        menu.addItem(.separator())

        let preview = NSMenuItem(
            title: L10n.previewOverlay,
            action: #selector(togglePreview),
            keyEquivalent: ""
        )
        preview.target = self
        menu.addItem(preview)

        let activeDeviceDetection = NSMenuItem(
            title: L10n.enableActiveDeviceDetection,
            action: #selector(toggleActiveDeviceDetection),
            keyEquivalent: ""
        )
        activeDeviceDetection.target = self
        menu.addItem(activeDeviceDetection)
        activeDeviceDetectionMenuItem = activeDeviceDetection

        let delayMenu = NSMenu()
        for value in [0.2, 0.4, 0.8] {
            let delayItem = NSMenuItem(
                title: String(format: L10n.delaySecondsFormat, value),
                action: #selector(selectDelay(_:)),
                keyEquivalent: ""
            )
            delayItem.target = self
            delayItem.representedObject = value
            delayMenu.addItem(delayItem)
            delayItems.append(delayItem)
        }
        let delayRoot = NSMenuItem(
            title: L10n.triggerDelay,
            action: nil,
            keyEquivalent: ""
        )
        delayRoot.submenu = delayMenu
        menu.addItem(delayRoot)

        let diagnostic = NSMenuItem(
            title: L10n.openDiagnosticLog,
            action: #selector(openDiagnosticLog),
            keyEquivalent: ""
        )
        diagnostic.target = self
        menu.addItem(diagnostic)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: L10n.quitApplication,
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
        updateMenu()
    }

    private func configureMainWindow() {
        let controller = MainWindowController()
        controller.onPreview = { [weak self] in
            self?.togglePreview()
        }
        controller.onOpenDiagnosticLog = { [weak self] in
            self?.openDiagnosticLog()
        }
        controller.updateOverlaySettings(savedOverlaySettings)
        controller.onOverlaySettingsChanged = { [weak self] settings in
            self?.saveOverlaySettings(settings)
        }
        controller.onSettingsPreviewBegan = { [weak self] in
            self?.settingsPreviewActive = true
            self?.updatePresentation()
        }
        controller.onSettingsPreviewEnded = { [weak self] in
            self?.settingsPreviewActive = false
            self?.updatePresentation()
        }
        mainWindowController = controller
        updateMenu()
    }

    private func updateMenu() {
        let title: String
        let detail: String
        let symbolName: String

        if flowAway {
            title = L10n.flowAwayTitle
            detail = L10n.flowAwayDetail
            symbolName = "cursorarrow.slash"
        } else if hasSeenLogitechPointer {
            let name = connectedNames.first ?? L10n.logitechMouse
            if isLogiOptionsPlusRunning {
                title = L10n.monitoringTitle(deviceName: name)
                detail = L10n.monitoringDetail
                symbolName = "cursorarrow.motionlines"
            } else {
                title = L10n.waitingForOptionsTitle
                detail = L10n.waitingForOptionsDetail
                symbolName = "exclamationmark.triangle"
            }
        } else {
            title = L10n.waitingForMouseTitle
            detail = L10n.waitingForMouseDetail
            symbolName = "computermouse"
        }

        statusMenuItem?.title = String(format: L10n.statusFormat, title)
        statusItem?.button?.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: title
        )
        mainWindowController?.updateStatus(
            title: title,
            detail: detail,
            symbolName: symbolName
        )
        activeDeviceDetectionMenuItem?.state =
            activeDeviceDetectionEnabled ? .on : .off
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

    @objc private func showMainWindow() {
        mainWindowController?.present()
    }

    @objc private func toggleActiveDeviceDetection() {
        activeDeviceDetectionEnabled.toggle()
        if !activeDeviceDetectionEnabled {
            flowAway = false
            edgeDetector.reset()
            updatePresentation()
        }
        updateMenu()
    }

    private func saveOverlaySettings(_ settings: OverlaySettings) {
        let defaults = UserDefaults.standard
        defaults.set(
            settings.transparency,
            forKey: "overlayTransparency"
        )
        defaults.set(
            settings.glassIntensity,
            forKey: "overlayGlassIntensity"
        )
        if settings.message == L10n.overlayTitle {
            defaults.removeObject(forKey: "overlayMessage")
        } else {
            defaults.set(settings.message, forKey: "overlayMessage")
        }
        overlay.updateSettings(settings)
        DiagnosticLog.write(
            "overlaySettings transparency="
                + String(format: "%.2f", settings.transparency)
                + " glassIntensity="
                + String(format: "%.2f", settings.glassIntensity)
                + " messageLength=\(settings.message.count)"
        )
    }

    private func dismissCurrentOverlay() {
        manualPreview = false
        settingsPreviewActive = false
        flowAway = false
        edgeDetector.reset()
        updatePresentation()
        DiagnosticLog.write("overlayDismissed")
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
        LogiOptionsPlusRuntime.isRunning
    }
}
