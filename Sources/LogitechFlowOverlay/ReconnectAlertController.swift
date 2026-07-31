import AppKit

private final class ReconnectAlertPanel: NSPanel {
    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}

final class ReconnectSpotlightView: NSView {
    var dimOpacity: CGFloat = 0.50 {
        didSet {
            needsDisplay = true
        }
    }

    var spotlightRadius: CGFloat = 100 {
        didSet {
            needsDisplay = true
        }
    }

    var feather: CGFloat = 0.04 {
        didSet {
            needsDisplay = true
        }
    }

    var pointerLocation: CGPoint? {
        didSet {
            needsDisplay = true
        }
    }

    override var isOpaque: Bool {
        false
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        context.clear(dirtyRect)
        guard let pointerLocation else {
            context.setFillColor(
                NSColor.black.withAlphaComponent(dimOpacity).cgColor
            )
            context.fill(bounds)
            return
        }

        if feather <= 0.001 {
            let outsidePath = CGMutablePath()
            outsidePath.addRect(bounds)
            outsidePath.addEllipse(
                in: spotlightRect(center: pointerLocation)
            )
            context.addPath(outsidePath)
            context.setFillColor(
                NSColor.black.withAlphaComponent(dimOpacity).cgColor
            )
            context.fillPath(using: .evenOdd)
            return
        }

        let colors = [
            NSColor.clear.cgColor,
            NSColor.clear.cgColor,
            NSColor.black.withAlphaComponent(dimOpacity).cgColor
        ] as CFArray
        let locations: [CGFloat] = [
            0.0,
            max(0.0, 1.0 - feather),
            1.0
        ]
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: locations
        ) else {
            return
        }

        context.drawRadialGradient(
            gradient,
            startCenter: pointerLocation,
            startRadius: 0,
            endCenter: pointerLocation,
            endRadius: spotlightRadius,
            options: [.drawsAfterEndLocation]
        )
    }

    private func spotlightRect(center: CGPoint) -> CGRect {
        CGRect(
            x: center.x - spotlightRadius,
            y: center.y - spotlightRadius,
            width: spotlightRadius * 2,
            height: spotlightRadius * 2
        )
    }
}

final class ReconnectAlertController: NSObject {
    private struct ScreenPanel {
        let screenID: CGDirectDisplayID
        let frame: CGRect
        let panel: NSPanel
        let spotlightView: ReconnectSpotlightView
    }

    private var screenPanels: [ScreenPanel] = []
    private var settings = ReconnectAlertSettings(
        isEnabled: ReconnectAlertSettings.defaultEnabled,
        dimOpacity: ReconnectAlertSettings.defaultDimOpacity,
        duration: ReconnectAlertSettings.defaultDuration,
        radius: ReconnectAlertSettings.defaultRadius,
        feather: ReconnectAlertSettings.defaultFeather
    )
    private var hideWorkItem: DispatchWorkItem?
    private var pointerLocation = CGPoint.zero
    private(set) var isVisible = false

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        hideWorkItem?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    func show(
        at pointerLocation: CGPoint,
        settings: ReconnectAlertSettings
    ) {
        present(
            at: pointerLocation,
            settings: settings,
            autoHideAfter: settings.duration,
            event: "reconnectAlertShown"
        )
    }

    func showSettingsPreview(
        at pointerLocation: CGPoint,
        settings: ReconnectAlertSettings
    ) {
        present(
            at: pointerLocation,
            settings: settings,
            autoHideAfter: nil,
            event: "reconnectAlertSettingsPreviewShown"
        )
    }

    func updateSettings(_ settings: ReconnectAlertSettings) {
        self.settings = settings
        screenPanels.forEach { item in
            item.spotlightView.dimOpacity = CGFloat(settings.dimOpacity)
            item.spotlightView.spotlightRadius = CGFloat(settings.radius)
            item.spotlightView.feather = CGFloat(settings.feather)
        }
    }

