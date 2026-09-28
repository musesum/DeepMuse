// created by musesum on 9/9/26

import QuartzCore
import MuFlo

/// four beat bar, WinSky time/Beat.cpp port: each column tap-records its own
/// beat table, plays or pauses it, and writes `out` = amp × (1 − now/span)
/// per frame; sync restarts the four together. A column nobody has touched
/// is idle: it writes no `out` at all, so an unused beat never shows as
/// active in the graph or fires its edges
@MainActor
final class BeatClock {

    /// one column: table of beat times in seconds from the first tap
    final class Beat {
        var beats = [0.0, 0.5]     // default 120 bpm, one beat
        var beatNow = 1
        var time = 0.0
        var recording = false
        var playing = false        // the script's `play` value, read at init
        /// a rec tap or a play tap from a person, a peer or midi; the clock's
        /// own toggling and a snapshot restore leave a column idle
        var used = false
        var recStart = 0.0
        var amp = 1.0
        var out = 0.0              // the value `out` last carried
        var beatMax: Int { beats.count - 1 }

        /// first tap starts a new table, later taps add a beat
        func rec(_ now: Double) {
            used = true
            if !recording {
                recording = true
                playing = false
                recStart = now
                beats = [0]
            } else {
                let t = now - recStart
                if t - (beats.last ?? 0) > 0.02 { beats.append(t) }
            }
        }
        /// recording closes on the play tap: the last mark ends the table
        func play(_ now: Double) {
            if recording {
                recording = false
                var t = now - recStart
                if t - (beats.last ?? 0) < 0.02 { t = (beats.last ?? 0) + 0.5 }
                beats.append(t)
            }
            playing = true
            beatNow = 1
            time = 0
        }
        func pause() { playing = false }

        /// recording → play; playing → back to beat one
        func sync(_ now: Double) {
            if recording { play(now) }
            else if playing { beatNow = 1; time = 0 }
        }
        /// advance the clock; out pulses at each beat and decays across it.
        /// an idle or paused column reads 0
        func go(_ dt: Double) -> Double {
            guard used, playing, beatMax >= 1 else { return 0 }
            time += dt
            while time > beats[beatNow] {
                beatNow += 1
                if beatNow > beatMax {
                    beatNow = 1
                    time -= beats[beatMax]
                }
            }
            let span = max(0.001, beats[beatNow] - beats[beatNow - 1])
            let now = time - beats[beatNow - 1]
            return amp * max(0, 1 - now / span)
        }
    }

    private var columns = [Beat]()
    private var outs = [Flo]()
    private var plays = [Flo]()
    private var lastTime = CACurrentMediaTime()
    private var link: CADisplayLink?

    init(_ root˚: Flo) {
        let beat˚ = root˚.bind("sky.beat")
        for name in ["one", "two", "three", "four"] {
            let column = Beat()
            let col˚ = beat˚.bind(name)
            columns.append(column)
            _ = col˚.bind("rec") { f, visit in
                // a tap is one-shot: a snapshot restore must not replay it
                guard f.float > 0.5, !visit.type.has(.archive) else { return }
                self.rec(column)
            }
            plays.append(col˚.bind("play") { f, visit in
                if f.float > 0.5 { column.play(CACurrentMediaTime()) } else { column.pause() }
                // the `<>` edge from the menu adds .model to a user's visit,
                // so test for the sources that mean a person meant it
                if visit.type.has([.user, .remote, .midi, .canvas, .pinch]) { column.used = true }
            })
            _ = col˚.bind("amp") { f,_ in column.amp = Double(f.float) }
            // the snapshot merged before this bind: read the restored values
            // here, so a column saved paused (`play(x : 0)`) stays paused
            column.amp = Double(col˚.findPath("amp")?.float ?? 1)
            column.playing = (col˚.findPath("play")?.float ?? 1) > 0.5
            outs.append(col˚.bind("out"))
        }
        _ = beat˚.bind("sync") { f, visit in
            guard f.float > 0.5, !visit.type.has(.archive) else { return }
            let now = CACurrentMediaTime()
            for (i, column) in self.columns.enumerated() {
                let wasRecording = column.recording
                column.sync(now)
                if wasRecording { self.plays[i].setNameNums([("x", 1)], .fire, Visitor(0, .model)) }
            }
        }
        link = CADisplayLink(target: self, selector: #selector(tick))
        link?.add(to: .main, forMode: .common)
    }

    /// a rec tap pauses the column's play toggle until play is tapped
    private func rec(_ column: Beat) {
        let wasRecording = column.recording
        column.rec(CACurrentMediaTime())
        if !wasRecording, let i = columns.firstIndex(where: { $0 === column }) {
            plays[i].setNameNums([("x", 0)], .fire, Visitor(0, .model))
        }
        DebugLog { P("🥁 beat rec \(column.beats.count) marks") }
    }

    @objc private func tick() {
        let now = CACurrentMediaTime()
        let dt = min(0.1, now - lastTime)
        lastTime = now
        for (i, column) in columns.enumerated() {
            let out = column.go(dt)
            // say it only when it changes: a playing column moves every
            // frame, a paused one drops to 0 once, an idle one never speaks
            guard out != column.out else { continue }
            column.out = out
            outs[i].setNameNums([("x", out)], .fire, Visitor(0, .model))
        }
    }
}
