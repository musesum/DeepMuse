import UIKit
import Tr3
import Par
import MuMetal
import MuMenuSky
import MuFiles

class SkyTr3: NSObject {

    static let shared = SkyTr3()
    let root = Tr3("√")

    public var skySize = CGSize(width: 1920, height: 1080)
    public var archive: MuArchive?
    private var fromSnapshot = true

    private var cameraFlip˚: Tr3?
    private var mainFps˚: Tr3?

    private var snapName = "Snapshot.zip"
    private var snapDate = TimeInterval(0)
    private var tr3Names = ["sky", "shader", "menu", "midi"]
    private var libraryNameDates = [String: TimeInterval]()
    private var documentNameDates = [String: TimeInterval]()

    override init() {
        
        super.init()

        /// get list of script file dates inside `library` directory -- updated by Xcode
        func getLibraryChanges() {
            for name in tr3Names {
                let date = MuFile.shared.libraryDate(name + ".tr3.h")
                if date > 0 {
                    libraryNameDates[name] = date
                    print(String(format: "%@ %.2f Δ%.2f", name, date, date - snapDate))
                }
            }
        }
        /// get list of script file dates inside `documents` directory -- updated manually by user
        func getDocumentChanges() {
            for name in tr3Names {
                let date = MuFile.shared.documentDate(name + ".tr3.h")
                if date > 0 {
                    libraryNameDates[name] = date
                    print(String(format: "%@ %.2f Δ%.2f", name, date, date - snapDate))
                }
            }
        }

        /// Merge changes to tr3 script changes via Xcode
        /// Only works once, as new snapshot will have a later date
        func mergeLibraryChanges() {
            for (name, date) in libraryNameDates {
                if date > snapDate {
                    //??? test will this merge?
                    _ = MuMenuSky.parseTr3(root, name)
                }
            }
        }
        /// Merge changes to tr3 script that user manually copied to documents directory.
        /// Only works once, as new snapshot will have a later date
        func mergeDocumentChanges() {
            for (name, date) in documentNameDates {
                if date > snapDate {
                    //??? test will this merge?
                    _ = MuMenuSky.parseTr3(root, name)
                }
            }
        }

        // parse Sky Snapshot Or scripts
        if let archive = MuArchive.readArchive(snapName) {
            snapDate = MuFile.shared.documentDate(snapName)
            print(String(format: "Snapshot.zip %.2f Δ%.2f", snapDate  , 0))
            getLibraryChanges()

            self.archive = archive
            archive.get("Snapshot.tr3.h", 1000000) { data in
                if  let data = data,
                    let script = self.dropRoot(String(data: data, encoding: .utf8)),
                    Tr3Parse.shared.parseScript(self.root, script, whitespace: "\n\t ") {

                    mergeLibraryChanges()
                    mergeDocumentChanges()
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
        _ = MuMenuSky.parseTr3(root, "midi")

        //let script = root.scriptRoot()
        //print("\n\n" + script + "\n\n")
    }
}
