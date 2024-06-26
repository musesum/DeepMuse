import MetalKit
import Compression
import ZIPFoundation
import MuFlo
import MuMetal
import MuPlato
import MuMenu

public class SkyPipeline: Pipeline {

    private var cellNode: MetalNode?    // CA node, after drawNode & cameraNode
    private var drawNode: MetalNode?    // drawing node, optional 1st node
    private var colorNode: MetalNode?   // colord palette
    private var recordNode: MetalNode?  // record text to m4v

    private var cameraNode: MetalNode?  // camera input - always first Node
    private var camixNode: MetalNode?   // camera mix node - before flatmapNode
    private var tileNode: MetalNode?    // deprecated
    private var platoNode: PlatoNode?

    public var skyColor:  ColorFlo! // instance of subtree of sky.color
    private var skyMainRun˚: Flo?    // run the cellular automata rules
    private var skyMainRun = true
    private var skyAnimate˚: Flo?
    private var skyAnimate = CGFloat(1)
    private var root˚: Flo!

    init(_ bounds: CGRect, _ root: Flo) {

        super.init(bounds)
        self.root˚ = root
        skyColor = ColorFlo(root)
        skyMainRun˚ = root.bind("sky.main.run") { f,_ in
            self.skyMainRun = f.bool
            self.cellNode?.isOn = self.skyMainRun
        }
        skyAnimate˚ = root.bind("sky.main.anim") { f,_ in
            self.skyAnimate = f.cgFloat
        }
       makeShader(root)
       setupPipeline(root)
    }

    /// setup new node during shader startup or via pipeline
    func initNodeName(_ name: String) -> MetalNode? {

        var node = nodeNamed[name]
        if node == nil {
            switch name {
            case "camera" : node = CameraNode (root˚,self)
            case "camix"  : node = CamixNode  (root˚,self)
            case "draw"   : node = DrawNode   (self, TouchCanvas.shared.touchFlo)
            case "color"  : node = ColorNode  (self, skyColor.getMix)
            case "record" : break //node = MetNodeRecord (self)
            case "tile"   : node = TileNode   (self, name)
            case "flatmap": node = FlatmapNode(self)
            case "cubemap": node = CubemapNode(self, true)
            case "plato"  : node = PlatoNode  (self, skyColor.getMix)
            default       : node = CellNode   (self, name)
            }
            nodeNamed[name] = node
        }
        return node
    }

    /// setup new node during shader startup or via pipeline
    func addNodeName(_ name: String,
                     after: MetalNode?) -> MetalNode? {

        if let node = nodeNamed[name] ?? initNodeName(name) {

            switch name {
            case "camera" : addCamera(node)
            case "camix"  : camixNode = node.insert(after: after)
            case "draw"   : addDraw(node)
            case "color"  : colorNode = node.insert(after: after)
            case "record" : recordNode = node.insert(after: after)
            case "tile"   : tileNode = node.insert(after: after)
            case "flatmap": addFlatNode(node)
            case "cubemap": addCubeNode(node)
            case "plato"  : addPlatoNode(node)
            default       : addCompute(node)
            }
            return node
        }
        return nil
        func addFlatNode(_ node: MetalNode) {
            if let node = node as? FlatmapNode {
                flatmapNode = node
                node.insert(after: after)
            }
        }
        func addCubeNode(_ node: MetalNode) {
            if let node = node as? CubemapNode {
                cubemapNode = node
                node.insert(after: after)
            }
        }
        func addPlatoNode(_ node: MetalNode) {
            if let node = node as? PlatoNode {
                platoNode = node
                node.insert(after: after)
            }
        }
        func addCamera(_ node: MetalNode) {
            cameraNode = node
            if let cameraNode, firstNode == drawNode {

                cameraNode.insert(after: drawNode)
                firstNode = cameraNode

            }
        }
        func addDraw(_ node: MetalNode) {
            drawNode = node
            firstNode = firstNode ?? drawNode
        }
        func addCompute(_ node: MetalNode) {
            cellNode = node
            if let drawNode {
                cellNode?.insert(after: after)
                // CA double universe feedback loop
                drawNode.inNode = node
                drawNode.inTex = node.outTex
            }
        }
    }
    /// called from SkyMetal:: makeShader.updateBuffer.addOn
    func swap(inNode node: MetalNode) {

        if settingUp { return } // don't swap while Setting up pipeline

        switch node.name {

        case "camera":
            // insert camera just after draw node to allow rules to apply to image
            if node.isOn {
                cameraNode = drawNode?.insertNode(node, .below)
//?          } else if let cameraNode {
//                removeNode(cameraNode)
//                if let camixNode {
//                    removeNode(camixNode)
//                }
            }

        case "camix":
            if node.isOn {
                camixNode = node
                fixupCamix()
            }

        case "cubemap":
            if let node = node as? CubemapNode {
                cubemapNode = node
                if node.isOn {
                    flatmapNode?.replace(with: node)
                } else if let flatmapNode {
                    node.replace(with: flatmapNode)
                    flatmapNode.isOn = true
                }
            }

        case "flatmap":
            if let node = node as? FlatmapNode {
                flatmapNode = node
                if node.isOn {
                    cubemapNode?.replace(with: node)
                } else if let cubemapNode {
                    node.replace(with: cubemapNode)
                    cubemapNode.isOn = true
                }
            }
        case "plato":
            if let node = node as? PlatoNode {
                platoNode = node
                if node.isOn {
                    node.insert(after: lastNode)
                    lastNode = node
                } else if let prevNode = node.inNode {
                    prevNode.outNode = nil
                    lastNode = prevNode
                }
            }
        case "record":
            if node.isOn {
                recordNode = flatmapNode?.inNode?.insertNode(node, .below)
            }

        default:
            if node.isOn {
                cellNode = cellNode?.replace(with: node)
            }
        }
        fixupNodes()
    }

