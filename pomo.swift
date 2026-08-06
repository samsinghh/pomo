import AppKit

let args = CommandLine.arguments
guard args.count == 3, let workMin = Double(args[1]), let breakMin = Double(args[2]),
      workMin > 0, breakMin > 0 else {
    FileHandle.standardError.write(Data("usage: pomo WORK_MINUTES BREAK_MINUTES\n".utf8))
    exit(2)
}

final class ChipView: NSView {
    var onHover: ((Bool) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways],
                                       owner: self))
    }

    override func mouseEntered(with event: NSEvent) { onHover?(true) }
    override func mouseExited(with event: NSEvent) { onHover?(false) }
}

@MainActor
final class Pomo: NSObject {
    private let workColor = NSColor(red: 0.85, green: 0.33, blue: 0.31, alpha: 1)
    private let breakColor = NSColor(red: 0.36, green: 0.72, blue: 0.36, alpha: 1)
    private let pausedColor = NSColor(white: 0.45, alpha: 1)

    private let workSeconds: TimeInterval
    private let breakSeconds: TimeInterval

    private let window: NSWindow
    private let chip = ChipView()
    private let phaseLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let closeButton = NSButton()

    private var onBreak = false
    private var phaseEnd = Date()
    private var paused = false
    private var pausedRemaining: TimeInterval = 0

    init(workMinutes: Double, breakMinutes: Double) {
        workSeconds = workMinutes * 60
        breakSeconds = breakMinutes * 60

        let size = CGSize(width: 220, height: 100)
        let visible = NSScreen.main!.visibleFrame
        let origin = CGPoint(x: visible.maxX - size.width - 20,
                             y: visible.maxY - size.height - 20)

        window = NSWindow(contentRect: NSRect(origin: origin, size: size),
                          styleMask: [.borderless], backing: .buffered, defer: false)
        super.init()

        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces]
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.contentView = chip

        chip.wantsLayer = true
        chip.layer!.cornerRadius = 14

        phaseLabel.font = .systemFont(ofSize: 14, weight: .bold)
        phaseLabel.textColor = .white
        phaseLabel.alignment = .center

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 34, weight: .bold)
        timeLabel.textColor = .white
        timeLabel.alignment = .center

        let stack = NSStackView(views: [phaseLabel, timeLabel])
        stack.orientation = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(stack)

        closeButton.attributedTitle = NSAttributedString(
            string: "✕",
            attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.85),
                         .font: NSFont.systemFont(ofSize: 11, weight: .bold)])
        closeButton.isBordered = false
        closeButton.toolTip = "Quit"
        closeButton.alphaValue = 0
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(closeButton)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: chip.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
            closeButton.topAnchor.constraint(equalTo: chip.topAnchor, constant: 4),
            closeButton.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -6),
            closeButton.widthAnchor.constraint(equalToConstant: 18),
            closeButton.heightAnchor.constraint(equalToConstant: 18),
        ])

        let button = closeButton
        chip.onHover = { inside in
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.15
                button.animator().alphaValue = inside ? 1 : 0
            }
        }

        chip.addGestureRecognizer(
            NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:))))
    }

    func run() {
        startPhase(isBreak: false)
        tick()
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(tick),
                             userInfo: nil, repeats: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func startPhase(isBreak: Bool) {
        onBreak = isBreak
        phaseEnd = Date().addingTimeInterval(isBreak ? breakSeconds : workSeconds)
        phaseLabel.stringValue = isBreak ? "BREAK" : "WORK"
        chip.layer!.backgroundColor = (isBreak ? breakColor : workColor).cgColor
    }

    @objc private func tick() {
        guard !paused else { return }
        var remaining = phaseEnd.timeIntervalSinceNow
        if remaining <= 0 {
            NSSound.beep()
            startPhase(isBreak: !onBreak)
            remaining = phaseEnd.timeIntervalSinceNow
        }
        let total = Int(remaining.rounded(.up))
        timeLabel.stringValue = String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func togglePause() {
        paused.toggle()
        if paused {
            pausedRemaining = max(phaseEnd.timeIntervalSinceNow, 0)
            phaseLabel.stringValue = "PAUSED"
            chip.layer!.backgroundColor = pausedColor.cgColor
        } else {
            phaseEnd = Date().addingTimeInterval(pausedRemaining)
            phaseLabel.stringValue = onBreak ? "BREAK" : "WORK"
            chip.layer!.backgroundColor = (onBreak ? breakColor : workColor).cgColor
        }
    }

    @objc private func handleClick(_ sender: NSClickGestureRecognizer) {
        if closeButton.frame.insetBy(dx: -8, dy: -8).contains(sender.location(in: chip)) {
            exit(0)
        }
        togglePause()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let pomo = MainActor.assumeIsolated { () -> Pomo in
    let p = Pomo(workMinutes: workMin, breakMinutes: breakMin)
    p.run()
    return p
}

signal(SIGINT, SIG_IGN)
let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigint.setEventHandler { exit(0) }
sigint.resume()

app.run()
