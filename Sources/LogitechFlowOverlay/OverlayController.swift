import AppKit

private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

final class OverlayController: NSObject {
    private struct ScreenPanel {
        let screenID: CGDirectDisplayID
        let frame: CGRect
        let panel: NSPanel
        let blur: NSVisualEffectView
        let tint: NSView
        let title: NSTextField
    }

    private struct PanelContent {
        let root: NSView
        let blur: NSVisualEffectView
        let tint: NSView
        let title: NSTextField
    }

    private var screenPanels: [ScreenPanel] = []
    private(set) var isVisible = false
    var onDismiss: (() -> Void)?
    private var settings = OverlaySettings(
        transparency: OverlaySettings.defaultTransparency,
        message: L10n.overlayTitle
    )

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
        NotificationCenter.default.removeObserver(self)
    }

    func updateSettings(_ settings: OverlaySettings) {
        guard self.settings != settings else { return }
        self.settings = settings

        screenPanels.forEach { item in
            item.blur.alphaValue = CGFloat(settings.blurAlpha)
            item.tint.layer?.backgroundColor = overlayTintColor.cgColor
            item.title.stringValue = settings.message
        }
        if isVisible {
            logPanelState(event: "overlaySettingsChanged")
        }
    }

    func show(animated: Bool = true) {
        guard !isVisible else { return }
        isVisible = true
        rebuildPanels()

        for item in screenPanels {
            let panel = item.panel
            panel.setFrame(item.frame, display: true, animate: false)
            panel.alphaValue = animated ? 0 : 1
            panel.orderFrontRegardless()
            // AppKit can adjust a borderless panel during its first ordering.
            // Reassert the target display frame after the window has a number.
            panel.setFrame(item.frame, display: true, animate: false)
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                screenPanels.forEach { $0.panel.animator().alphaValue = 1 }
            }
        }
        logPanelState(event: "overlayShown")
    }

    func hide(animated: Bool = true) {
        guard isVisible else { return }
        isVisible = false

        guard animated else {
            screenPanels.forEach { $0.panel.orderOut(nil) }
            return
        }

        let currentPanels = screenPanels.map(\.panel)
        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                currentPanels.forEach { $0.animator().alphaValue = 0 }
            },
            completionHandler: {
                currentPanels.forEach { $0.orderOut(nil) }
            }
        )
    }

    @objc private func screensChanged() {
        guard isVisible else { return }
        screenPanels.forEach { $0.panel.orderOut(nil) }
        rebuildPanels()
        screenPanels.forEach {
            $0.panel.setFrame($0.frame, display: true, animate: false)
            $0.panel.alphaValue = 1
            $0.panel.orderFrontRegardless()
            $0.panel.setFrame($0.frame, display: true, animate: false)
        }
        logPanelState(event: "screensChanged")
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
        let panel = OverlayPanel(
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
        panel.ignoresMouseEvents = false
        panel.becomesKeyOnlyIfNeeded = true
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
        let content = makeContentView(frame: screen.frame)
        panel.contentView = content.root
        panel.setFrame(screen.frame, display: false, animate: false)
        return ScreenPanel(
            screenID: screenID,
            frame: screen.frame,
            panel: panel,
            blur: content.blur,
            tint: content.tint,
            title: content.title
        )
    }

    private func logPanelState(event: String) {
        let state = screenPanels.map { item in
            "display=\(item.screenID) window=\(item.panel.windowNumber) "
                + "target=\(NSStringFromRect(item.frame)) "
                + "actual=\(NSStringFromRect(item.panel.frame)) "
                + "visible=\(item.panel.isVisible)"
        }.joined(separator: " | ")
        DiagnosticLog.write("\(event) count=\(screenPanels.count) \(state)")
    }

    private var overlayTintColor: NSColor {
        NSColor(
            calibratedRed: 0.035,
            green: 0.055,
            blue: 0.085,
            alpha: CGFloat(settings.tintAlpha)
        )
    }

    private func makeContentView(frame: CGRect) -> PanelContent {
        let root = NSView(frame: CGRect(origin: .zero, size: frame.size))

        let blur = NSVisualEffectView(frame: root.bounds)
        blur.autoresizingMask = [.width, .height]
        blur.blendingMode = .behindWindow
        blur.material = .fullScreenUI
        blur.state = .active
        blur.alphaValue = CGFloat(settings.blurAlpha)
        root.addSubview(blur)

        let tint = NSView(frame: root.bounds)
        tint.autoresizingMask = [.width, .height]
        tint.wantsLayer = true
        tint.layer?.backgroundColor = overlayTintColor.cgColor
        root.addSubview(tint)

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        let symbol = NSImageView()
        symbol.image = NSImage(
            systemSymbolName: "cursorarrow.slash",
            accessibilityDescription: L10n.overlayAccessibility
        )
        symbol.symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: 54,
            weight: .semibold
        )
        symbol.contentTintColor = .white

        let title = NSTextField(
            wrappingLabelWithString: settings.message
        )
        title.font = .systemFont(ofSize: 28, weight: .semibold)
        title.textColor = .white
        title.alignment = .center
        title.maximumNumberOfLines = 3
        title.lineBreakMode = .byWordWrapping
        title.preferredMaxLayoutWidth = max(
            280,
            min(760, frame.width - 180)
        )

        let subtitle = NSTextField(labelWithString: L10n.overlaySubtitle)
        subtitle.font = .systemFont(ofSize: 15, weight: .medium)
        subtitle.textColor = NSColor.white.withAlphaComponent(0.72)
        subtitle.alignment = .center

        let dismissButton = NSButton(
            title: L10n.dismissOverlay,
            target: self,
            action: #selector(dismissOverlay)
        )
        dismissButton.bezelStyle = .rounded
        dismissButton.controlSize = .large
        dismissButton.image = NSImage(
            systemSymbolName: "xmark",
            accessibilityDescription: nil
        )
        dismissButton.imagePosition = .imageLeading
        dismissButton.contentTintColor = .white
        dismissButton.bezelColor = NSColor.white.withAlphaComponent(0.18)
        dismissButton.keyEquivalent = "\u{1b}"
        dismissButton.widthAnchor.constraint(
            greaterThanOrEqualToConstant: 130
        ).isActive = true

        let capsule = NSView()
        capsule.wantsLayer = true
        capsule.layer?.cornerRadius = 28
        capsule.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.22).cgColor
        capsule.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(symbol)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        stack.setCustomSpacing(20, after: subtitle)
        stack.addArrangedSubview(dismissButton)
        capsule.addSubview(stack)
        root.addSubview(capsule)

        NSLayoutConstraint.activate([
            capsule.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            capsule.centerYAnchor.constraint(equalTo: root.centerYAnchor),
            capsule.widthAnchor.constraint(greaterThanOrEqualToConstant: 470),
            capsule.widthAnchor.constraint(
                lessThanOrEqualTo: root.widthAnchor,
                constant: -80
            ),
            stack.leadingAnchor.constraint(equalTo: capsule.leadingAnchor, constant: 42),
            stack.trailingAnchor.constraint(equalTo: capsule.trailingAnchor, constant: -42),
            stack.topAnchor.constraint(equalTo: capsule.topAnchor, constant: 30),
            stack.bottomAnchor.constraint(equalTo: capsule.bottomAnchor, constant: -30)
        ])

        return PanelContent(
            root: root,
            blur: blur,
            tint: tint,
            title: title
        )
    }

    @objc private func dismissOverlay() {
        onDismiss?()
    }
}
