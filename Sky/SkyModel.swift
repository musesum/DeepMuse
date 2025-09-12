// created by musesum on 7/30/24

import SwiftUI
import MuFlo
import MuAudio
import MuSky
import MuVision
import MuMenu
import MuPeers
import MuHands

@MainActor
class SkyModel {

    private let archive: SkyArchive
    private let muAudio: MuAudio!
    private let drawDot: DrawDot
    private let drawPal: DrawPal
    private let ripples: Ripples
    private let camera: CameraSession
    private let peers: Peers
    private let tapeFlo: TapeFlo
    private let share: Share

    internal var insets = EdgeInsets()
    internal let scale: CGFloat

    public let root˚: Flo
    public let pipeline: SkyPipeline
    public let touchCanvas: TouchCanvas
    public let touchDraw: TouchDraw
    public let nextFrame: NextFrame
    public let archiveVm: ArchiveVm
    public var touchView: TouchView
    public var handsPhase: HandsPhase
    public var menus: Menus

    public var renderState: RenderState
    public var stateFrame = [RenderState: CGRect]()

    init(_ root˚: Flo,
         _ renderState: RenderState,
         _ archiveVm: ArchiveVm,
         _ peers: Peers,
         _ scale: CGFloat,
         _ bounds: CGRect,
         _ camera: CameraSession) {

        self.root˚ = root˚
        self.renderState = renderState
        self.archiveVm = archiveVm
        self.nextFrame = archiveVm.nextFrame
        self.scale = scale 
        self.peers = peers
        self.ripples = Ripples()
        self.archive = SkyArchive(root˚, nextFrame)
        self.tapeFlo = TapeFlo(root˚)
        self.share = Share(peers, tapeFlo)
        self.muAudio = MuAudio(root˚, share)
        self.touchDraw = TouchDraw(root˚,scale)
        self.camera = camera
        self.touchCanvas = TouchCanvas(touchDraw, scale, share)
        self.pipeline = SkyPipeline(root˚, renderState, archive, touchDraw, scale, bounds, ripples, camera, touchCanvas, archiveVm.nextFrame)
        self.drawDot = DrawDot(root˚, "sky.draw.dot", touchCanvas)
        self.drawPal = DrawPal(root˚, "sky.draw.ripple", touchCanvas, ripples)
        self.touchView = TouchView(pipeline, touchCanvas)
        self.handsPhase = HandsPhase(root˚)
        self.menus = Menus(root˚, archiveVm, handsPhase, share)

        archiveVm.archiveProto = self
        peers.addDelegate(self, for: .archiveFrame)
    }
}

extension SkyModel: @MainActor ArchiveProto {

    func readUserArchive(_ url: URL, _ nextFrame: NextFrame, local: Bool) {
        
        archive.readUrl(url, nextFrame, local: local)
        let archName = url.deletingPathExtension().lastPathComponent
        DebugLog { P("🏛️ \"\(archName)\" \(local ? "local" : "remote")") }

        if local {
            shareItem(url)
        }
    }

    func shareItem(_ url: URL) {
        Task {
            guard let data = try? Data(contentsOf: url) else {
                return PrintLog("⁉️ Error reading archive file")
            }
            await peers.sendItem(.archiveFrame) {
                (try? JSONEncoder().encode(ArchiveFrame(url: url, data: data))) ?? {
                    PrintLog("⁉️ Error encoding archive frame")
                    return nil
                }()
            }
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

                        //  new save texture as png
                        if let pngData = textureToPngData(childTex) {
                            archiveExt.addName(path, ext: "png", data: pngData)
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

extension SkyModel: @MainActor PeersDelegate {
    
    public func received(data: Data) {
        if let archiveFrame = try? JSONDecoder().decode(ArchiveFrame.self, from: data) {
            // Save the received archive data to a temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let tempUrl = tempDir.appendingPathComponent(archiveFrame.name).appendingPathExtension("mu")
            
            do {
                try archiveFrame.data.write(to: tempUrl)
                // Process the archive as a remote archive
                readUserArchive(tempUrl, nextFrame, local: false)
            } catch {
                PrintLog("⁉️ Error saving received archive: \(error)")
            }
        }
    }
}