    private func present(
        at pointerLocation: CGPoint,
        settings: ReconnectAlertSettings,
        autoHideAfter duration: TimeInterval?,
        event: String
    ) {
        guard settings.isEnabled else { return }

        hideWorkItem?.cancel()
        self.settings = settings
        self.pointerLocation = pointerLocation
        isVisible = true
        rebuildPanels()
        updateSpotlightLocations()

        screenPanels.forEach { item in
            item.panel.setFrame(item.frame, display: true, animate: false)
            item.panel.alphaValue = 0
            item.panel.orderFrontRegardless()
            item.panel.setFrame(item.frame, display: true, animate: false)
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            screenPanels.forEach { $0.panel.animator().alphaValue = 1 }
        }

        if let duration {
            let workItem = DispatchWorkItem { [weak self] in
                self?.hide()
            }
            hideWorkItem = workItem
            DispatchQueue.main.asyncAfter(
                deadline: .now() + duration,
                execute: workItem
            )
        }

        logPanelState(event: event)
    }

    func updatePointerLocation(_ location: CGPoint) {
        guard isVisible else { return }
        pointerLocation = location
        updateSpotlightLocations()
    }

    func hide(animated: Bool = true) {
        guard isVisible else { return }
        isVisible = false
        hideWorkItem?.cancel()
        hideWorkItem = nil

        let currentPanels = screenPanels.map(\.panel)
        guard animated else {
            currentPanels.forEach { $0.orderOut(nil) }
            DiagnosticLog.write("reconnectAlertHidden")
            return
        }

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.24
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                currentPanels.forEach { $0.animator().alphaValue = 0 }
            },
            completionHandler: {
                currentPanels.forEach { $0.orderOut(nil) }
            }
        )
        DiagnosticLog.write("reconnectAlertHidden")
    }

    @objc private func screensChanged() {
        guard isVisible else { return }
        screenPanels.forEach { $0.panel.orderOut(nil) }
        rebuildPanels()
        updateSpotlightLocations()
        screenPanels.forEach {
            $0.panel.setFrame($0.frame, display: true, animate: false)
            $0.panel.alphaValue = 1
            $0.panel.orderFrontRegardless()
            $0.panel.setFrame($0.frame, display: true, animate: false)
        }
        logPanelState(event: "reconnectAlertScreensChanged")
    }

    private func rebuildPanels() {
        screenPanels.forEach { $0.panel.orderOut(nil) }
        screenPanels = NSScreen.screens.compactMap { screen in
            guard let screenID = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? CGDirectDisplayID else {
                return nil
            }
            return makeScreenPanel(for: screen, screenID: screenID)
        }
    }

    private func makeScreenPanel(
        for screen: NSScreen,
        screenID: CGDirectDisplayID
    ) -> ScreenPanel {
        let panel = ReconnectAlertPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.canHide = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        let spotlightView = ReconnectSpotlightView(
            frame: CGRect(origin: .zero, size: screen.frame.size)
        )
        spotlightView.autoresizingMask = [.width, .height]
        spotlightView.dimOpacity = CGFloat(settings.dimOpacity)
        spotlightView.spotlightRadius = CGFloat(settings.radius)
        spotlightView.feather = CGFloat(settings.feather)
        panel.contentView = spotlightView
        panel.setFrame(screen.frame, display: false, animate: false)

        return ScreenPanel(
            screenID: screenID,
            frame: screen.frame,
            panel: panel,
            spotlightView: spotlightView
        )
    }

    private func updateSpotlightLocations() {
        screenPanels.forEach { item in
            guard item.frame.contains(pointerLocation) else {
                item.spotlightView.pointerLocation = nil
                return
            }
            item.spotlightView.pointerLocation = CGPoint(
                x: pointerLocation.x - item.frame.minX,
                y: pointerLocation.y - item.frame.minY
            )
        }
    }

    private func logPanelState(event: String) {
        let activeScreen = screenPanels.first {
            $0.frame.contains(pointerLocation)
        }?.screenID
        let state = screenPanels.map { item in
            "display=\(item.screenID) window=\(item.panel.windowNumber) "
                + "target=\(NSStringFromRect(item.frame)) "
                + "actual=\(NSStringFromRect(item.panel.frame)) "
                + "visible=\(item.panel.isVisible)"
        }.joined(separator: " | ")
        DiagnosticLog.write(
            "\(event) count=\(screenPanels.count) "
                + "activeDisplay=\(activeScreen.map(String.init) ?? "none") "
                + "pointer=\(NSStringFromPoint(pointerLocation)) "
                + "dimOpacity=\(String(format: "%.2f", settings.dimOpacity)) "
                + "duration=\(String(format: "%.2f", settings.duration)) "
                + "radius=\(String(format: "%.0f", settings.radius)) "
                + "feather=\(String(format: "%.2f", settings.feather)) "
                + state
        )
    }
}
