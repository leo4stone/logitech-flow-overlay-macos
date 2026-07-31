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
    var onReconnectAlertSettingsChanged: ((ReconnectAlertSettings) -> Void)?
    var onReconnectAlertPreview: (() -> Void)?
    var onReconnectAlertSettingsPreviewBegan: (() -> Void)?
    var onReconnectAlertSettingsPreviewEnded: (() -> Void)?
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
    private let glassSlider = TrackingSlider(
        value: OverlaySettings.defaultGlassIntensity * 100,
        minValue: OverlaySettings.minimumGlassIntensity * 100,
        maxValue: OverlaySettings.maximumGlassIntensity * 100,
        target: nil,
        action: nil
    )
    private let glassValueLabel = NSTextField(labelWithString: "")
    private let messageField = NSTextField(string: L10n.overlayTitle)
    private let reconnectAlertCheckbox = NSButton(
        checkboxWithTitle: L10n.enableReconnectAlert,
        target: nil,
        action: nil
    )
    private let reconnectDimSlider = TrackingSlider(
        value: ReconnectAlertSettings.defaultDimOpacity * 100,
        minValue: ReconnectAlertSettings.minimumDimOpacity * 100,
        maxValue: ReconnectAlertSettings.maximumDimOpacity * 100,
        target: nil,
        action: nil
    )
    private let reconnectDimValueLabel = NSTextField(labelWithString: "")
    private let reconnectDurationSlider = TrackingSlider(
        value: ReconnectAlertSettings.defaultDuration,
        minValue: ReconnectAlertSettings.minimumDuration,
        maxValue: ReconnectAlertSettings.maximumDuration,
        target: nil,
        action: nil
    )
    private let reconnectDurationValueLabel = NSTextField(labelWithString: "")
    private let reconnectRadiusSlider = TrackingSlider(
        value: ReconnectAlertSettings.defaultRadius,
        minValue: ReconnectAlertSettings.minimumRadius,
        maxValue: ReconnectAlertSettings.maximumRadius,
        target: nil,
        action: nil
    )
    private let reconnectRadiusValueLabel = NSTextField(labelWithString: "")
    private let reconnectFeatherSlider = TrackingSlider(
        value: ReconnectAlertSettings.defaultFeather * 100,
        minValue: ReconnectAlertSettings.minimumFeather * 100,
        maxValue: ReconnectAlertSettings.maximumFeather * 100,
        target: nil,
        action: nil
    )
    private let reconnectFeatherValueLabel = NSTextField(labelWithString: "")
    private lazy var reconnectControls: [NSControl] = [
        reconnectDimSlider,
        reconnectDurationSlider,
        reconnectRadiusSlider,
        reconnectFeatherSlider
    ]
    private let reconnectPreviewButton = NSButton(
        title: L10n.previewReconnectAlert,
        target: nil,
        action: nil
    )

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 900),
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
        glassSlider.doubleValue = settings.glassIntensity * 100
        messageField.stringValue = settings.message
        updateTransparencyValue()
        updateGlassValue()
    }

    func updateReconnectAlertSettings(
        _ settings: ReconnectAlertSettings
    ) {
        reconnectAlertCheckbox.state = settings.isEnabled ? .on : .off
        reconnectDimSlider.doubleValue = settings.dimOpacity * 100
        reconnectDurationSlider.doubleValue = settings.duration
        reconnectRadiusSlider.doubleValue = settings.radius
        reconnectFeatherSlider.doubleValue = settings.feather * 100
        updateReconnectAlertValues()
        updateReconnectControlsEnabled()
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
        let reconnectAlertCard = makeReconnectAlertCard()

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
            views: [
                title,
                subtitle,
                statusCard,
                settingsCard,
                reconnectAlertCard,
                buttons,
                note
            ]
        )
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        stack.setCustomSpacing(10, after: title)
        stack.setCustomSpacing(20, after: subtitle)
        stack.setCustomSpacing(16, after: statusCard)
        stack.setCustomSpacing(14, after: settingsCard)
        stack.setCustomSpacing(20, after: reconnectAlertCard)
        contentView.addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        settingsCard.translatesAutoresizingMaskIntoConstraints = false
        reconnectAlertCard.translatesAutoresizingMaskIntoConstraints = false
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
            reconnectAlertCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
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

        let glassLabel = NSTextField(labelWithString: L10n.glassIntensity)
        glassLabel.font = .systemFont(ofSize: 13, weight: .medium)

        glassSlider.target = self
        glassSlider.action = #selector(glassChanged)
        glassSlider.isContinuous = true
        glassSlider.onTrackingBegan = { [weak self] in
            self?.beginSettingsPreview()
        }
        glassSlider.onTrackingEnded = { [weak self] in
            self?.endSettingsPreview()
        }

        glassValueLabel.font = .monospacedDigitSystemFont(
            ofSize: 13,
            weight: .medium
        )
        glassValueLabel.alignment = .right
        glassValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        glassValueLabel.widthAnchor.constraint(
            equalToConstant: 46
        ).isActive = true
        updateGlassValue()

        let glassRow = NSStackView(
            views: [glassLabel, glassSlider, glassValueLabel]
        )
        glassRow.orientation = .horizontal
        glassRow.alignment = .centerY
        glassRow.spacing = 12

        let glassHelp = NSTextField(
            labelWithString: L10n.glassIntensityHelp
        )
        glassHelp.font = .systemFont(ofSize: 11)
        glassHelp.textColor = .tertiaryLabelColor

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
                glassRow,
                glassHelp,
                messageLabel,
                messageRow
            ]
        )
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 8
        content.setCustomSpacing(14, after: heading)
        content.setCustomSpacing(12, after: transparencyHelp)
        content.setCustomSpacing(14, after: glassHelp)

        let card = NSVisualEffectView()
        card.material = .contentBackground
        card.blendingMode = .withinWindow
        card.state = .active
        card.wantsLayer = true
        card.layer?.cornerRadius = 14
        card.addSubview(content)

        content.translatesAutoresizingMaskIntoConstraints = false
        transparencyRow.translatesAutoresizingMaskIntoConstraints = false
        glassRow.translatesAutoresizingMaskIntoConstraints = false
        messageRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            transparencyRow.widthAnchor.constraint(equalTo: content.widthAnchor),
            glassRow.widthAnchor.constraint(equalTo: content.widthAnchor),
            messageRow.widthAnchor.constraint(equalTo: content.widthAnchor)
        ])
        return card
    }

    private func makeReconnectAlertCard() -> NSView {
        let heading = NSTextField(
            labelWithString: L10n.reconnectAlertSettings
        )
        heading.font = .systemFont(ofSize: 15, weight: .semibold)

        let summary = NSTextField(
            wrappingLabelWithString: L10n.reconnectAlertSummary
        )
        summary.font = .systemFont(ofSize: 11)
        summary.textColor = .tertiaryLabelColor

        reconnectAlertCheckbox.target = self
        reconnectAlertCheckbox.action = #selector(reconnectAlertChanged)

        reconnectPreviewButton.target = self
        reconnectPreviewButton.action = #selector(previewReconnectAlert)
        reconnectPreviewButton.bezelStyle = .rounded

        let enableRow = NSStackView(
            views: [reconnectAlertCheckbox, reconnectPreviewButton]
        )
        enableRow.orientation = .horizontal
        enableRow.alignment = .centerY
        enableRow.spacing = 12
        enableRow.distribution = .fill
        reconnectAlertCheckbox.setContentHuggingPriority(
            .defaultLow,
            for: .horizontal
        )

        let dimRow = makeReconnectSliderRow(
            label: L10n.reconnectDimOpacity,
            slider: reconnectDimSlider,
            valueLabel: reconnectDimValueLabel,
            action: #selector(reconnectDimChanged)
        )
        let durationRow = makeReconnectSliderRow(
            label: L10n.reconnectDuration,
            slider: reconnectDurationSlider,
            valueLabel: reconnectDurationValueLabel,
            action: #selector(reconnectDurationChanged)
        )
        let radiusRow = makeReconnectSliderRow(
            label: L10n.reconnectRadius,
            slider: reconnectRadiusSlider,
            valueLabel: reconnectRadiusValueLabel,
            action: #selector(reconnectRadiusChanged)
        )
        let featherRow = makeReconnectSliderRow(
            label: L10n.reconnectFeather,
            slider: reconnectFeatherSlider,
            valueLabel: reconnectFeatherValueLabel,
            action: #selector(reconnectFeatherChanged)
        )

        let content = NSStackView(
            views: [
                heading,
                summary,
                enableRow,
                dimRow,
                durationRow,
                radiusRow,
                featherRow
            ]
        )
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 9
        content.setCustomSpacing(4, after: heading)
        content.setCustomSpacing(12, after: summary)

        let card = NSVisualEffectView()
        card.material = .contentBackground
        card.blendingMode = .withinWindow
        card.state = .active
        card.wantsLayer = true
        card.layer?.cornerRadius = 14
        card.addSubview(content)

        content.translatesAutoresizingMaskIntoConstraints = false
        summary.translatesAutoresizingMaskIntoConstraints = false
        enableRow.translatesAutoresizingMaskIntoConstraints = false
        dimRow.translatesAutoresizingMaskIntoConstraints = false
        durationRow.translatesAutoresizingMaskIntoConstraints = false
        radiusRow.translatesAutoresizingMaskIntoConstraints = false
        featherRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(
                equalTo: card.leadingAnchor,
                constant: 20
            ),
            content.trailingAnchor.constraint(
                equalTo: card.trailingAnchor,
                constant: -20
            ),
            content.topAnchor.constraint(
                equalTo: card.topAnchor,
                constant: 16
            ),
            content.bottomAnchor.constraint(
                equalTo: card.bottomAnchor,
                constant: -16
            ),
            summary.widthAnchor.constraint(equalTo: content.widthAnchor),
            enableRow.widthAnchor.constraint(equalTo: content.widthAnchor),
            dimRow.widthAnchor.constraint(equalTo: content.widthAnchor),
            durationRow.widthAnchor.constraint(equalTo: content.widthAnchor),
            radiusRow.widthAnchor.constraint(equalTo: content.widthAnchor),
            featherRow.widthAnchor.constraint(equalTo: content.widthAnchor)
        ])
        updateReconnectAlertValues()
        updateReconnectControlsEnabled()
        return card
    }

    private func makeReconnectSliderRow(
        label title: String,
        slider: TrackingSlider,
        valueLabel: NSTextField,
        action: Selector
    ) -> NSStackView {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.widthAnchor.constraint(equalToConstant: 126).isActive = true

        slider.target = self
        slider.action = action
        slider.isContinuous = true
        slider.onTrackingBegan = { [weak self] in
            self?.beginReconnectAlertSettingsPreview()
        }
        slider.onTrackingEnded = { [weak self] in
            self?.endReconnectAlertSettingsPreview()
        }

        valueLabel.font = .monospacedDigitSystemFont(
            ofSize: 13,
            weight: .medium
        )
        valueLabel.alignment = .right
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.widthAnchor.constraint(equalToConstant: 58).isActive = true

        let row = NSStackView(views: [label, slider, valueLabel])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        return row
    }

    private func notifyOverlaySettingsChanged() {
        let settings = OverlaySettings(
            transparency: transparencySlider.doubleValue / 100,
            glassIntensity: glassSlider.doubleValue / 100,
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

    private func updateGlassValue() {
        glassValueLabel.stringValue = String(
            format: "%.0f%%",
            glassSlider.doubleValue
        )
    }

    private func notifyReconnectAlertSettingsChanged() {
        onReconnectAlertSettingsChanged?(
            ReconnectAlertSettings(
                isEnabled: reconnectAlertCheckbox.state == .on,
                dimOpacity: reconnectDimSlider.doubleValue / 100,
                duration: reconnectDurationSlider.doubleValue,
                radius: reconnectRadiusSlider.doubleValue,
                feather: reconnectFeatherSlider.doubleValue / 100
            )
        )
    }

    private func updateReconnectAlertValues() {
        reconnectDimValueLabel.stringValue = String(
            format: "%.0f%%",
            reconnectDimSlider.doubleValue
        )
        reconnectDurationValueLabel.stringValue = String(
            format: L10n.reconnectDurationValueFormat,
            reconnectDurationSlider.doubleValue
        )
        reconnectRadiusValueLabel.stringValue = String(
            format: "%.0f pt",
            reconnectRadiusSlider.doubleValue
        )
        reconnectFeatherValueLabel.stringValue = String(
            format: "%.0f%%",
            reconnectFeatherSlider.doubleValue
        )
    }

    private func updateReconnectControlsEnabled() {
        let isEnabled = reconnectAlertCheckbox.state == .on
        reconnectControls.forEach { $0.isEnabled = isEnabled }
        reconnectPreviewButton.isEnabled = isEnabled
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

    private func beginReconnectAlertSettingsPreview() {
        onReconnectAlertSettingsPreviewBegan?()
    }

    private func endReconnectAlertSettingsPreview() {
        onReconnectAlertSettingsPreviewEnded?()
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

    @objc private func glassChanged() {
        updateGlassValue()
        notifyOverlaySettingsChanged()
    }

    @objc private func resetDefaultMessage() {
        messageField.stringValue = L10n.overlayTitle
        notifyOverlaySettingsChanged()
    }

    @objc private func reconnectAlertChanged() {
        updateReconnectControlsEnabled()
        notifyReconnectAlertSettingsChanged()
    }

    @objc private func reconnectDimChanged() {
        updateReconnectAlertValues()
        notifyReconnectAlertSettingsChanged()
    }

    @objc private func reconnectDurationChanged() {
        updateReconnectAlertValues()
        notifyReconnectAlertSettingsChanged()
    }

    @objc private func reconnectRadiusChanged() {
        updateReconnectAlertValues()
        notifyReconnectAlertSettingsChanged()
    }

    @objc private func reconnectFeatherChanged() {
        updateReconnectAlertValues()
        notifyReconnectAlertSettingsChanged()
    }

    @objc private func previewReconnectAlert() {
        onReconnectAlertPreview?()
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
            glassIntensity: glassSlider.doubleValue / 100,
            message: messageField.stringValue
        )
        messageField.stringValue = settings.message
        onOverlaySettingsChanged?(settings)
    }
}
