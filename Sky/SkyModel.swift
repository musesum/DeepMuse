// created by musesum on 7/30/24

import SwiftUI
import MuFlo
import MuAudio
import MuSky
import MuVision
import MuMenu
import MuPeers
import MuHands

@MainActor @Observable public final class StartupState {
    public var menusReady = false
    public var done = false
}

@MainActor
class SkyModel {
    public static var shared = SkyModel()

    public let startup = StartupState()

    private let archive: SkyArchive
    public private(set) var muAudio: MuAudio?
    private let drawDot: DrawDot
    private let drawPal: DrawPal
    private let ripples: Ripples
    private let camera: CameraSession
    private let tapeFlo: TapeFlo
    private let beatClock: BeatClock

    internal var insets = EdgeInsets()
    internal let scale: CGFloat

    private var pairMix˚: Flo?           // pipe.color.pairMix, bound at the first frame
    private var warrenRule˚: Flo?        // pipe.cell.rule.warren, the node the solo switches
    private var warrenVersion˚: Flo?     // pipe.cell.rule.warren.version, the row selector
    private var warrenReseed˚: Flo?      // pipe.cell.rule.warren.reseed, the entry pulse
    private var pairMixTries = 0         // bind attempts, one per frame, capped below
    private var pairRowWas = 0           // last (on && 10/11) row seen; 0 when warren owns neither
    private var reseedLit = false        // pulse raised on the previous frame, cleared on this one

    public let root˚: Flo
    public let pipeline: SkyPipeline
    public let touchCanvas: TouchCanvas
    public let touchDraw: TouchDraw
    public let archiveVm: ArchiveVm
    public var touchView: TouchView
    public var handsPhase: HandsPhase
    public var menus: Menus
    public var menuView: MenuView

    public var renderState: RenderState
    public var stateFrame = [RenderState: CGRect]()
    #if os(iOS)
    private var cameraPinch: CameraPinch?
    private var pencilInput: PencilInput?
    #endif

    init() {

        #if os(visionOS)
        let bounds = CGRect.zero
        self.scale = CGFloat(3)
        #else
        let bounds = UIScreen.main.bounds
        self.scale = UIScreen.main.scale
        #endif


        self.root˚ = Flo("√")
        self.archiveVm = ArchiveVm()
        self.renderState = .windowed
        self.ripples = Ripples()
        self.archive = SkyArchive(root˚)
        self.tapeFlo = TapeFlo(root˚)
        Peers.shared.setupPeers(tapeFlo)
        // sequencer leaf reads the deck through this seam (MuMenu owns no TapeFlo)
        LeafSequencerVm.tape = { [tapeFlo] in tapeFlo }
        self.touchDraw = TouchDraw(root˚,scale)
        self.camera = CameraSession()
        self.touchCanvas = TouchCanvas(touchDraw, scale)
        self.pipeline = SkyPipeline(root˚, renderState, archive, touchDraw, scale, bounds, ripples, camera, touchCanvas)
        pipeline.bindEmbeds()
        self.drawDot = DrawDot(root˚, "canvas.dot", touchCanvas)
        self.drawPal = DrawPal(root˚, "canvas.ripple", touchCanvas, ripples)
        self.touchView = TouchView(pipeline, touchCanvas)
        self.handsPhase = HandsPhase(root˚)
        self.menus = Menus(root˚, archiveVm, handsPhase, startHidden: true)
        self.menuView = MenuView(menus.menuVms)
        self.beatClock = BeatClock(root˚)
        StripPicker.install()
        archiveVm.archiveProto = self
        bindCodeLeaf()
        Peers.shared.addDelegate(self, for: .archiveFrame)
        #if os(iOS)
        self.cameraPinch = CameraPinch(touchView, root˚)
        self.pencilInput = PencilInput(touchView, root˚)
        #endif
    }
    /// route editor submits into the runtime shader compiler
    private func bindCodeLeaf() {
        LeafCodeVm.compiler = { [weak self] body, flo, done in
            guard let self, let node = self.codeNode(flo) else {
                return done([CodeError(0, line: 1, col: 0, message: "no pipe node for \(flo.path())")])
            }
            self.pipeline.compileEmbed(node, body: body) { errors in
                done(errors.enumerated().map {
                    CodeError($0, line: $1.line, col: $1.col, message: $1.message) })
            }
        }
        LeafCodeVm.seed = { [weak self] flo in
            guard let self,
                  let node = self.codeNode(flo),
                  let fileName = node.shader?.fileName,
                  let template = MuVision.read(fileName, "metal")
            else { return nil }
            return Shader.templateBody(template)
        }
    }
    /// `{{ @<file.metal> }}` names the shader; pipe flos still match by identity
    private func codeNode(_ flo: Flo) -> PipeNode? {
        if let fileRef = flo.embed?.fileRef {
            let fileName = (fileRef as NSString).deletingPathExtension
            return pipeline.pipeNode(fileName: fileName)
        }
        return pipeline.pipeNode(for: flo)
    }

