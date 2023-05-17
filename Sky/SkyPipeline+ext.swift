
import UIKit
import MuFlo
import MuPar // Visitor
import MuMetal

extension SkyPipeline {

    func makeShader(for flo: Flo) {

        guard let shader  = flo   .findPath("shader" ) else { return err(flo,"shader" )}
        guard let cell    = shader.findPath("cell"   ) else { return err(flo,"cell"   )}
        guard let compute = shader.findPath("compute") else { return err(flo,"compute")}
        guard let render  = shader.findPath("render" ) else { return err(flo,"render" )}

        for flo in cell.children {
            if let node = initNodeName(flo.name) {
                makeNode(node, flo)
            }
        }
        for flo in compute.children {
            if let node = initNodeName(flo.name) {
                makeNode(node, flo)
            }
        }
        for flo in render.children {
            if let node = initNodeName(flo.name) {
                makeNode(node, flo)
            }
        }
    }
    func makeNode(_ node: MetNode,
                  _ flo: Flo) {

        updateBuffer(node, flo)

        for child in flo.children {
            switch child.name {
                case "on"     : addMtlNodeOn(node, child)
                case "loops"  : node.loops = max(1,child.int)
                case "flip"   : break // ignore
                case "mix"    : updateChildBuffer(node, child)
                case "frame"  : updateChildBuffer(node, child)
                case "repeat" : updateChildBuffer(node, child)
                case "mirror" : updateChildBuffer(node, child)
                case "bits"   : updateChildBuffer(node, child)
                case "gravity": updateChildBuffer(node, child)
                default       : err(flo, "name:\(child.name)")
            }
        }
    }
    func updateBuffer(_ node: MetNode,
                      _ flo: Flo) {

        func updateFloats(_ flo: Flo, _: Visitor = Visitor(0)) {
            if let exprs = flo.val as? FloValExprs {
                let nums = exprs.getValNums()
                node.updateBuffer(flo.name, nums)
            } else if let scalar = flo.val as? FloValScalar {
                node.updateBuffer(flo.name, [scalar.now])
            }
        }
        flo.addClosure(updateFloats)
        updateFloats(flo)
    }

    func anyInt(_ any: Any?) -> Int {
        if let v = any as? FloValScalar {
            return Int(v.now)
        } else {
            print("*** SkyMetal::anyInt: unknown: \(any.debugDescription)")
            return 0
        }
    }
    func addMtlNodeOn(_ node: MetNode,
                      _ flo: Flo) {

        node.isOn = flo.bool
        flo.addClosure(nodeOn)

        func nodeOn(_ isOn: Flo, _: Visitor) {

            if let name = flo.parent?.name,
               let node = nodeNamed[name] {

                let isOn = isOn.bool

                setMtlNode(node, isOn)

                if name == "camera" {
                    MetCamera.shared.setCameraOn(isOn)
                    _ = CameraFlip.shared // setup singleton
                    if let mixNode = nodeNamed["camix"] {
                        setMtlNode(mixNode, isOn)
                    }
                }
            }
        }
        func setMtlNode(_ node: MetNode,_ isOn: Bool) {
            node.setMetalNodeOn(isOn) {
                self.swap(inNode: node)
            }
        }
    }
    func updateChildBuffer(_ node: MetNode,
                           _ child: Flo) {
        child.addClosure { child,_ in
            updateParentFloats(child)
        }
        updateParentFloats(child)

        func updateParentFloats(_ child: Flo) {
            if  let exprs = child.val as? FloValExprs {
                let nums = exprs.getValNums()
                node.updateBuffer(child.name, nums)

            } else if let val = child.val as? FloValScalar {
                
                let val = val.getVal()
                node.updateBuffer(child.name, [val])
            }
        }
    }
    func err(_ flo: Flo, _ item: String) {
        print("🚫 makeShader couldn't find \(item) in \(flo.name)")
    }
}