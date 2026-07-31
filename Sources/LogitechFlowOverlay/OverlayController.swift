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
        glassIntensity: OverlaySettings.defaultGlassIntensity,
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
            item.blur.maskImage = makeGlassMask(
                alpha: settings.glassMaskAlpha
            )
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

    private func makeGlassMask(alpha: Double) -> NSImage? {
        guard alpha < 1 else {
            return nil
        }

        let image = NSImage(
            size: NSSize(width: 2, height: 2),
            flipped: false
        ) { rect in
            NSColor.white.withAlphaComponent(alpha).setFill()
            rect.fill()
            return true
        }
        image.capInsets = NSEdgeInsets()
        image.resizingMode = .stretch
        return image
    }

    private func makeContentView(frame: CGRect) -> PanelContent {
        let root = NSView(frame: CGRect(origin: .zero, size: frame.size))

        let blur = NSVisualEffectView(frame: root.bounds)
        blur.autoresizingMask = [.width, .height]
        blur.blendingMode = .behindWindow
        blur.material = .fullScreenUI
        blur.state = .active
        blur.maskImage = makeGlassMask(
            alpha: settings.glassMaskAlpha
        )
        root.addSubview(blur)

        let tint = NSView(frame: root.bounds)
        tint.autoresizingMask = [.width, .height]
        tint.wantsLayer = true
        tint.layer?.backgroundColor = overlayTintColor.cgColor
        root.addSubview(tint)

        let promptStack = NSStackView()
        promptStack.orientation = .vertical
        promptStack.alignment = .centerX
        promptStack.spacing = 14
        promptStack.translatesAutoresizingMaskIntoConstraints = false

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

        let dismissImage = NSImage(
            systemSymbolName: "xmark",
            accessibilityDescription: L10n.dismissOverlay
        )?.withSymbolConfiguration(
            NSImage.SymbolConfiguration(
                pointSize: 18,
                weight: .semibold
            )
        ) ?? NSImage()
        dismissImage.isTemplate = true

        let dismissButton = NSButton(
            image: dismissImage,
            target: self,
            action: #selector(dismissOverlay)
        )
        dismissButton.controlSize = .large
        dismissButton.imagePosition = .imageOnly
        dismissButton.isBordered = false
        dismissButton.contentTintColor = .white
        dismissButton.wantsLayer = true
        dismissButton.layer?.cornerRadius = 25
        dismissButton.layer?.backgroundColor = NSColor.black.withAlphaComponent(
            0.32
        ).cgColor
        dismissButton.layer?.borderColor = NSColor.white.withAlphaComponent(
            0.28
        ).cgColor
        dismissButton.layer?.borderWidth = 1
        dismissButton.keyEquivalent = "\u{1b}"
        dismissButton.toolTip = L10n.dismissOverlay
        dismissButton.setAccessibilityLabel(L10n.dismissOverlay)
        dismissButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        dismissButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let promptCard = NSView()
        promptCard.wantsLayer = true
        promptCard.layer?.cornerRadius = 28
        promptCard.layer?.backgroundColor = NSColor.black.withAlphaComponent(
            0.22
        ).cgColor
        promptCard.translatesAutoresizingMaskIntoConstraints = false

        promptStack.addArrangedSubview(symbol)
        promptStack.addArrangedSubview(title)
        promptStack.addArrangedSubview(subtitle)
        promptCard.addSubview(promptStack)

        let overlayControls = NSStackView(
            views: [promptCard, dismissButton]
        )
        overlayControls.orientation = .vertical
        overlayControls.alignment = .centerX
        overlayControls.spacing = 18
        overlayControls.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(overlayControls)

        NSLayoutConstraint.activate([
            overlayControls.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            overlayControls.centerYAnchor.constraint(equalTo: root.centerYAnchor),
            promptCard.widthAnchor.constraint(greaterThanOrEqualToConstant: 470),
            promptCard.widthAnchor.constraint(
                lessThanOrEqualTo: root.widthAnchor,
                constant: -80
            ),
            promptStack.leadingAnchor.constraint(
                equalTo: promptCard.leadingAnchor,
                constant: 42
            ),
            promptStack.trailingAnchor.constraint(
                equalTo: promptCard.trailingAnchor,
                constant: -42
            ),
            promptStack.topAnchor.constraint(
                equalTo: promptCard.topAnchor,
                constant: 30
            ),
            promptStack.bottomAnchor.constraint(
                equalTo: promptCard.bottomAnchor,
                constant: -30
            )
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