    /// create pipeline from script or snapshot
    public func setupPipeline(_ root˚: Flo) {

        camixNode = nil

        if  let pipeline = root˚.findPath("shader.pipeline"),
            let firstChild = pipeline.children.first {

            var lastNode: MetalNode?
            let type = firstChild.string //?? "draw"
            let name = firstChild.name
            firstNode = addNodeName(name, after: nil)
            guard let firstNode else { return }
            lastNode = firstNode

            for i in 1 ..< pipeline.children.count {

                let next = pipeline.children[i]
                let name = next.name
                if let nextNode = addNodeName(name, after: lastNode) {
                    lastNode = nextNode
                    switch type {
                    case "kernel" : cellNode = nextNode
                    case "record" : recordNode = nextNode
                    case "camera" : cameraNode = nextNode
                    case "camix"  : camixNode = nextNode
                    case "tile"   : tileNode = nextNode
                    case "flatmap": flatmapNode = nextNode as? FlatmapNode
                    case "cubemap": cubemapNode = nextNode as? CubemapNode
                    default       : break
                    }
                }
            }
            fixupNodes()

        } else {
            setupDefaultPipeline()
        }
        settingUp = false
    }

    func fixupCamix() {
        if let camixNode {
            if let colorNode {
                removeNode(camixNode)
                colorNode.insertNode(camixNode, .below)
            } else if let flatmapNode {
                removeNode(camixNode)
                flatmapNode.insertNode(camixNode, .above)
            } else if let cubemapNode {
                removeNode(camixNode)
                cubemapNode.insertNode(camixNode, .above)
            }
        }
    }
    func fixupTile() {
        if let tileNode {
            if let flatmapNode {
                removeNode(tileNode)
                flatmapNode.insertNode(tileNode, .above)
            } else if let cubemapNode {
                removeNode(tileNode)
                cubemapNode.insertNode(tileNode, .above)
            }
        }
    }
    func fixupFirst() {
        if let firstNode,
           let cellNode {
            firstNode.inNode = cellNode // feedback loop
            firstNode.inTex = cellNode.outTex
        }
    }
    func fixupNodes() {
        fixupCamix()
        fixupTile()
        fixupFirst()
        updateLastNode()
        print("⟹ pipeline: " + scriptPipeline())
    }
    /// Create linked list of MtlNode to render scene
    func setupDefaultPipeline() {

        // make first pipeline af draw, compute, color, render
        drawNode    = addNodeName("draw"    , after: nil      )
        cellNode    = addNodeName("fade"    , after: drawNode )
        colorNode   = addNodeName("color"   , after: cellNode )
        //???? flatmapNode = addNodeName("flatmap" , after: colorNode) as? FlatmapNode
        cubemapNode = addNodeName("cubemap" , after: colorNode) as? CubemapNode

        firstNode = drawNode
        firstNode?.inNode = cellNode // feedback cell back into firstNode
        firstNode?.inTex = cellNode?.outTex

        // firstNode?.printMetaNodes()
    }
}

