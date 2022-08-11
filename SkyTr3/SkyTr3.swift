import UIKit
import Tr3
import Par
import MuMetal

class SkyTr3: NSObject {
    
    static let shared = SkyTr3()

    public let root = Tr3("√")
    public var skySize = CGSize(width: 1920, height: 1080)
    public var archive: MuArchive?

    private var screenFillZero˚: Tr3?
    private var screenFillOne˚: Tr3?
    private var touchRepeat˚: Tr3?
    private var scrolling˚: Tr3?
    private var cameraFlip˚: Tr3?
    private var fromSnapshot = true
    
    override init() {
        
        super.init()
        
        // parse Sky Snapshot Or scripts
        if let archive = MuArchive.readArchive("Snapshot.zip") { 
            
            self.archive = archive
            archive.get("Snapshot.tr3.h", 1000000) { data in
                if  let data = data,
                    let script = self.dropRoot(String(data: data, encoding: .utf8)),
                    Tr3Parse.shared.parseScript(self.root, script, whitespace: "\n\t ") {
                    print(script)
                }
                else {
                    self.parseScriptFiles()
                }
            }
            archive.get("Snapshot.tex", 30_000_000) { data in
                if let data = data {
                    print("--- archive.get Snapshot.tex \(data.count)")
                    SkyDraw.shared.textureData = data
                }
                self.initScreenFill()
            }
            self.initCameraFlip()
        }
        else {
            parseScriptFiles()
            initScreenFill()
            initCameraFlip()
        }
    }

    /// fill screen callback to clear universe
    func initScreenFill() {

        func fillDraw(_ value: Float?) {
            if let value = value {
                SkyDraw.shared.fillValue = value
            }
        }
        func repeatDraw(_ value: CGPoint?) {
            if let p = value {
                let touchRepeat = (abs(p.x - 0.5) > 0.001 ||
                                   abs(p.y - 0.5) > 0.001)
                SkyView.shared.touchRepeat = touchRepeat
            }
        }
        if let sky = root.findPath("sky") {
        
            screenFillZero˚ = sky.findPath("draw.screen.fillZero")
            screenFillZero˚?.addClosure { tr3, _ in fillDraw(tr3.FloatVal()) }

            screenFillOne˚ = sky.findPath("draw.screen.fillOne")
            screenFillOne˚?.addClosure { tr3, _ in fillDraw(tr3.FloatVal()) }
            
            scrolling˚ = sky.findPath("shader.draws.buffer.scroll")
            scrolling˚?.addClosure { tr3, _ in repeatDraw(tr3.CGPointVal()) }
        }
        else {
            print("🚫 missing path: '√.sky'")
        }
    }

    func initCameraFlip() {
        let camera = root.findPath("sky.shader.camera")
        cameraFlip˚ = camera?.findPath("flip") ?? nil
        cameraFlip˚?.addClosure  { tr3, _ in CameraSession.shared.flipCamera() }
    }

    /// remove ove leading "√ { \n" from script file if it exists
    func dropRoot(_ script: String?) -> String? {
        if let script = script {
            var hasRoot = false
            var index = 0
            scan: for char in script {
                switch char {
                    case "√": hasRoot = true; index += 1
                    case " ", "\n", "\t": index += 1
                    case "{": if hasRoot { index += 1 }
                    default: break scan
                }
            }
            if hasRoot {
                let start = String.Index(utf16Offset: index, in: script)
                let end   = String.Index(utf16Offset: script.count, in: script)
                let sub = script[start ..< end]
                return String(sub)
            }
        }
        return script
    }

    func parseArchive(_ archive: MuArchive) {
        // get script and parse
        archive.get("Snapshot.tr3", 1000000) { data in
            if  let data = data,
                let script = self.dropRoot(String(data: data, encoding: .utf8)) {

                print(script)
                let _ = Tr3Parse.shared.parseScript(self.root, script, whitespace: "\n\t ")
            } 
        }
    }
    func parseScriptFiles() {
        func parseFile(_ fileName: String) {
            let _ = Tr3Parse.shared.parseTr3(root, fileName)
        }

        parseFile("sky.main")
        parseFile("sky.shader")
//???        parseFile("midi")
//        parseFile("panel.cell")
//        parseFile("panel.camera")
//        parseFile("panel.cell.fade")
//        parseFile("panel.cell.ave")
//        parseFile("panel.cell.melt")
//        parseFile("panel.cell.tunl")
//        parseFile("panel.cell.zha")
//        parseFile("panel.cell.slide")
//        parseFile("panel.cell.fred")
//
//        parseFile("panel.cell.brush")
//        parseFile("panel.shader.color")
//        parseFile("panel.cell.scroll")
//        parseFile("panel.shader.tile")
//        parseFile("panel.cell.camera")
//        parseFile("panel.record")
//        parseFile("panel.cell.speed")
        //?? let script = root.makeTr3Script(indent: 0, pretty: false, commented: false)
        //?? let script = root.dumpScript(indent: 0) // with values
        let script = root.scriptRoot()
        print("\n\n" + script + "\n\n")
    }
}
