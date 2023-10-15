//  SkyVm.swift
//  created by musesum on 8/25/23.


import SwiftUI

import MuMenu
import MuAudio // MuMidi
import MuSkyFlo // bundle
import MuFlo
import MuMetal // saveSkyArchive

class SkyVm {
    static var shared = SkyVm()
    var midi: MuMidi?
    var pipeline: SkyPipeline?

    let archive = FloArchive(bundle: MuSkyFlo.bundle,
                             archive: "Snapshot",
                             scripts:  ["sky", "shader", "model", "menu", "plato", "cube", "midi", "corner"],
                             textures: ["draw"])

    var touchView: SkyTouchView!
    var settingUp = true
#if os(xrOS)
    let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
#else
    let bounds = UIScreen.main.bounds
#endif

    init() {
        midi = MuMidi(root: archive.root˚)
        if let midi {
            TouchMidi.touchRemote = midi
        }
        _ = MuAudio.shared // MuAudio.shared.test()
        pipeline = SkyPipeline(bounds, archive.root˚)
        TouchCanvas.shared.touchFlo.parseRoot(archive.root˚, archive)
        touchView = SkyTouchView(bounds)
        NextFrame.shared.addFrameDelegate("SkyVm".hash, self)
    }
    // snapshot on framebuffer, draw Texture and skyGraph
    public func saveSkyArchive(_ completion: @escaping CallVoid) {
        guard let pipeline else { return }

        let time = trunc(Date().timeIntervalSince1970)
        let snapName = archive.archiveName + ".zip"
        let snapTime = archive.archiveName + ".\(time).zip"
        let snapArchive = MuArchive(snapTime)
        let nodeNamed = pipeline.nodeNamed
        let metalLayer = pipeline.metalLayer
        let frameBufferOnly = metalLayer.framebufferOnly

        metalLayer.framebufferOnly = false //  frameBufferOnly

        addScreenIcon() // make icon from an image snapshot of framebuffer
        addDrawTexture()   // MetNodeDraws output texture as `.tex`
        addFloScript()  // snapshot of Sky Graph as flo script
        snapArchive.copy(snapTime, to: snapName)

        metalLayer.framebufferOnly = frameBufferOnly // restore
        completion()

        func addScreenIcon() {
            if let flatmapNode = nodeNamed["flatmap"] as? MetNodeFlatmap,
               let image = flatmapNode.cgImage {

                let uiImage = UIImage(cgImage: image).roundIcon(128)
                if let data = uiImage?.pngData() {
                    snapArchive.add(archive.archiveName + ".png", data: data)
                }
            }
        }

        func addDrawTexture() {
            if  let drawNode = nodeNamed["draw"] as? MetNodeDraw,
                let drawTex = drawNode.outTex {

                let (bytes, totalSize) = drawTex.mtlBytes()
                let data = Data.init(bytes: bytes, count: totalSize)
                snapArchive.add("draw" + ".tex", data: data)
            }
        }

        func addFloScript(_ full: Bool = true) {
            let root = archive.root˚
            let name = archive.archiveName
            if full {
                let scriptFull = root.scriptFull
                let dataFull = Data(scriptFull.utf8)
                print("\n\nscriptDef ⟹\n" )
                print(scriptFull + "\n\n")
                snapArchive.add(name + ".full.flo.h", data: dataFull)
            } else {
                let scriptNow = root.scriptNow
                let dataNow = Data(scriptNow.utf8)
                print("scriptNow ⟹\n" + scriptNow + "\n\n")
                snapArchive.add(name + ".now.flo.h", data: dataNow)
            }
        }
    }

}
extension SkyVm: MenuDelegate {

    func window(bounds: CGRect, insets: EdgeInsets) {

        let width = bounds.width + insets.leading + insets.trailing
        let height = bounds.height + insets.top + insets.bottom
        #if os(xrOS)
        let scale = CGFloat(3) //?? scale
        #else
        let scale = UIScreen.main.scale
        #endif
        let viewSize = CGSize(width: width * scale, height: height * scale)
        TouchCanvas.shared.touchFlo.viewSize = viewSize
        touchView?.frame = CGRect(x: 0, y: 0, width: width, height: height)
        pipeline?.resize(viewSize, scale)
    }
}
extension SkyVm: NextFrameDelegate {

    func nextFrame() -> Bool {
        pipeline?.draw()
        return true
    }
    func cancel(_ key: Int) {
        NextFrame.shared.removeDelegate(key)
    }

}
