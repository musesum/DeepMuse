
import UIKit
import MuFlo
import MuMetal

extension SkyPipeline {

    func makeShader(_ root˚: Flo) {

        guard let shader = root˚ .findPath("shader") else { return err(root˚,"shader" )}
        guard let cell   = shader.findPath("cell"  ) else { return err(root˚,"cell"   )}
        guard let kernel = shader.findPath("kernel") else { return err(root˚,"kernel")}
        guard let render = shader.findPath("render") else { return err(root˚,"render" )}

        for child in cell.children   {
            if cell.name == "more" {
                for grandchild in child.children {
                    makeMetNode(grandchild)
                }
            } else {
                makeMetNode(child)
            }
        }
        for child in kernel.children { makeMetNode(child) }
        for child in render.children { makeMetNode(child) }

        func makeMetNode(_ flo: Flo) {

            guard let node = initNodeName(flo.name) else { return }

            updateBuffer(node, flo)

            for child in flo.children {
                switch child.name {
                case "on"     : addMtlNodeOn(node, child)
                case "loops"  : updateChildBuffer(node, child)
                case "mix"    : updateChildBuffer(node, child)
                case "frame"  : updateChildBuffer(node, child)
                case "repeat" : updateChildBuffer(node, child)
                case "mirror" : updateChildBuffer(node, child)
                case "bits"   : updateChildBuffer(node, child)
                case "gravity": updateChildBuffer(node, child)
                case "front"  : break // ignore shader.camera.front
                case "rotate" : break // ignore shader.render.cubemap.rotate
                default       : err(flo, child.name)
                }
            }
        }
        func updateBuffer(_ node: MetalNode,
                          _ flo: Flo) {

            func updateFloats(_ flo: Flo, _: Visitor = Visitor(0)) {
                if let exprs = flo.exprs {
                    let nums = exprs.getValNums()
                    node.updateBuffer(flo.name, nums)
                }
            }
            flo.addClosure(updateFloats)
            updateFloats(flo)
        }

        func addMtlNodeOn(_ node: MetalNode,
                          _ flo: Flo) {

            node.isOn = flo.bool
            flo.addClosure(nodeOn)

            func nodeOn(_ flo: Flo, _: Visitor) {

                if let name = flo.parent?.name,
                   let node = nodeNamed[name] {

                    let isOn = flo.bool

                    setMtlNode(node, isOn)
                    #if os(visionOS)
                    #else
                    if name == "camera" {
                        Camera.shared.setCameraOn(isOn)

                        if let mixNode = nodeNamed["camix"] {
                            setMtlNode(mixNode, isOn)
                        }
                    }
                    #endif
                }
            }
            func setMtlNode(_ node: MetalNode,_ isOn: Bool) {
                node.setMetalNodeOn(isOn) {
                    self.swap(inNode: node)
                }
            }
        }
        func updateChildBuffer(_ node: MetalNode,
                               _ child: Flo) {
            child.addClosure { child,_ in
                updateParentFloats(child)
            }
            updateParentFloats(child)

            func updateParentFloats(_ child: Flo) {
                if  let exprs = child.exprs {
                    let nums = exprs.getValNums()
                    node.updateBuffer(child.name, nums)
                }
            }
        }
        func err(_ flo: Flo, _ item: String) {
            print("⁉️ makeShader couldn't find \(flo.path(9)).\(item)")
        }
    }
}
