// created by musesum on 7/30/24

import SwiftUI
import MuFlo
import MuAudio
import MuSky
import MuVision
import MuMenu

class SkyCanvasBase {

    private var midi: MuMidi
    private var settingUp = true
    private var frameNow = CGRect.zero
    private var archive: SkyArchive

    public var pipeline: SkyPipeline
    public var touchesView: TouchesView
    public var renderState = RenderDepth.state
    public var stateFrame = [RenderState: CGRect]()
    public var touchCanvas = TouchCanvas.shared

    init() {
        archive = SkyArchive.shared
        midi = MuMidi(root: Flo.root˚)
        TouchMidi.touchRemote = midi
        _ = MuAudio.shared // MuAudio.shared.test()
        TouchDraw.shared.parseRoot(Flo.root˚, archive)
        pipeline = SkyPipeline(Flo.root˚, archive)

        touchesView = TouchesView(pipeline.pipeSize, touchCanvas)
        touchesView.backgroundColor = .clear
        touchesView.layer.addSublayer(pipeline.layer)
        touchesView.isOpaque = false
        ArchiveVm.shared.archiveProto = self
        NextFrame.shared.addBetweenFrame {
            self.pipeline.alignTextures()
        }
    }
}

extension SkyCanvasBase: ArchiveProto {

    func readUserArchive(_ url: URL, local: Bool) {

        archive.readUrl(url, local: local)
        let archName = url.deletingPathExtension().lastPathComponent
        DebugLog { P("🏛️ \"\(archName)\" \(local ? "local" : "remote")") }
        NextFrame.shared.addBetweenFrame {
            self.pipeline.alignNameTex()
        }
    }

    // snapshot on framebuffer, draw Texture and skyGraph
    public func saveArchive(_ title: String,
                            _ description: String,
                            _ completion: @escaping CallVoid) {

        // setup temp filename with current time
        let time = String(trunc(Date().timeIntervalSince1970))
        let tempName = "\(time).\(title)"
        guard let archiveExt = ArchiveZip(tempName, "mu", .create) else { return }

        // save framebuffer state and allow transfer to cpu memory
        let frameBufferOnly = pipeline.layer.framebufferOnly
        pipeline.layer.framebufferOnly = false

        addScreenIcon() // make icon from an image snapshot of framebuffer
        saveTextures()  // MetNodeDraws output texture as `.tex`

        // restore prior framebuffer state
        pipeline.layer.framebufferOnly = frameBufferOnly

        // save snapshot of flo graph
        // genius saving deltas instead of complete script
        saveFloScript("delta", scriptOps: .Time)
        // saveFloScript("now", scriptOps: .Now)
        saveDescription(description)

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

                let pipeFlo = pipeNode.pipeFlo
                for child in pipeFlo.children {

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
                    if let on = pipeChild.pipeFlo.val("on"), on > 0 {
                        savePipe(pipeChild)
                    }
                }
            }
        }

        func saveFloScript(_ name: String, scriptOps: FloScriptOps) {
            let script = Flo.root˚.scriptRoot(scriptOps)
            let dataNow = Data(script.utf8)
            archiveExt.addName(name,  ext: "flo.h", data: dataNow)
        }
        func saveDescription(_ desciption: String) {
            let dataNow = Data(desciption.utf8)
            archiveExt.addName("description",  ext: "txt", data: dataNow)
        }
    }
}
