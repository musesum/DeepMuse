import UIKit
import Tr3
import Par
import MuMenuSky
import MuSkyTr3

class SkyTr3: NSObject {

    static let shared = SkyTr3()
    let root = Tr3("√")

    public var skySize = CGSize(width: 1920, height: 1080)
    public var archive: MuArchive?
    private var fromSnapshot = true

    private var snapName = "Snapshot.zip"
    private var snapDate = TimeInterval(0)
    private var tr3ScriptNames = ["sky", "shader", "menu", "midi"]
    private var bundleNameDates = [String: TimeInterval]()
    private var documentNameDates = [String: TimeInterval]()

    override init() {
        
        super.init()

        // parse Sky Snapshot scripts
        if let archive = MuArchive.readArchive(snapName) {

            snapDate = MuFile.shared.documentDate(snapName)
            print(String(format: "Documents/Snapshot.zip %.2f Δ 0", snapDate))
            getTr3BundleChanges()
            getDocumentChanges()

            if bundleHasChanged() {
                parseBundleScriptFiles()
            } else {
                parseSnapshot(archive)
            }
        }
        else {
            parseBundleScriptFiles()
        }

        /// get list of script file dates inside `library` directory -- updated by Xcode
        func getTr3BundleChanges() {
            let tr3Bundle = MuSkyTr3.bundle

            for name in tr3ScriptNames {
                if let tr3Path = tr3Bundle.path(forResource: name, ofType: ".tr3.h") {
                    let date = MuFile.shared.pathDate(tr3Path)
                    if date > 0 {
                        bundleNameDates[name] = date
                        print(String(format: "Bundle/%@ %.2f Δ %.f", name, date, date - snapDate))
                    }
                }
            }
        }
        /// get list of script file dates inside `documents` directory -- updated manually by user
        func getDocumentChanges() {
            for name in tr3ScriptNames {
                let date = MuFile.shared.documentDate(name + ".tr3.h")
                if date > 0 {
                    bundleNameDates[name] = date
                    print(String(format: "Documents/%@ %.2f Δ %.f", name, date, date - snapDate))
                }
            }
        }

        /// Merge changes to tr3 script that user manually copied to documents directory.
        /// Only works once, as new snapshot will have a later date
        func mergeUserDocumentChanges() {
            for (name, date) in documentNameDates {
                if date > snapDate {
                    _ = MuMenuSky.mergeTr3(root, name)
                }
            }
        }

        /// Developer made changes to .tr3 files and redeployed via XCode
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
            archive.get("Snapshot.def.tr3.h", 1000000) { data in
                if let data {
                    parseTr3Data(data) {
                        mergeUserDocumentChanges()
                        getRuntimeChanges()
                        getTexture()
                    }
                }
                else {
                    self.parseBundleScriptFiles()
                    getTexture()
                }
            }

            func getRuntimeChanges() {
                archive.get("Snapshot.now.tr3.h", 1000000) { data in
                    if let data {
                        let before = self.root.scriptRoot([.parens, .def, .edge])
                        parseTr3Data(data, merge: true) {
                            let after = self.root.scriptRoot([.parens, .def, .edge])
                             _ = ParStr.testCompare(before, after)
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

            func parseTr3Data(_ data: Data, merge: Bool = false, finished: CallVoid? = nil) {
                if let script = self.dropRoot(String(data: data, encoding: .utf8)) {
                    if merge {
                        _ = Tr3Parse.shared.mergeScript(self.root, script)
                    } else {
                        _ =  Tr3Parse.shared.parseScript(self.root, script)
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

        func addScreenIcon() {
            if let renderNode = nodeNamed["render"] as? MtlKernelRender,
               let renderTex = renderNode.renderedTex,
               let image = renderTex.toImage() {
                let uiImage = UIImage(cgImage: image).rotatedIcon(128)
                if let data = uiImage?.pngData() {
                    archive.add(name + ".png", data: data)
                }
            }
        }

        func addTexture() {
            if  let drawNode = nodeNamed["draw"] as? MtlKernelDraw,
                let drawTex = drawNode.outTex {

                let (bytes, totalSize) = drawTex.bytes()
                let data = Data.init(bytes: bytes, count: totalSize)
                archive.add(name + ".tex", data: data)
            }
        }

        func addTr3Script() {
            let root = SkyTr3.shared.root
            let scriptDef = root.scriptRoot([.parens, .def, .expand, .edge, .comment, .copyAt])
            let scriptNow = root.scriptRoot([.parens, .def, .now, .delta, .compact])
            let dataDef = Data(scriptDef.utf8)
            let dataNow = Data(scriptNow.utf8)

            archive.add(name + ".def.tr3.h", data: dataDef)
            archive.add(name + ".now.tr3.h", data: dataNow)

            print("\n\n" )
            print("scriptDef ⟹\n" + scriptDef + "\n\n")
            print("scriptNow ⟹\n" + scriptNow + "\n\n")

        }

        // begin -------------------------------------------------

        mtkView.framebufferOnly = false //  frameBufferOnly

        addScreenIcon() // make icon from an image snapshot of framebuffer
        addTexture()    // MtlKernelDraws output texture as `.tex`
        addTr3Script()  // snapshot of Sky Graph as tr3 script
        archive.copy(snapTime, to: snapName)

        mtkView.framebufferOnly = frameBufferOnly // restore
        completion()
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
        archive.get("Snapshot.tr3", 1000000) { data in
            if  let data = data,
                let script = self.dropRoot(String(data: data, encoding: .utf8)) {

                print(script)
                let _ = Tr3Parse.shared.parseScript(self.root, script)
            } 
        }
    }
    /// New install or user manually removed snapshot file
    func parseBundleScriptFiles() {
        for tr3ScriptName in tr3ScriptNames {
            _ = MuMenuSky.parseTr3(root, tr3ScriptName)
        }
        //let script = root.scriptRoot()
        //print("\n\n" + script + "\n\n")
    }
}
