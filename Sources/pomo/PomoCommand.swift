import AppKit
import ArgumentParser
import PomoKit

@main
struct PomoCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pomo",
        abstract: "A minimal pomodoro timer for macOS, with a popup timer.",
        version: "1.0.0")

    @Argument(help: "Work minutes.")
    var workMinutes: Double = 25

    @Argument(help: "Break minutes.")
    var breakMinutes: Double = 5

    @Option(name: [.customShort("s"), .customLong("sessions")], help: "Work sessions per cycle.")
    var sessions: Int = 4

    @Option(name: [.customShort("l"), .customLong("long-break")],
            help: "Long break minutes after the last session of a cycle.")
    var longBreak: Double = 15

    func validate() throws {
        guard workMinutes > 0, breakMinutes > 0, longBreak > 0, sessions >= 1 else {
            throw ValidationError("Durations must be > 0 and --sessions at least 1.")
        }
    }

    func run() throws {
        let config = PomoConfiguration(workMinutes: workMinutes, breakMinutes: breakMinutes,
                                       longBreakMinutes: longBreak, sessionsPerCycle: sessions)

        MainActor.assumeIsolated {
            let app = NSApplication.shared
            app.setActivationPolicy(.accessory)

            let controller = PomoApp(configuration: config)
            controller.run()

            signal(SIGINT, SIG_IGN)
            let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
            sigint.setEventHandler { Foundation.exit(0) }
            sigint.resume()

            withExtendedLifetime((controller, sigint)) {
                app.run() 
            }
        }
    }
}
