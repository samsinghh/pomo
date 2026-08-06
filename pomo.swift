import AppKit

let args = CommandLine.arguments
guard args.count == 3, let workMin = Double(args[1]), let breakMin = Double(args[2]),
      workMin > 0, breakMin > 0 else {
    FileHandle.standardError.write(Data("usage: pomo WORK_MINUTES BREAK_MINUTES\n".utf8))
    exit(2)
}

let workColor = NSColor(red: 0.85, green: 0.33, blue: 0.31, alpha: 1)
let breakColor = NSColor(red: 0.36, green: 0.72, blue: 0.36, alpha: 1)

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let width: CGFloat = 220, height: CGFloat = 100
let screen = NSScreen.main!.visibleFrame
let frame = NSRect(x: screen.maxX - width - 20, y: screen.maxY - height - 20,
                   width: width, height: height)

let window = NSWindow(contentRect: frame, styleMask: [.borderless],
                      backing: .buffered, defer: false)
window.level = .floating
window.isReleasedWhenClosed = false
window.collectionBehavior = [.canJoinAllSpaces]
window.isOpaque = false
window.backgroundColor = .clear
window.hasShadow = true
window.isMovableByWindowBackground = true

let content = window.contentView!
content.wantsLayer = true
content.layer!.cornerRadius = 14

let phaseLabel = NSTextField(labelWithString: "")
phaseLabel.font = .systemFont(ofSize: 14, weight: .bold)
phaseLabel.textColor = .white
phaseLabel.alignment = .center

let timeLabel = NSTextField(labelWithString: "")
timeLabel.font = .monospacedDigitSystemFont(ofSize: 34, weight: .bold)
timeLabel.textColor = .white
timeLabel.alignment = .center

let stack = NSStackView(views: [phaseLabel, timeLabel])
stack.orientation = .vertical
stack.spacing = 2
stack.translatesAutoresizingMaskIntoConstraints = false
window.contentView!.addSubview(stack)
NSLayoutConstraint.activate([
    stack.centerXAnchor.constraint(equalTo: window.contentView!.centerXAnchor),
    stack.centerYAnchor.constraint(equalTo: window.contentView!.centerYAnchor),
])

var onBreak = false
var phaseEnd = Date()
var paused = false
var pausedRemaining: TimeInterval = 0

@MainActor func startPhase(_ isBreak: Bool) {
    onBreak = isBreak
    phaseEnd = Date().addingTimeInterval((isBreak ? breakMin : workMin) * 60)
    phaseLabel.stringValue = isBreak ? "BREAK" : "WORK"
    window.contentView!.layer!.backgroundColor = (isBreak ? breakColor : workColor).cgColor
}

@MainActor func togglePause() {
    paused.toggle()
    if paused {
        pausedRemaining = max(phaseEnd.timeIntervalSinceNow, 0)
        phaseLabel.stringValue = "PAUSED"
        content.layer!.backgroundColor = NSColor(white: 0.45, alpha: 1).cgColor
    } else {
        phaseEnd = Date().addingTimeInterval(pausedRemaining)
        phaseLabel.stringValue = onBreak ? "BREAK" : "WORK"
        content.layer!.backgroundColor = (onBreak ? breakColor : workColor).cgColor
    }
}

@MainActor func tick() {
    if paused { return }
    var remaining = phaseEnd.timeIntervalSinceNow
    if remaining <= 0 {
        NSSound.beep()
        startPhase(!onBreak)
        remaining = phaseEnd.timeIntervalSinceNow
    }
    let total = Int(remaining.rounded(.up))
    timeLabel.stringValue = String(format: "%02d:%02d", total / 60, total % 60)
}

@MainActor final class ClickHandler: NSObject {
    @objc func click(_ sender: NSClickGestureRecognizer) { togglePause() }
}
let clickHandler = MainActor.assumeIsolated { ClickHandler() }

MainActor.assumeIsolated {
    startPhase(false)
    tick()
    content.addGestureRecognizer(
        NSClickGestureRecognizer(target: clickHandler, action: #selector(ClickHandler.click(_:))))
}
Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
    MainActor.assumeIsolated { tick() }
}

NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification,
                                       object: window, queue: .main) { _ in exit(0) }

signal(SIGINT, SIG_IGN)
let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigint.setEventHandler { exit(0) }
sigint.resume()

window.makeKeyAndOrderFront(nil)
app.run()
