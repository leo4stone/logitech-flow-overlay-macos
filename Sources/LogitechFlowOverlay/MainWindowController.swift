import AppKit

private final class TrackingSlider: NSSlider {
    var onTrackingBegan: (() -> Void)?
    var onTrackingEnded: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onTrackingBegan?()
        super.mouseDown(with: event)
        onTrackingEnded?()
    }
}

final class MainWindowController: NSWindowController {
    var onPreview: (() -> Void)?
    var onOpenDiagnosticLog: (() -> Void)?
    var onOverlaySettingsChanged: ((OverlaySettings) -> Void)?
    var onSettingsPreviewBegan: (() -> Void)?
    var onSettingsPreviewEnded: (() -> Void)?

    private let statusIcon = NSImageView()
    private let statusLabel = NSTextField(
        labelWithString: L10n.mainInitialStatus
    )
    private let statusDetailLabel = NSTextField(
        wrappingLabelWithString: L10n.mainInitialDetail
    )
    private let transparencySlider = TrackingSlider(
        value: OverlaySettings.defaultTransparency * 100,
        minValue: OverlaySettings.minimumTransparency * 100,
        maxValue: OverlaySettings.maximumTransparency * 100,
        target: nil,
        action: nil
    )
    private let transparencyValueLabel = NSTextField(labelWithString: "")
    private let messageField = NSTextField(string: L10n.overlayTitle)

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 620),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Logitech Flow Overlay"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        buildContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func updateStatus(
        title: String,
        detail: String,
        symbolName: String
    ) {
        statusLabel.stringValue = title
        statusDetailLabel.stringValue = detail
        statusIcon.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: title
        )
    }

    func updateOverlaySettings(_ settings: OverlaySettings) {
        transparencySlider.doubleValue = settings.transparency * 100
        messageField.stringValue = settings.message
        updateTransparencyValue()
    }

    private func buildContent() {
        guard let contentView = window?.contentView else { return }

        let title = NSTextField(labelWithString: "Logitech Flow Overlay")
        title.font = .systemFont(ofSize: 30, weight: .bold)

        let subtitle = NSTextField(
            wrappingLabelWithString: L10n.mainSummary
        )
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = .secondaryLabelColor

        statusIcon.symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: 34,
            weight: .medium
        )
        statusIcon.imageScaling = .scaleProportionallyUpOrDown

        statusLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        statusDetailLabel.font = .systemFont(ofSize: 13)
        statusDetailLabel.textColor = .secondaryLabelColor

        let statusText = NSStackView(views: [statusLabel, statusDetailLabel])
        statusText.orientation = .vertical
        statusText.alignment = .leading
        statusText.spacing = 5

        let statusRow = NSStackView(views: [statusIcon, statusText])
        statusRow.orientation = .horizontal
        statusRow.alignment = .centerY
        statusRow.spacing = 16
        statusRow.edgeInsets = NSEdgeInsets(
            top: 18,
            left: 20,
            bottom: 18,
            right: 20
        )

        let statusCard = NSVisualEffectView()
        statusCard.material = .contentBackground
        statusCard.blendingMode = .withinWindow
        statusCard.state = .active
        statusCard.wantsLayer = true
        statusCard.layer?.cornerRadius = 14
        statusCard.addSubview(statusRow)
        statusRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusRow.leadingAnchor.constraint(
                equalTo: statusCard.leadingAnchor
            ),
            statusRow.trailingAnchor.constraint(
                equalTo: statusCard.trailingAnchor
            ),
            statusRow.topAnchor.constraint(equalTo: statusCard.topAnchor),
            statusRow.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 42),
            statusIcon.heightAnchor.constraint(equalToConstant: 42)
        ])

        let settingsCard = makeSettingsCard()

        let previewButton = NSButton(
            title: L10n.previewOverlay,
            target: self,
            action: #selector(previewOverlay)
        )
        previewButton.bezelStyle = .rounded
        previewButton.controlSize = .large

        let logButton = NSButton(
            title: L10n.openDiagnosticLog,
            target: self,
            action: #selector(openDiagnosticLog)
        )
        logButton.bezelStyle = .rounded
        logButton.controlSize = .large

        let buttons = NSStackView(views: [previewButton, logButton])
        buttons.orientation = .horizontal
        buttons.spacing = 12

        let note = NSTextField(
            wrappingLabelWithString: L10n.mainClosingNote
        )
        note.font = .systemFont(ofSize: 12)
        note.textColor = .tertiaryLabelColor

        let stack = NSStackView(
            views: [title, subtitle, statusCard, settingsCard, buttons, note]
        )
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        stack.setCustomSpacing(10, after: title)
        stack.setCustomSpacing(20, after: subtitle)
        stack.setCustomSpacing(16, after: statusCard)
        stack.setCustomSpacing(20, after: settingsCard)
        contentView.addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        settingsCard.translatesAutoresizingMaskIntoConstraints = false
        note.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 36
            ),
            stack.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -36
            ),
            stack.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 34
            ),
            stack.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -30
            ),
            subtitle.widthAnchor.constraint(equalTo: stack.widthAnchor),
            statusCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            settingsCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            note.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    private func makeSettingsCard() -> NSView {
        let heading = NSTextField(labelWithString: L10n.overlaySettings)
        heading.font = .systemFont(ofSize: 15, weight: .semibold)

        let transparencyLabel = NSTextField(
            labelWithString: L10n.overlayTransparency
        )
        transparencyLabel.font = .systemFont(ofSize: 13, weight: .medium)

        transparencySlider.target = self
        transparencySlider.action = #selector(transparencyChanged)
        transparencySlider.isContinuous = true
        transparencySlider.onTrackingBegan = { [weak self] in
            self?.beginSettingsPreview()
        }
        transparencySlider.onTrackingEnded = { [weak self] in
            self?.endSettingsPreview()
        }

        transparencyValueLabel.font = .monospacedDigitSystemFont(
            ofSize: 13,
            weight: .medium
        )
        transparencyValueLabel.alignment = .right
        transparencyValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        transparencyValueLabel.widthAnchor.constraint(
            equalToConstant: 46
        ).isActive = true
        updateTransparencyValue()

        let transparencyRow = NSStackView(
            views: [
                transparencyLabel,
                transparencySlider,
                transparencyValueLabel
            ]
        )
        transparencyRow.orientation = .horizontal
        transparencyRow.alignment = .centerY
        transparencyRow.spacing = 12

        let transparencyHelp = NSTextField(
            labelWithString: L10n.overlayTransparencyHelp
        )
        transparencyHelp.font = .systemFont(ofSize: 11)
        transparencyHelp.textColor = .tertiaryLabelColor

        let messageLabel = NSTextField(labelWithString: L10n.overlayMessage)
        messageLabel.font = .systemFont(ofSize: 13, weight: .medium)

        messageField.placeholderString = L10n.overlayMessagePlaceholder
        messageField.delegate = self
        messageField.font = .systemFont(ofSize: 13)
        messageField.bezelStyle = .roundedBezel

        let resetButton = NSButton(
            title: L10n.resetDefaultMessage,
            target: self,
            action: #selector(resetDefaultMessage)
        )
        resetButton.bezelStyle = .rounded

        let messageRow = NSStackView(views: [messageField, resetButton])
        messageRow.orientation = .horizontal
        messageRow.alignment = .centerY
        messageRow.spacing = 10

        let content = NSStackView(
            views: [
                heading,
                transparencyRow,
                transparencyHelp,
                messageLabel,
                messageRow
            ]
        )
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 8
        content.setCustomSpacing(14, after: heading)
        content.setCustomSpacing(14, after: transparencyHelp)

        let card = NSVisualEffectView()
        card.material = .contentBackground
        card.blendingMode = .withinWindow
        card.state = .active
        card.wantsLayer = true
        card.layer?.cornerRadius = 14
        card.addSubview(content)

        content.translatesAutoresizingMaskIntoConstraints = false
        transparencyRow.translatesAutoresizingMaskIntoConstraints = false
        messageRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            transparencyRow.widthAnchor.constraint(equalTo: content.widthAnchor),
            messageRow.widthAnchor.constraint(equalTo: content.widthAnchor)
        ])
        return card
    }

    private func notifyOverlaySettingsChanged() {
        let settings = OverlaySettings(
            transparency: transparencySlider.doubleValue / 100,
            message: messageField.stringValue
        )
        onOverlaySettingsChanged?(settings)
    }

    private func updateTransparencyValue() {
        transparencyValueLabel.stringValue = String(
            format: "%.0f%%",
            transparencySlider.doubleValue
        )
    }

    private func beginSettingsPreview() {
        window?.level = NSWindow.Level(
            rawValue: NSWindow.Level.screenSaver.rawValue + 1
        )
        onSettingsPreviewBegan?()
    }

    private func endSettingsPreview() {
        onSettingsPreviewEnded?()
        window?.level = .normal
    }

    @objc private func previewOverlay() {
        onPreview?()
    }

    @objc private func openDiagnosticLog() {
        onOpenDiagnosticLog?()
    }

    @objc private func transparencyChanged() {
        updateTransparencyValue()
        notifyOverlaySettingsChanged()
    }

    @objc private func resetDefaultMessage() {
        messageField.stringValue = L10n.overlayTitle
        notifyOverlaySettingsChanged()
    }
}

extension MainWindowController: NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        let limited = String(
            messageField.stringValue.prefix(
                OverlaySettings.maximumMessageLength
            )
        )
        if limited != messageField.stringValue {
            messageField.stringValue = limited
        }
        notifyOverlaySettingsChanged()
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        let settings = OverlaySettings(
            transparency: transparencySlider.doubleValue / 100,
            message: messageField.stringValue
        )
        messageField.stringValue = settings.message
        onOverlaySettingsChanged?(settings)
    }
}
