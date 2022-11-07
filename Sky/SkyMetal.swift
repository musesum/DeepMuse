
import UIKit
import Tr3

class SkyMetal {
    
    static let shared = SkyMetal()

    var pipeline = SkyPipeline.shared

    func makeShader(for tr3: Tr3) {

        guard let shader = tr3.findPath("shader")  else { return err(tr3, "shader") }
        guard let model = shader.findPath("model") else { return err(tr3, "shader.model") }
        guard let modelCell = model.findPath("cell") else { return err(tr3, "model.cell") }
        guard let modelPipe = model.findPath("pipe") else { return err(tr3, "model.pipe") }
        guard let file = shader.findPath("file") else { return err(tr3, "shader.file") }
        guard let fileCell = file.findPath("cell") else { return err(tr3, "file.cell") }
        guard let filePipe = file.findPath("pipe") else { return err(tr3, "file.pipe") }

        for cellTr3 in modelCell.children {
            if let node = pipeline.initNodeName(cellTr3.name, "cell") {
                makeNode(node, cellTr3, fileCell)
            }
        }

        for pipeTr3 in modelPipe.children {
            if let node = pipeline.initNodeName(pipeTr3.name, pipeTr3.name) {
                makeNode(node, pipeTr3, filePipe)
            }
        }
    }
    func makeNode(_ node: MtlNode,
                  _ tr3: Tr3,
                  _ fileTr3: Tr3) {

        updateBuffer(node, tr3)

        for child in tr3.children {
            switch child.name {
                case "on"     : addOn(node, child)
                case "loops"  : node.loops = child.IntVal() ?? 1
                case "flip"   : break // ignore
                case "mix"    : updateChildBuffer(node, child)
                case "frame"  : updateChildBuffer(node, child)
                case "repeat" : updateChildBuffer(node, child)
                case "mirror" : updateChildBuffer(node, child)
                case "bits"   : updateChildBuffer(node, child)
                default       : err(tr3, "name:\(child.name)")
            }
        }
        if let fileTr3 = fileTr3.findPath(tr3.name),
           let fileName = fileTr3.StringVal() {
            node.filename = fileName
        }
    }
    func updateBuffer(_ node: MtlNode,
                      _ tr3: Tr3) {

        func updateFloats(_ tr3: Tr3) {
            if let exprs = tr3.val as? Tr3Exprs {
                let floats = exprs.getValFloats()
                node.updateBuffer(tr3.name, floats)
            } else if let scalar = tr3.val as? Tr3ValScalar {
                node.updateBuffer(tr3.name, [scalar.now])
            }
        }
        tr3.addClosure { tr3, _ in
            updateFloats(tr3)
        }
        updateFloats(tr3)
    }

    func anyInt(_ any: Any?) -> Int {
        if let v = any as? Tr3ValScalar {
            return Int(v.now)
        } else {
            print("*** makeCellNode::anyInt: unknown: \(any.debugDescription)")
            return 0
        }
    }
    func addOn(_ node: MtlNode,
               _ child: Tr3) {

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

    func updateChildBuffer(_ node: MtlNode,
                           _ child: Tr3) {

        func updateParentFloats(_ child: Tr3) {
            if  let exprs = child.val as? Tr3Exprs {
                let floats = exprs.getValFloats()
                node.updateBuffer(child.name, floats)
            }
            else if let val = child.val as? Tr3ValScalar {
                let float = val.getVal()
                node.updateBuffer(child.name, [float])
            }
        }
        child.addClosure { child, _ in
            updateParentFloats(child)
        }
        updateParentFloats(child)
    }
    func err(_ tr3: Tr3, _ item: String) {
        print("🚫 makeShader couldn't find \(item) in \(tr3.name)")
    }
}
