import UIKit
import MuFlo
import MuPar
import MuMenuSky
import MuSkyFlo
import MuMetal
import MuMenu // TouchCanvas

class SkyFlo: NSObject {

    static let shared = SkyFlo()
    static let logSnapshot = false

    let root˚ = Flo.root˚
    private var touchRepeat˚: Flo?
    
    public var skySize = CGSize(width: 1920, height: 1080)
    public var archive: MuArchive?
    private var fromSnapshot = true

    private var snapName = "Snapshot.zip"
    private var snapDate = TimeInterval(0)

    private var floScriptNames = ["sky", "shader", "model",
                                  "menu", "plato", "cube",
                                  "midi", "corner"]

    private var bundleNameDates = [String: TimeInterval]()
    private var documentNameDates = [String: TimeInterval]()

    override init() {
        
        super.init()

        // parse Sky Snapshot scripts
        if let archive = MuArchive.readArchive(snapName) {

            snapDate = MuFile.shared.documentDate(snapName)
            print(String(format: "Documents/Snapshot.zip %.2f Δ 0", snapDate))
            getFloBundleChanges()
            getDocumentChanges()

            if bundleHasChanged() {
                parseBundleScriptFiles()
            } else {
                parseSnapshot(archive)
            }
        } else {
            parseBundleScriptFiles()
        }

        /// get list of script file dates inside `library` directory -- updated by Xcode
        func getFloBundleChanges() {
            let floBundle = MuSkyFlo.bundle

            for name in floScriptNames {
                if let floPath = floBundle.path(forResource: name, ofType: ".flo.h") {
                    let date = MuFile.shared.pathDate(floPath)
                    if date > 0 {
                        bundleNameDates[name] = date
                        print(String(format: "Bundle/%@ %.2f Δ %.f", name, date, date - snapDate))
                    }
                }
            }
        }
        /// get list of script file dates inside `documents` directory -- updated manually by user
        func getDocumentChanges() {
            for name in floScriptNames {
                let date = MuFile.shared.documentDate(name + ".flo.h")
                if date > 0 {
                    bundleNameDates[name] = date
                    print(String(format: "Documents/%@ %.2f Δ %.f", name, date, date - snapDate))
                }
            }
        }

        /// Merge changes to flo script that user manually copied to documents directory.
        /// Only works once, as new snapshot will have a later date
        func mergeUserDocumentChanges() {
            for (name, date) in documentNameDates {
                if date > snapDate {
                    _ = MuMenuSky.mergeFlo(root˚, name)
                }
            }
        }

        /// Developer made changes to .flo files and redeployed via XCode
        func bundleHasChanged() -> Bool {
            for date in bundleNameDates.values {
                if date > snapDate {
                    return true
                }
            }
            return false
        }

        func parseSnapshot(_ archive: MuArchive) {
            self.archive = archive
            archive.get("Snapshot.full.flo.h", 1000000) { data in
                if let data {
                    parseFloData(data) {
                        mergeUserDocumentChanges()
                        // getRuntimeChanges()
                        getTexture()
                    }
                }
                else {
                    self.parseBundleScriptFiles()
                    getTexture()
                }
            }

            func getRuntimeChanges() {
                archive.get("Snapshot.now.flo.h", 1000000) { data in
                    if let data {

                        if SkyFlo.logSnapshot {
                            
                            let before = self.root˚.scriptFlo([.parens, .def, .edge])
                            parseFloData(data, merge: true) {
                                let after = self.root˚.scriptFlo([.parens, .def, .edge])
                                _ = ParStr.testCompare(before, after)
                            }
                        } else {

                            parseFloData(data, merge: true)
                        }

                    }
                }
            }
            func getTexture () {
                archive.get("Snapshot.tex", 30_000_000) { data in
                    if let data {
                        print("--- archive.get Snapshot.tex \(data.count)")
                        TextureData.shared.data = data
                    }
                }
            }

            func parseFloData(_ data: Data, merge: Bool = false, finished: CallVoid? = nil) {
                if let script = self.dropRoot(String(data: data, encoding: .utf8)) {
                    if merge {
                        _ = FloParse.shared.mergeScript(self.root˚, script)
                    } else {
                        _ =  FloParse.shared.parseScript(self.root˚, script)
                    }
                }
                finished?()
            }
        }
    }
    // snapshot on framebuffer, draw Texture and skyGraph
    public func saveSkyArchive(_ name: String, _ completion: @escaping CallVoid) {

        let time = trunc(Date().timeIntervalSince1970)
        let snapName = name + ".zip"
        let snapTime = name + ".\(time).zip"
        let archive = MuArchive(snapTime)
        let nodeNamed = SkyPipeline.shared.nodeNamed
        let mtkView = SkyPipeline.shared.mtkView
        let frameBufferOnly = mtkView.framebufferOnly

        mtkView.framebufferOnly = false //  frameBufferOnly

        addScreenIcon() // make icon from an image snapshot of framebuffer
        addTexture()    // MetNodeDraws output texture as `.tex`
        addFloScript()  // snapshot of Sky Graph as flo script
        archive.copy(snapTime, to: snapName)

        mtkView.framebufferOnly = frameBufferOnly // restore
        completion()


        func addScreenIcon() {
            if let flatmapNode = nodeNamed["flatmap"] as? MetNodeFlatmap,
               let image = flatmapNode.cgImage {
                
                let uiImage = UIImage(cgImage: image).roundIcon(128)
                if let data = uiImage?.pngData() {
                    archive.add(name + ".png", data: data)
                }
            }
        }

        func addTexture() {
            if  let drawNode = nodeNamed["draw"] as? MetNodeDraw,
                let drawTex = drawNode.outTex {

                let (bytes, totalSize) = drawTex.bytes()
                let data = Data.init(bytes: bytes, count: totalSize)
                archive.add(name + ".tex", data: data)
            }
        }

        func addFloScript() {

            let root = SkyFlo.shared.root˚
            let scriptFull = root.scriptFull
            let dataFull = Data(scriptFull.utf8)
            print("\n\nscriptDef ⟹\n" )
            print(scriptFull + "\n\n")
            archive.add(name + ".full.flo.h", data: dataFull)
            #if false
            let scriptNow = root.scriptNow
            let dataNow = Data(scriptNow.utf8)
            print("scriptNow ⟹\n" + scriptNow + "\n\n")
            archive.add(name + ".now.flo.h", data: dataNow)
            #endif
        }
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
                let end = String.Index(utf16Offset: script.count, in: script)
                let sub = script[start ..< end]
                return String(sub)
            }
        }
        return script
    }

    func parseArchive(_ archive: MuArchive) {
        // get script and parse
        archive.get("Snapshot.flo", 1000000) { data in
            if  let data = data,
                let script = self.dropRoot(String(data: data, encoding: .utf8)) {

                print(script)
                let _ = FloParse.shared.parseScript(self.root˚, script)
            } 
        }
    }
    /// New install or user manually removed snapshot file
    func parseBundleScriptFiles() {
        for floScriptName in floScriptNames {
            _ = MuMenuSky.parseFlo(root˚, floScriptName)
        }
        //let script = root.scriptRoot()
        //print("\n\n" + script + "\n\n")
    }
}