    func loadAudio() {   // deferred: CoreMIDI open ~828ms, post-interactive
        guard muAudio == nil else { return }
        let audio = MuAudio(root˚)
        muAudio = audio
        // live mic → wave scatter kernel: WaveNode pulls mag/fft per frame;
        // mic.input vf leaf gates the tap (y volume 0 = off, w band-pass)
        WaveNode.audioTap = { [micTap = audio.micTap] in (micTap.mag, micTap.fft) }
        // mic.input scope: green PCM line pulls the same sample window
        LeafVfVm.pcm = { [micTap = audio.micTap] in micTap.mag }
        // music midi leaf, mic mode: FFT bins → note grid; raw samples give
        // ABSOLUTE loudness (the bins are per-buffer normalized)
        LeafMidiVm.fftBins = { [micTap = audio.micTap] in micTap.fft }
        LeafMidiVm.micRaw = { [micTap = audio.micTap] in micTap.mag }
        // sim harness: CoreMIDI does not bridge host virtual sources into
        // the simulator — replay a scripted sequence into the midi flo
        // nodes (the exact writes MidiFlo performs) when launched with it
        if ProcessInfo.processInfo.arguments.contains("-midiTestPulse") {
            midiTestPulse()
        }
    }

    /// arg-gated note/aftertouch pulse for simulator verification
    private func midiTestPulse() {
        guard let on˚  = root˚.findPath("midi.input.note.on"),
              let off˚ = root˚.findPath("midi.input.note.off"),
              let at˚  = root˚.findPath("midi.input.afterTouch") else { return }
        func write(_ flo: Flo, _ names: [(String, Double)]) {
            flo.setNameNums(names, .fire, Visitor(0, .midi))
        }
        let notes: [(Double, Double)] = [(5, 30), (45, 60), (60, 80),
                                         (69, 100), (108, 120), (126, 127)]
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 25_000_000_000) // menus first
            while true {                                       // cycle forever
                for (n, v) in notes {
                    write(on˚, [("num", n), ("velo", v), ("chan", 1), ("port", 0), ("time", 0)])
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                for a in stride(from: 10.0, through: 127, by: 8) {  // grow 69
                    write(at˚, [("num", 69), ("val", a), ("chan", 1), ("port", 0), ("time", 0)])
                    try? await Task.sleep(nanoseconds: 90_000_000)
                }
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                for a in stride(from: 127.0, through: 10, by: -12) { // shrink 69
                    write(at˚, [("num", 69), ("val", a), ("chan", 1), ("port", 0), ("time", 0)])
                    try? await Task.sleep(nanoseconds: 90_000_000)
                }
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                for (n, _) in notes.prefix(3) {                      // clear the low three
                    write(off˚, [("num", n), ("velo", 0), ("chan", 1), ("port", 0), ("time", 0)])
                    try? await Task.sleep(nanoseconds: 150_000_000)
                }
                try? await Task.sleep(nanoseconds: 5_000_000_000)    // three held, then reset
                for (n, _) in notes {
                    write(off˚, [("num", n), ("velo", 0), ("chan", 1), ("port", 0), ("time", 0)])
                }
                try? await Task.sleep(nanoseconds: 4_000_000_000)
            }
        }
    }
    // warren rows 10 and 11 store two occupants per pixel; the colour stage reads
    // both only when pipe.color.pairMix is set. bound after the flo parse, never
    // from init: a closure added in init fires before the menus exist. retried once
    // a frame until the paths resolve, since the parse may lag the first frame.
    // the flag is then re-read every frame rather than from a closure on the warren
    // node. the rule tree solos through `*(-> *(on 0))`, and that set activates the
    // closures of exactly one sibling, picked by dictionary order — which sibling is
    // not fixed across runs, so a closure can miss the switch and leave the flag at 1
    // over a rule warren does not own. reading two values a frame cannot miss.
    static let pairMixTryCap = 120
    func syncPairMix() {
        if pairMix˚ == nil { bindPairMix() } else { setPairMix() }
    }
    private func bindPairMix() {
        guard pairMix˚ == nil, pairMixTries < Self.pairMixTryCap else { return }
        pairMixTries += 1
        guard let warren˚ = root˚.findPath("pipe.cell.rule.warren"),
              let version˚ = warren˚.findPath("version"),
              let seed˚ = warren˚.findPath("reseed"),
              let mix˚ = root˚.findPath("pipe.color.pairMix") else {
            if pairMixTries == Self.pairMixTryCap {
                PrintLog("⁉️ bindPairMix unbound after \(Self.pairMixTryCap) frames")
            }
            return
        }
        pairMix˚ = mix˚
        warrenRule˚ = warren˚
        warrenVersion˚ = version˚
        warrenReseed˚ = seed˚
        setPairMix()
    }
    private func setPairMix() {
        guard let pairMix˚, let warrenRule˚, let warrenVersion˚ else { return }
        let on = (warrenRule˚.val("on") ?? 0) > 0
        let version = Int(((warrenVersion˚.val("x") ?? 0)).rounded())
        let mix = (on && (version == 10 || version == 11)) ? 1.0 : 0.0
        setReseed(mix > 0 ? version : 0)
        guard pairMix˚.val("x") != mix else { return }
        DebugLog { P("🎨 pairMix \(mix) warren v\(version) on \(on)") }
        pairMix˚.setNameNums([("x", mix)], .fire, Visitor(0, .model))
    }
    // rows 10 and 11 are entered by a rule switch, so the incoming texture is the
    // previous rule's leftover; decoded as pair form it freezes the run. One rendered
    // frame of reseed packs that picture into a fresh run. Raised on the transition
    // into a row this rule owns, from any other state -- launch straight into 10 or 11
    // included -- and on a move between the two rows, which is a new run on the
    // projected picture. Cleared on the next frame, so the pulse is exactly one frame:
    // held longer it would re-derive from the lane form it just wrote and halve values.
    private func setReseed(_ row: Int) {
        guard let warrenReseed˚ else { return }
        let enter = row > 0 && row != pairRowWas
        pairRowWas = row
        guard enter || reseedLit else { return }
        let pulse = enter ? 1.0 : 0.0
        reseedLit = enter
        DebugLog { P("🌱 warren reseed \(pulse) v\(row)") }
        warrenReseed˚.setNameNums([("x", pulse)], .fire, Visitor(0, .model))
    }
    public func setFrame(_ frame: CGRect,
                         _ insets: EdgeInsets,
                         onAppear: Bool) {

        DebugLog { P("🧭 menuFrame\(frame.digits())") }
        let pinXY = CGPoint(x: frame.midX, y: frame.midY) /// safe-area center, matches spinner
        let width = frame.width + insets.leading + insets.trailing
        let height = frame.height + insets.top + insets.bottom
        let size = CGSize(width: width, height: height)

        let drawableSize = size * scale  // layer.drawableSize
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        touchView.frame = frame
        touchCanvas.drawableSize = drawableSize
        pipeline.resizeFrame(frame, drawableSize, scale, onAppear)
        if !startup.menusReady { Task { @MainActor in self.startup.menusReady = true } }  // one-turn hop, never sync in first commit
        if !startup.done {
            for menuVm in menus.menuVms {
                menuVm.rootVm.cornerVm.setStartupCenter(pinXY)
            }
        }
    }
}

