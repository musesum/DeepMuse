
import UIKit
import Tr3
import MuMetal

class SkyMetal {
    
    static let shared = SkyMetal()

    var pipeline = SkyPipeline.shared


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
    func makeShader(for tr3: Tr3) {

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
