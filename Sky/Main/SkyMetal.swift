
import UIKit
import Tr3
import MuMetal
import SwiftUI

class SkyMetal {
    
    static let shared = SkyMetal()

    var pipeline = SkyPipeline.shared

    func makeShader(for tr3: Tr3) {

        func err(_ tr3: Tr3, _ item: String) {
            print("🚫 makeShader couldn't find \(item) in \(tr3.name)")
        }

        func makeCellNode(_ tr3: Tr3, _ fileCellTr3: Tr3) {
            guard let node = pipeline.initNodeName(tr3.name, "cell") else { return err (tr3, "cell") }
            guard let comps = tr3.components() else { return err(tr3, "components")}
            for (name,any) in comps {
                switch name {
                    case "val": break
                    case "seg": break
                    case "tog": break
                    case "on": break
                    case "repeat": break
                    case "bits": break
                    default: err(tr3, "name")
                }
            }
            if let fileTr3 = fileCellTr3.findPath(tr3.name),
               let fileName = fileTr3.StringVal() {
                node.filename = fileName
            }
        }

        func makePipeNode(_ tr3: Tr3, _ filePipeTr3: Tr3) {
            guard let node = pipeline.initNodeName(tr3.name, tr3.name) else { return err (tr3, "cell") }
            guard let comps = tr3.components() else { return err(tr3, "components")}
            for (name,any) in comps {
                switch name {
                    case "val": break
                    case "seg": break
                    case "tog": break
                    case "on": break
                    case "repeat": break
                    case "x", "y", "w", "h": break
                    default: err(tr3, "name")
                }
            }
            if let fileTr3 = filePipeTr3.findPath(tr3.name),
               let fileName = fileTr3.StringVal() {
                node.filename = fileName
            }
        }

        guard let shader = tr3.findPath("shader")  else { return err(tr3, "shader") }
        
        guard let model = shader.findPath("model") else { return err(tr3, "shader.model") }
        guard let modelCell = model.findPath("cell")   else { return err(tr3, "model.cell") }
        guard let modelPipe = model.findPath("pipe")   else { return err(tr3, "model.pipe") }

        guard let file = shader.findPath("file") else { return err(tr3, "shader.file") }
        guard let fileCell = file.findPath("cell")   else { return err(tr3, "file.cell") }
        guard let filePipe = file.findPath("pipe")   else { return err(tr3, "file.pipe") }

        for cell in modelCell.children {
            makeCellNode(cell, fileCell)
        }

        for pipe in modelPipe.children {
            makePipeNode(pipe, filePipe)
        }
    }


    /** translate Tr3 script into shader with uniforms

        shader {
            melt {
                type "compute"
                file "cell.melt.metal"
                on   (0...1=0)
                buffer {
                    version (0...1=0)  } }

    - Note: In the above example
       melt refers to metal function `kernel void melt(...)`
       declared inside the file `cell.melt.metal`.
       Currently, the metal file is statically linked. So, the filename is ignored.
       Later, will be able to compile the file at runtime, or possibly
       later, an option of embedding the script inside a .tr3 file
     */
    func makeShaderOld(for tr3: Tr3) {

        func updateBuffer(_ node: MtlNode, tr3: Tr3) {

            tr3.addClosure { tr3, _ in
                if let val = tr3.val?.getVal() {
                    node.updateBuffer(tr3.name, val)
                }
            }
            if let val = tr3.val?.getVal() {
                node.updateBuffer(tr3.name, val)
            }
        }

        // begin ---------------------------------------------------------------

        if tr3.name.first == "_" { return } // ignore "_compute" base class
        if  let type = tr3.findPath("type")?.StringVal(),
            let node = pipeline.initNodeName(tr3.name, type) {

            func addOn(_ child: Tr3) {
                node.isOn = child.BoolVal()
                child.addClosure { tr3, _ in
                    let nodeNamed = self.pipeline.nodeNamed
                    guard let parent = tr3.parent else { return print("🚫 no parent" ) }
                    guard let node = nodeNamed[parent.name] else { return print("🚫 no node for parent:\(parent.scriptLineage(2))" ) }
                    let isOn = tr3.BoolVal()

                    node.setOn(isOn) {
                        if isOn {
                            self.pipeline.swap(inNode: node)
                        }
                    }
                    //print("   tr3:\(tr3.scriptLineage(3)) isOn:\(isOn)")
                }
            }

            for child in tr3.children {
                switch child.name {
                    case "buffer": child.children.forEach { updateBuffer(node, tr3: $0) }
                    case "file":   node.filename = child.StringVal() ?? ""
                    case "repeat": node.repeats = child.IntVal() ?? 1
                    case "on":     addOn(child)
                    case "flip":   break // ignore
                    case "type":   break // already found, see above
                    default: print("🚫 unknown shader:\(tr3.name) parameter: \(child.name)")
                }
            }
        }
    }
}
