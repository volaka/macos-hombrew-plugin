import AppKit
import BrewNotifierCore

@MainActor
final class CheckNowWindowController: NSWindowController {
    private let service: BrewService
    private let onComplete: (([BrewPackage], [BrewCask]) -> Void)?

    private var spinner: NSProgressIndicator!
    private var logView: NSTextView!
    private var statusLabel: NSTextField!
    private var actionButton: NSButton!
    private var checkTask: Task<Void, Never>?

    init(service: BrewService = BrewService(),
         onComplete: (([BrewPackage], [BrewCask]) -> Void)? = nil) {
        self.service = service
        self.onComplete = onComplete

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Checking for Updates"
        panel.isFloatingPanel = true
        panel.center()

        super.init(window: panel)
        buildUI(panel: panel)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildUI(panel: NSPanel) {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.isIndeterminate = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimation(nil)

        statusLabel = NSTextField(labelWithString: "Checking for updates…")
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.autoresizingMask = [.width]
        scrollView.documentView = textView
        logView = textView

        actionButton = NSButton(title: "Cancel", target: self, action: #selector(cancelOrClose))
        actionButton.bezelStyle = .rounded
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(spinner)
        container.addSubview(statusLabel)
        container.addSubview(scrollView)
        container.addSubview(actionButton)

        panel.contentView = container

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 400),
            container.heightAnchor.constraint(equalToConstant: 300),

            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),

            statusLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            scrollView.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -8),

            actionButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])
    }

    func startCheck() {
        checkTask = Task {
            do {
                let result = try await service.fetchOutdatedWithProgress { [weak self] line in
                    Task { @MainActor [weak self] in
                        self?.appendLog(line)
                    }
                }
                let total = result.formulae.count + result.casks.count
                spinner.stopAnimation(nil)
                spinner.isHidden = true
                statusLabel.stringValue = total > 0
                    ? "✅ Found \(total) update\(total == 1 ? "" : "s")"
                    : "✅ All packages up to date"
                actionButton.title = "Done"
                onComplete?(result.formulae, result.casks)
            } catch {
                spinner.stopAnimation(nil)
                spinner.isHidden = true
                statusLabel.stringValue = "❌ \(error.localizedDescription)"
                actionButton.title = "Close"
            }
        }
    }

    private func appendLog(_ line: String) {
        guard let storage = logView.textStorage else { return }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.labelColor,
        ]
        storage.append(NSAttributedString(string: line + "\n", attributes: attrs))
        logView.scrollToEndOfDocument(nil)
    }

    @objc private func cancelOrClose() {
        checkTask?.cancel()
        close()
    }
}