extension SkyModel: @MainActor ArchiveProto {

    func readUserArchive(_ url: URL, local: Bool) {

        archive.readUrl(url, local: local)
        let archName = url.deletingPathExtension().lastPathComponent
        DebugLog { P("🏛️ \"\(archName)\" \(local ? "local" : "remote")") }
        NextFrame.shared.addBetweenFrame {
            self.pipeline.alignNameTex()
            Reset.reset()
        }
        if local {
            shareItem(url)
        }
    }


    // snapshot on framebuffer, draw Texture and skyGraph
    public func saveArchive(_ title: String,
                            _ description: String,
                            _ completion: @escaping CallVoid) {

        // setup temp filename with current time
        let time = trunc(Date().timeIntervalSince1970)
        let tempName = title + ".\(time)"
        guard let archiveExt = ArchiveZip(tempName, "mu", .create) else { return }

        // save framebuffer state and allow transfer to cpu memory
        let frameBufferOnly = pipeline.layer.framebufferOnly
        pipeline.layer.framebufferOnly = false

        addScreenIcon() // make icon from an image snapshot of framebuffer
        saveTextures()  // MetNodeDraws output texture as `.tex`

        // restore prior framebuffer state
        pipeline.layer.framebufferOnly = frameBufferOnly

        // save snapshot of flo graph
        saveFloScript("now", scriptOps: .Now)
        saveFloScript("full", scriptOps: .Full) //.....
        archiveExt.replace(title, with: tempName)

        completion()

        // save 256x256 snapshot for AchivePicker thumbnail
        func addScreenIcon() {

            if let pipeSource = pipeline.pipeSource,
               let image = pipeSource.cgImage {

                let uiImage = UIImage(cgImage: image)
                    .roundIcon(diameter: 256, corner: 32)
                if let data = uiImage?.pngData() {
                    archiveExt.addName("icon", ext: "png", data: data)
                }
            }
        }

        // save achive textures needed to reconstruct pipeline state
        func saveTextures() {

            // save only first occurance of texture
            var saved = Set<Int>()

            // from beginning node of pipeline
            savePipe(pipeline.pipeSource)

            // recursively scan pipeline tree for archive textures
            func savePipe(_ pipeNode: PipeNode?) {

                guard let pipeNode else { return }

                let pipeNode˚ = pipeNode.pipeFlo˚
                for child in pipeNode˚.children {

                    // found a new achive texture
                    if child.passthrough == false,
                       let childTex = child.texture,
                       child.hasExpr("archive"),
                       !saved.contains(childTex.hash)
                    {
                        // register as a found texture
                        saved.insert(childTex.hash)
                        let path = child.path(3)
                        DebugLog { P("🏛️ \(#function) \(path)") }

                        //  save texture as png in texture/ subdirectory
                        if let pngData = textureToPngData(childTex) {
                            archiveExt.addName("texture/" + path, ext: "png", data: pngData)
                        }
                    }
                }
                // parse the child node parts of pipeline tree
                for pipeChild in pipeNode.pipeChildren {
                    // `on` == 1 is the active part of a pipeline
                    // `on` == 0 can be skipped
                    if let on = pipeChild.pipeFlo˚.val("on"), on > 0 {
                        savePipe(pipeChild)
                    }
                }
            }
        }

        func saveFloScript(_ name: String, scriptOps: FloScriptOps) {

            let script = root˚.scriptRoot(scriptOps)
            let dataNow = Data(script.utf8)
            archiveExt.addName(name,  ext: "flo.h", data: dataNow)
        }
    }

}

