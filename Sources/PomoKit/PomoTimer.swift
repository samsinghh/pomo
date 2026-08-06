import Foundation

/// Durations and cycle shape for a pomodoro run.
public struct PomoConfiguration: Sendable {
    public var workDuration: TimeInterval
    public var shortBreakDuration: TimeInterval
    public var longBreakDuration: TimeInterval
    public var sessionsPerCycle: Int

    public init(workMinutes: Double = 25, breakMinutes: Double = 5,
                longBreakMinutes: Double = 15, sessionsPerCycle: Int = 4) {
        workDuration = workMinutes * 60
        shortBreakDuration = breakMinutes * 60
        longBreakDuration = longBreakMinutes * 60
        self.sessionsPerCycle = sessionsPerCycle
    }

    public func duration(of phase: Phase) -> TimeInterval {
        switch phase {
        case .work: workDuration
        case .shortBreak: shortBreakDuration
        case .longBreak: longBreakDuration
        }
    }

    public func nextPhase(after phase: Phase) -> Phase {
        switch phase {
        case .work(let n):
            n >= sessionsPerCycle ? .longBreak : .shortBreak(afterSession: n)
        case .shortBreak(let n):
            .work(session: n + 1)
        case .longBreak:
            .work(session: 1)
        }
    }
}

public enum Phase: Equatable, Sendable {
    case work(session: Int)
    case shortBreak(afterSession: Int)
    case longBreak

    public var isWork: Bool {
        if case .work = self { return true }
        return false
    }

    public func label(sessionsPerCycle: Int) -> String {
        switch self {
        case .work(let n): "WORK \(n)/\(sessionsPerCycle)"
        case .shortBreak: "BREAK"
        case .longBreak: "LONG BREAK"
        }
    }
}

public struct PomoTimer: Sendable {
    public let configuration: PomoConfiguration
    public private(set) var phase: Phase
    public private(set) var isPaused = false

    private var phaseEnd: Date
    private var pausedRemaining: TimeInterval = 0

    public init(configuration: PomoConfiguration, start: Date) {
        self.configuration = configuration
        phase = .work(session: 1)
        phaseEnd = start.addingTimeInterval(configuration.workDuration)
    }

    @discardableResult
    public mutating func advance(to now: Date) -> Int {
        guard !isPaused else { return 0 }
        var transitions = 0
        while now >= phaseEnd {
            phase = configuration.nextPhase(after: phase)
            phaseEnd.addTimeInterval(configuration.duration(of: phase))
            transitions += 1
        }
        return transitions
    }

    public func remaining(at now: Date) -> TimeInterval {
        isPaused ? pausedRemaining : max(phaseEnd.timeIntervalSince(now), 0)
    }

    public mutating func pause(at now: Date) {
        guard !isPaused else { return }
        pausedRemaining = max(phaseEnd.timeIntervalSince(now), 0)
        isPaused = true
    }

    public mutating func resume(at now: Date) {
        guard isPaused else { return }
        phaseEnd = now.addingTimeInterval(pausedRemaining)
        isPaused = false
    }

    public mutating func togglePause(at now: Date) {
        isPaused ? resume(at: now) : pause(at: now)
    }
}

/// "MM:SS", rounding partial seconds up so a fresh phase shows its full length.
public func formatMMSS(_ seconds: TimeInterval) -> String {
    let total = max(Int(seconds.rounded(.up)), 0)
    return String(format: "%02d:%02d", total / 60, total % 60)
}
