import AppKit

final class MainWindowController: NSWindowController {
    var onPreview: (() -> Void)?
    var onOpenDiagnosticLog: (() -> Void)?

    private let statusIcon = NSImageView()
    private let statusLabel = NSTextField(
        labelWithString: L10n.mainInitialStatus
    )
    private let statusDetailLabel = NSTextField(
        wrappingLabelWithString: L10n.mainInitialDetail
    )

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 440),
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
            views: [title, subtitle, statusCard, buttons, note]
        )
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        stack.setCustomSpacing(10, after: title)
        stack.setCustomSpacing(24, after: subtitle)
        stack.setCustomSpacing(24, after: statusCard)
        contentView.addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        statusCard.translatesAutoresizingMaskIntoConstraints = false
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
            note.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    @objc private func previewOverlay() {
        onPreview?()
    }

    @objc private func openDiagnosticLog() {
        onOpenDiagnosticLog?()
    }
}
