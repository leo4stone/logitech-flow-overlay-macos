import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlay = OverlayController()
    private let reconnectAlert = ReconnectAlertController()
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
    private var reconnectSettingsPreviewActive = false
    private var connectedNames: [String] = []
    private var optionsRuntimeTracker = RuntimeAvailabilityTracker(
        unavailabilityGracePeriod: 2.0
    )
    private var nextOptionsRuntimeProbeAt: TimeInterval = 0

    private var optionsPlusRunning: Bool {
        optionsRuntimeTracker.isAvailable ?? false
    }

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

    private var savedReconnectAlertSettings: ReconnectAlertSettings {
        let defaults = UserDefaults.standard
        let isEnabled: Bool
        if defaults.object(forKey: "reconnectAlertEnabled") == nil {
            isEnabled = ReconnectAlertSettings.defaultEnabled
        } else {
            isEnabled = defaults.bool(forKey: "reconnectAlertEnabled")
        }
        let dimOpacity = defaults.object(
            forKey: "reconnectAlertDimOpacity"
        ) as? Double ?? ReconnectAlertSettings.defaultDimOpacity
        let duration = defaults.object(
            forKey: "reconnectAlertDuration"
        ) as? Double ?? ReconnectAlertSettings.defaultDuration
        let radius = defaults.object(
            forKey: "reconnectAlertRadius"
        ) as? Double ?? ReconnectAlertSettings.defaultRadius
        let feather = defaults.object(
            forKey: "reconnectAlertFeather"
        ) as? Double ?? ReconnectAlertSettings.defaultFeather
        let defaultColor = ReconnectAlertSettings.defaultSpotlightColor
        let spotlightColor = ReconnectSpotlightColor(
            red: defaults.object(
                forKey: "reconnectAlertSpotlightRed"
            ) as? Double ?? defaultColor.red,
            green: defaults.object(
                forKey: "reconnectAlertSpotlightGreen"
            ) as? Double ?? defaultColor.green,
            blue: defaults.object(
                forKey: "reconnectAlertSpotlightBlue"
            ) as? Double ?? defaultColor.blue,
            alpha: defaults.object(
                forKey: "reconnectAlertSpotlightAlpha"
            ) as? Double ?? defaultColor.alpha
        )
        return ReconnectAlertSettings(
            isEnabled: isEnabled,
            dimOpacity: dimOpacity,
            duration: duration,
            radius: radius,
            feather: feather,
            spotlightColor: spotlightColor
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
        reconnectAlert.hide(animated: false)
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
        let pointerLocation = NSEvent.mouseLocation
        reconnectAlert.updatePointerLocation(pointerLocation)
        let timestamp = ProcessInfo.processInfo.systemUptime

        if FileManager.default.fileExists(atPath: DiagnosticLog.previewTriggerPath) {
            try? FileManager.default.removeItem(atPath: DiagnosticLog.previewTriggerPath)
            runDiagnosticPreview(Notification(
                name: Notification.Name(
                    "io.github.leo4stone.LogitechFlowOverlay.preview"
                )
            ))
        }

        refreshOptionsRuntime(at: timestamp)

        guard activeDeviceDetectionEnabled else {
            if flowAway {
                flowAway = false
                edgeDetector.reset()
                updatePresentation()
            }
            return
        }

        guard optionsPlusRunning else {
            // Runtime availability is only a health signal. Once a Flow
            // departure is confirmed, never turn a negative process probe into
            // a synthetic return; preserve the state until positive local
            // pointer evidence or an explicit user action ends it.
            if !flowAway {
                edgeDetector.reset()
            }
            return
        }

        let screenFrames = NSScreen.screens.map(\.frame)
        let wasArmed = edgeDetector.isArmed
        let event = edgeDetector.observe(
            point: pointerLocation,
            screens: screenFrames,
            at: timestamp
        )
        if !wasArmed && edgeDetector.isArmed {
            DiagnosticLog.write(
                "flowCandidate point=\(NSStringFromPoint(pointerLocation))"
            )
        }

        switch event {
        case .leftComputer:
            DiagnosticLog.write("flowAway")
            reconnectAlert.hide(animated: false)
            flowAway = true
            updatePresentation()
        case .returned:
            completeFlowReturn(source: "edge")
        case nil:
            break
        }
    }

    private func refreshOptionsRuntime(at timestamp: TimeInterval) {
        guard timestamp >= nextOptionsRuntimeProbeAt else { return }
        nextOptionsRuntimeProbeAt = timestamp + 0.5

        let rawIsRunning = isLogiOptionsPlusRunning
        let wasPending = optionsRuntimeTracker.isUnavailabilityPending
        let stableChange = optionsRuntimeTracker.observe(
            rawIsAvailable: rawIsRunning,
            at: timestamp
        )

        if !wasPending && optionsRuntimeTracker.isUnavailabilityPending {
            DiagnosticLog.write(
                "optionsPlusProbeMissing flowAwayPreserved=\(flowAway)"
            )
        } else if wasPending,
                  !optionsRuntimeTracker.isUnavailabilityPending,
                  rawIsRunning
        {
            DiagnosticLog.write("optionsPlusProbeRecovered")
        }

        guard let stableChange else { return }
        DiagnosticLog.write("optionsPlusRunning=\(stableChange)")
        if !stableChange, flowAway {
            DiagnosticLog.write("flowAwayPreserved reason=optionsPlusUnavailable")
        }
        updateMenu()
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
        completeFlowReturn(source: "hidInput")
    }

    private func completeFlowReturn(source: String) {
        guard flowAway else { return }
        DiagnosticLog.write("flowReturned source=\(source)")
        flowAway = false
        edgeDetector.reset()
        updatePresentation()

        let settings = savedReconnectAlertSettings
        guard settings.isEnabled else { return }
        reconnectAlert.show(
            at: NSEvent.mouseLocation,
            settings: settings
        )
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
        controller.updateReconnectAlertSettings(savedReconnectAlertSettings)
        controller.onReconnectAlertSettingsChanged = { [weak self] settings in
            self?.saveReconnectAlertSettings(settings)
        }
        controller.onReconnectAlertPreview = { [weak self] in
            self?.previewReconnectAlert()
        }
        controller.onReconnectAlertSettingsPreviewBegan = { [weak self] in
            self?.beginReconnectAlertSettingsPreview()
        }
        controller.onReconnectAlertSettingsPreviewEnded = { [weak self] in
            self?.endReconnectAlertSettingsPreview()
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
            if optionsPlusRunning {
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
            reconnectAlert.hide()
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

    private func saveReconnectAlertSettings(
        _ settings: ReconnectAlertSettings
    ) {
        let defaults = UserDefaults.standard
        defaults.set(
            settings.isEnabled,
            forKey: "reconnectAlertEnabled"
        )
        defaults.set(
            settings.dimOpacity,
            forKey: "reconnectAlertDimOpacity"
        )
        defaults.set(
            settings.duration,
            forKey: "reconnectAlertDuration"
        )
        defaults.set(
            settings.radius,
            forKey: "reconnectAlertRadius"
        )
        defaults.set(
            settings.feather,
            forKey: "reconnectAlertFeather"
        )
        defaults.set(
            settings.spotlightColor.red,
            forKey: "reconnectAlertSpotlightRed"
        )
        defaults.set(
            settings.spotlightColor.green,
            forKey: "reconnectAlertSpotlightGreen"
        )
        defaults.set(
            settings.spotlightColor.blue,
            forKey: "reconnectAlertSpotlightBlue"
        )
        defaults.set(
            settings.spotlightColor.alpha,
            forKey: "reconnectAlertSpotlightAlpha"
        )
        defaults.removeObject(forKey: "reconnectAlertBrightnessBoost")
        reconnectAlert.updateSettings(settings)
        if !settings.isEnabled {
            reconnectSettingsPreviewActive = false
            reconnectAlert.hide()
        }
        DiagnosticLog.write(
            "reconnectAlertSettings enabled=\(settings.isEnabled) "
                + "dimOpacity="
                + String(format: "%.2f", settings.dimOpacity)
                + " duration="
                + String(format: "%.2f", settings.duration)
                + " radius="
                + String(format: "%.0f", settings.radius)
                + " feather="
                + String(format: "%.2f", settings.feather)
                + " spotlightColor="
                + String(
                    format: "%.2f,%.2f,%.2f,%.2f",
                    settings.spotlightColor.red,
                    settings.spotlightColor.green,
                    settings.spotlightColor.blue,
                    settings.spotlightColor.alpha
                )
        )
    }

    private func beginReconnectAlertSettingsPreview() {
        guard !reconnectSettingsPreviewActive else { return }
        let settings = savedReconnectAlertSettings
        guard settings.isEnabled else { return }
        reconnectSettingsPreviewActive = true
        reconnectAlert.showSettingsPreview(
            at: NSEvent.mouseLocation,
            settings: settings
        )
    }

    private func endReconnectAlertSettingsPreview() {
        guard reconnectSettingsPreviewActive else { return }
        reconnectSettingsPreviewActive = false
        reconnectAlert.hide()
    }

    private func previewReconnectAlert() {
        let settings = savedReconnectAlertSettings
        guard settings.isEnabled else { return }
        reconnectAlert.show(
            at: NSEvent.mouseLocation,
            settings: settings
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
