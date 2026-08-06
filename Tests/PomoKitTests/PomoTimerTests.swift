import Foundation
import Testing
@testable import PomoKit

private let t0 = Date(timeIntervalSinceReferenceDate: 0)

private func makeTimer(work: Double = 25, brk: Double = 5, long: Double = 15,
                       sessions: Int = 4) -> PomoTimer {
    PomoTimer(configuration: PomoConfiguration(workMinutes: work, breakMinutes: brk,
                                               longBreakMinutes: long,
                                               sessionsPerCycle: sessions),
              start: t0)
}

@Suite struct PomoTimerTests {
    @Test func initialState() {
        let timer = makeTimer()
        #expect(timer.phase == .work(session: 1))
        #expect(timer.remaining(at: t0) == 25 * 60)
        #expect(!timer.isPaused)
    }

    @Test func workTransitionsToShortBreak() {
        var timer = makeTimer()
        #expect(timer.advance(to: t0 + 25 * 60) == 1)
        #expect(timer.phase == .shortBreak(afterSession: 1))
        #expect(timer.remaining(at: t0 + 25 * 60) == 5 * 60)
    }

    @Test func fullCycleSequence() {
        var timer = makeTimer()
        var seen: [Phase] = [timer.phase]
        var now = t0
        for _ in 0..<8 {
            now += timer.remaining(at: now)
            timer.advance(to: now)
            seen.append(timer.phase)
        }
        #expect(seen == [
            .work(session: 1), .shortBreak(afterSession: 1),
            .work(session: 2), .shortBreak(afterSession: 2),
            .work(session: 3), .shortBreak(afterSession: 3),
            .work(session: 4), .longBreak,
            .work(session: 1),  // next cycle
        ])
    }

    @Test func longBreakDuration() {
        var timer = makeTimer()
        // 4 work sessions and 3 short breaks put us at the start of the long break.
        let elapsed = (4 * 25 + 3 * 5) * 60.0
        timer.advance(to: t0 + elapsed)
        #expect(timer.phase == .longBreak)
        #expect(timer.remaining(at: t0 + elapsed) == 15 * 60)
    }

    @Test func multiPhaseCatchUpCarriesOvershoot() {
        var timer = makeTimer()
        // 25 + 5 + 25 minutes crosses 3 boundaries; overshoot 30 s into break 2.
        let now = t0 + (25 + 5 + 25) * 60 + 30
        #expect(timer.advance(to: now) == 3)
        #expect(timer.phase == .shortBreak(afterSession: 2))
        #expect(timer.remaining(at: now) == 5 * 60 - 30)
    }

    @Test func pauseFreezesRemaining() {
        var timer = makeTimer()
        timer.advance(to: t0 + 60)
        timer.pause(at: t0 + 60)
        #expect(timer.isPaused)
        #expect(timer.remaining(at: t0 + 9999) == 24 * 60)
        #expect(timer.advance(to: t0 + 99999) == 0)
        #expect(timer.phase == .work(session: 1))
    }

    @Test func resumeArithmetic() {
        var timer = makeTimer()
        timer.pause(at: t0 + 60)          // 24:00 left
        timer.resume(at: t0 + 500)
        #expect(timer.remaining(at: t0 + 560) == 24 * 60 - 60)
    }

    @Test func pauseAcrossBoundaryDefersTransition() {
        var timer = makeTimer()
        timer.pause(at: t0 + 25 * 60 - 1)  // 1 s of work left
        timer.advance(to: t0 + 25 * 60 + 999)
        #expect(timer.phase == .work(session: 1))
        timer.resume(at: t0 + 5000)
        #expect(timer.advance(to: t0 + 5000.5) == 0)
        #expect(timer.advance(to: t0 + 5001) == 1)
        #expect(timer.phase == .shortBreak(afterSession: 1))
    }

    @Test func fractionalMinutes() {
        var timer = makeTimer(work: 0.1, brk: 0.05)
        #expect(timer.remaining(at: t0) == 6)
        #expect(timer.advance(to: t0 + 6) == 1)
        #expect(timer.phase == .shortBreak(afterSession: 1))
    }

    @Test func singleSessionGoesStraightToLongBreak() {
        var timer = makeTimer(sessions: 1)
        timer.advance(to: t0 + 25 * 60)
        #expect(timer.phase == .longBreak)
    }

    @Test func mmssFormatting() {
        #expect(formatMMSS(1500) == "25:00")
        #expect(formatMMSS(5.2) == "00:06")
        #expect(formatMMSS(0) == "00:00")
        #expect(formatMMSS(-1) == "00:00")
    }

    @Test func phaseLabels() {
        #expect(Phase.work(session: 2).label(sessionsPerCycle: 4) == "WORK 2/4")
        #expect(Phase.shortBreak(afterSession: 1).label(sessionsPerCycle: 4) == "BREAK")
        #expect(Phase.longBreak.label(sessionsPerCycle: 4) == "LONG BREAK")
    }
}
