import UIKit
import Tr3
import Par
import MuMetal
import MuMenuSky

class SkyTr3: NSObject {

    static let shared = SkyTr3()
    let root = Tr3("√")

    public var skySize = CGSize(width: 1920, height: 1080)
    public var archive: MuArchive?
    private var fromSnapshot = true

    private var cameraFlip˚: Tr3?
    private var mainFps˚: Tr3?

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
                if let data {
                    print("--- archive.get Snapshot.tex \(data.count)")
                    TextureData.shared.data = data
                }
            }
        }
        else {
            parseScriptFiles()
        }
        cameraFlip˚ = root.bindPath("shader.model.pipe.camera.flip") { _,_ in CameraSession.shared.flipCamera() }
        mainFps˚ = root.bindPath("sky.main.fps") { t, _ in SkyWorkLink.shared.updateFps(t.IntVal()) }
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

        _ = MuMenuSky.parseTr3(root, "sky")
        _ = MuMenuSky.parseTr3(root, "shader")
        _ = MuMenuSky.parseTr3(root, "menu")

        //?? let script = root.makeTr3Script(indent: 0, pretty: false, commented: false)
        //?? let script = root.dumpScript(indent: 0) // with values

        //let script = root.scriptRoot()
        //print("\n\n" + script + "\n\n")
    }
}
