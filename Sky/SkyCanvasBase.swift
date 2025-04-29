// created by musesum on 7/30/24

import SwiftUI
import MuFlo
import MuAudio
import MuSky
import MuVision
import MuMenu
import MuPeer

class SkyCanvasBase {

    private let archive: SkyArchive
    private let muAudio: MuAudio!
    private let drawDot: DrawDot
    private let drawPal: DrawPal
    private let ripples: Ripples
    private let touchCanvas: TouchCanvas
    private let peers: Peers

    public let root˚: Flo
    public let pipeline: SkyPipeline
    public let touchView: TouchView
    public let touchDraw: TouchDraw
    public let nextFrame: NextFrame
    public let archiveVm: ArchiveVm

    public var renderState = RenderDepth.state
    public var stateFrame = [RenderState: CGRect]()

    init(_ root˚: Flo,
         _ archiveVm: ArchiveVm,
         _ peers: Peers,
         _ scale: CGFloat,
         _ bounds: CGRect) {

        self.root˚ = root˚
        self.archiveVm = archiveVm
        self.nextFrame = archiveVm.nextFrame
        self.peers = peers
        self.ripples = Ripples()
        archive = SkyArchive(root˚, nextFrame)
        muAudio = MuAudio(root˚, peers)
        touchDraw = TouchDraw(root˚, scale)
        pipeline = SkyPipeline(root˚, archive, touchDraw, scale, bounds, ripples)
        touchCanvas = TouchCanvas(touchDraw, peers)
        drawDot = DrawDot(root˚, "sky.draw.dot", touchCanvas, touchDraw, archive)
        drawPal = DrawPal(root˚, "sky.draw.ripple", touchCanvas, touchDraw, archive, ripples)
        touchView = TouchView(pipeline, touchCanvas)

        archiveVm.archiveProto = self
        nextFrame.addBetweenFrame {
            self.pipeline.alignTextures()
        }
    }
}

extension SkyCanvasBase: ArchiveProto {

    func readUserArchive(_ url: URL, _ nextFrame: NextFrame, local: Bool) {

        archive.readUrl(url, nextFrame, local: local)
        let archName = url.deletingPathExtension().lastPathComponent
        DebugLog { P("🏛️ \"\(archName)\" \(local ? "local" : "remote")") }
        nextFrame.addBetweenFrame {
            self.pipeline.alignNameTex()
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

                let pipeNode˚ = pipeNode.pipeNode˚
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
                    if let on = pipeChild.pipeNode˚.val("on"), on > 0 {
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