#if os(iOS)
/// Pinch on the canvas zooms the camera lens (`pipe.camera.zoom`) while the
/// camera streams; simultaneous recognition keeps menu + canvas touches intact.
@MainActor
final class CameraPinch: NSObject, UIGestureRecognizerDelegate {

    private let camera˚ : Flo?
    private let zoom˚   : Flo?
    private var baseZoom = CGFloat(1)

    init(_ touchView: UIView, _ root˚: Flo) {
        camera˚ = root˚.findPath("pipe.camera")
        zoom˚   = root˚.findPath("pipe.camera.zoom")
        super.init()
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        pinch.cancelsTouchesInView = false
        pinch.delegate = self
        touchView.addGestureRecognizer(pinch)
    }
    @objc private func pinched(_ pinch: UIPinchGestureRecognizer) {
        guard let on = camera˚?.val("on"), on > 0 else { return }
        switch pinch.state {
        case .began   : baseZoom = CGFloat(zoom˚?.val("x") ?? 1)
        case .changed : zoom˚?.setNameNums([("x", Double(baseZoom * pinch.scale))], .fire, Visitor(0, .user))
        default       : break
        }
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

/// Apple Pencil double tap and squeeze on the canvas. Both pulse a
/// `sky.input.pencil` node whose flo edge sets `swap` or `fold` on canvas:
/// the menu shows the paint leaf shown last, swaps canvas.real and
/// canvas.false, or dismisses the one that is up. The leaf shown is the
/// layer drawn on -- the menu writes canvas.brush.paint w, not this -- so
/// the tap is the Pencil "switch tool" gesture. The system preference wins:
/// a user who set either gesture to Ignore in Settings gets nothing here
@MainActor
final class PencilInput: NSObject, UIPencilInteractionDelegate {

    private let tap˚     : Flo?
    private let squeeze˚ : Flo?
    private var interaction: UIPencilInteraction?

    init(_ touchView: UIView, _ root˚: Flo) {
        tap˚     = root˚.findPath("sky.input.pencil.tap")
        squeeze˚ = root˚.findPath("sky.input.pencil.squeeze")
        super.init()
        let interaction = UIPencilInteraction()
        interaction.delegate = self
        interaction.isEnabled = true
        touchView.addInteraction(interaction)
        self.interaction = interaction
    }
    func pencilInteraction(_ interaction: UIPencilInteraction,
                           didReceiveTap tap: UIPencilInteraction.Tap) {
        guard UIPencilInteraction.preferredTapAction != .ignore else { return }
        tap˚?.setNameNums([("x", 1)], .fire, Visitor(0, .user))
        // a pulse, not a state: back to 0 silently, so a snapshot never
        // saves x 1 and an archive merge never refires the swap edge
        tap˚?.setNameNums([("x", 0)], .sneak, Visitor(0))
    }
    func pencilInteraction(_ interaction: UIPencilInteraction,
                           didReceiveSqueeze squeeze: UIPencilInteraction.Squeeze) {
        guard UIPencilInteraction.preferredSqueezeAction != .ignore else { return }
        switch squeeze.phase {
        case .began             : squeeze˚?.setNameNums([("x", 1)], .fire, Visitor(0, .user))
        case .ended, .cancelled : squeeze˚?.setNameNums([("x", 0)], .fire, Visitor(0, .user))
        default                 : break
        }
    }
}
#endif

extension SkyModel: @MainActor PeersDelegate {
    
    public func received(data: Data, from: DataFrom) {
        if let archiveFrame = try? JSONDecoder().decode(ArchiveFrame.self, from: data) {
            // Save the received archive data to a temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let tempUrl = tempDir.appendingPathComponent(archiveFrame.name).appendingPathExtension("mu")
            
            do {
                try archiveFrame.data.write(to: tempUrl)
                // Process the archive as a remote archive
                readUserArchive(tempUrl, local: false)
            } catch {
                PrintLog("⁉️ Error saving received archive: \(error)")
            }
        }
    }
    public func resetItem(_ item: PlayItem) {
    }
    public func playItem(_ item: PlayItem, from: DataFrom) {
        received(data: item.data, from: from)
    }
    public func dropped(from: DataFrom) {
        //PrintLog("📡 SkyModel dropped")
    }
    public func shareItem(_ item: Any) {
        guard let url = item as? URL else { return }
        Task {
            guard let data = try? Data(contentsOf: url) else {
                return PrintLog("⁉️ Error reading archive file")
            }
            await Peers.shared.sendItem(.archiveFrame) {
                (try? JSONEncoder().encode(ArchiveFrame(url: url, data: data))) ?? {
                    PrintLog("⁉️ Error encoding archive frame")
                    return nil
                }()
            }
        }
    }

}
