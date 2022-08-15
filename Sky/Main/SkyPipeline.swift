import MetalKit
import Par
import Tr3
import Compression
import ZIPFoundation

import MuMetal
import MuUtilities // MuAspect

/// metal draw/scroll + CA Rule + color + render pipleline
public class SkyPipeline: NSObject, MTKViewDelegate {

    static let shared = SkyPipeline()

    public var mtkView = MTKView()             // MetalKit render view
    private var mtlCommand: MTLCommandQueue?  // queue w/ command buffers

    public var cellNode: MtlNode?      // 1st CA node, after drawNode / cameraNode
    private var firstNode: MtlNode?    // 1st node in renderer chain
    private var drawNode: MtlNode?     // drawing node, optional 1st node
    private var colorNode: MtlNode?    // colord palette
    private var recordNode: MtlNode?   // record text to m4v
    private var renderNode: MtlNode?   // record to screen
    private var cameraNode: MtlNode?   // camera input node - always first firstNode
    private var camixNode: MtlNode?    // camera mix node is before renderNode

    public var nodeNamed = [String: MtlNode]() // find node by name

    public var drawSize = CGSize.zero  // size of draw surface
    public var viewSize = CGSize.zero  // size of render surface
    public var clipRect = CGRect.zero

    private var settingup = true        // ignore swapping in new shaders
    private var skyColor = SkyColor(SkyTr3.shared.root) // instance of subtree of sky.color
    private var skyMainRun˚: Tr3?       // run the cellular automata rules
    private var skyMainRun = true

    override init() {

        super.init()

        let bounds = UIScreen.main.bounds
        drawSize = (bounds.size.width > bounds.size.height
                    ? CGSize(width: 1920, height: 1080)
                    : CGSize(width: 1080, height: 1920))

        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.framebufferOnly = false
        mtkView.delegate = self
        mtlCommand = mtkView.device?.makeCommandQueue()

        nodeNamed = [:]

        skyMainRun˚ = SkyTr3.shared.root.findPath("sky.main.run")
        skyMainRun˚?.addClosure { tr3, _ in
            self.skyMainRun = tr3.BoolVal()
            self.cellNode?.isOn = self.skyMainRun
        }
    }

    func setViewFrame(_ viewFrame: CGRect) -> MTKView {
        
        mtkView.frame = viewFrame
        mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = self
        return mtkView
    }

    func scriptPipeline() -> String {
        var str = ""
        var del = "["

        var node = firstNode
        while node != nil {
            str += del + node!.name + ":" + node!.type
            del = ", "
            node = node!.outNode
        }
        str += "]"
        return str
    }

    func removeNode(_ node: MtlNode) {
        node.inNode?.outNode = node.outNode
        node.outNode?.inNode = node.inNode
    }

    /// create pipeline from script or snapshot
    func setupSkyPipeline() {

        camixNode = nil

        func fixupNodes() {
            if  let camixNode = camixNode,
                let renderNode = renderNode {

                removeNode(camixNode)
                renderNode.insertNode(camixNode, .above)
            }
            firstNode?.inNode = cellNode // feedback loop
            firstNode?.inTex = cellNode?.outTex
        }

        let tr3Root = SkyTr3.shared.root
        if  let pipeline = tr3Root.findPath("sky.pipeline"),
            let firstChild = pipeline.children.first {

            var lastNode: MtlNode?
            let type = firstChild.StringVal() ?? "draw"
            let name = firstChild.name
            firstNode = addNodeName(name, after: nil, type: type)
            guard let firstNode = firstNode else { return }
            lastNode = firstNode

            for i in 1 ..< pipeline.children.count {

                let next = pipeline.children[i]
                let type = next.StringVal() ?? "compute"
                let name = next.name
                if let nextNode = addNodeName(name, after: lastNode, type: type) {
                    lastNode = nextNode
                    switch type {
                        case "compute": cellNode = nextNode
                        case "record" : recordNode = nextNode
                        case "render" : renderNode = nextNode
                        case "camera" : cameraNode = nextNode
                        case "camix"  : camixNode = nextNode
                        default       : break
                    }
                }
            }
            fixupNodes()
            print("⟹ pipeline: " + scriptPipeline())
        }
        else {
            setupDefaultPipeline()
        }
    }

    // snapshot on framebuffer, drawTexture and skyGraph
    func saveSkyArchive(_ name: String, _ completion: @escaping CallVoid) {

        let time = trunc(Date().timeIntervalSince1970)
        let snapName = name + ".zip"
        let snapTime = name + ".\(time).zip"
        let archive = MuArchive(snapTime)

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
            if  let drawNode = nodeNamed["draws"] as? MtlKernelDraws,
                let drawTex = drawNode.outTex {

                let (bytes, totalSize) = drawTex.bytes()
                let data = Data.init(bytes: bytes, count: totalSize)
                archive.add(name + ".tex", data: data)
            }
        }

        func addTr3Script() {
            let root = SkyTr3.shared.root
            let script = root.scriptRoot()//??.makeTr3Script(indent: 0, pretty: false, commented: false)
            let data = Data(script.utf8)
            print("\n\n"+script+"\n\n")
            archive.add(name + ".tr3.h", data: data)
        }

        // begin -------------------------------------------------
        let frameBufferOnly = mtkView.framebufferOnly
        mtkView.framebufferOnly = false //  frameBufferOnly

        addScreenIcon() // make icon from an image snapshot of framebuffer
        addTexture()    // MtlKernelDraws output texture as `.tex`
        addTr3Script()  // snapshot of Sky Graph as tr3 script
        archive.copy(snapTime, to: snapName)

        mtkView.framebufferOnly = frameBufferOnly // restore
        completion()
    }


    /// Create linked list of MtlNode to render scene
    func setupDefaultPipeline() {

        // make first pipeline af draw, compute, color, render
        drawNode   = addNodeName("draws",  after: nil,        type: "draw")
        cellNode   = addNodeName("fade",   after: drawNode,   type: "compute")
        colorNode  = addNodeName("color",  after: cellNode,   type: "color")
        renderNode = addNodeName("render", after: recordNode, type: "render")

        firstNode = drawNode
        firstNode?.inNode = cellNode // feedback cell back into firstNode
        firstNode?.inTex = cellNode?.outTex

        // firstNode?.printMetaNodes()
    }
    private var uiOrientation: UIInterfaceOrientation { get {
        return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait }
    }
    /// setup new node during shader startup or via pipeline
    func initNodeName(_ name: String,
                      _ type: String) -> MtlNode? {
        var node = nodeNamed[name]
        if node == nil, let device = mtkView.device {
            switch type {
                case "camera" : node = MtlKernelCamera  (name, device, drawSize, type, uiOrientation)
                case "draw"   : node = MtlKernelDraws   (name, device, drawSize, type, SkyDraw.shared.drawTexture)
                case "compute": node = MtlKernelCompute (name, device, drawSize, type)
                case "color"  : node = MtlKernelColor   (name, device, drawSize, type, skyColor.getMix)
                case "camix"  : node = MtlKernelCamix   (name, device, drawSize, type, uiOrientation)
                case "render" : node = MtlKernelRender  (name, device, drawSize, type, mtkView)
                case "record" : node = MtlKernelRecord  (name, device, drawSize, type)
                default       : node = MtlKernelCompute (name, device, drawSize, type)
            }
            nodeNamed[name] = node
        }
        node?.type = type
        return node
    }

    /// setup new node during shader startup or via pipeline
    func addNodeName(_ name: String,
                     after: MtlNode?,
                     type: String)  -> MtlNode? {

        func addCameraToPipeline(_ node: MtlNode) {
            cameraNode = node
            if let cameraNode = cameraNode,
                firstNode == drawNode {
                
                cameraNode.insert(before: drawNode)
                firstNode = cameraNode
            }
        }
        func addDrawToPipeline(_ node: MtlNode) {
            drawNode = node
            firstNode = firstNode ?? drawNode
        }
        func addComputeToPipeline(_ node: MtlNode) {
            cellNode = node
            if let drawNode = drawNode {
                cellNode?.insert(after: after)
                // CA double universe feedback loop
                drawNode.inNode = node
                drawNode.inTex = node.outTex
            }
        }

        // begin -------------------------

        if let node = nodeNamed[name] ?? initNodeName(name, type) {

            switch type {
                case "camera"  : addCameraToPipeline(node)
                case "draw"    : addDrawToPipeline(node)
                case "compute" : addComputeToPipeline(node)
                case "color"   : colorNode = node.insert(after: after)
                case "camix"   : camixNode = node.insert(after: after)
                case "render"  : renderNode = node.insert(after: after)
                case "record"  : recordNode = node.insert(after: after)
                default        : node.insert(after: after)
            }
            return node
        }
        return nil
    }

    /// called from SkyMetal:: makeShader.updateBuffer.addOn
    func swap(inNode node: MtlNode) {
        
        if settingup { return } // don't swap while Setting up pipeline

        switch node.type {

            case "camera":
                // insert camera just after draw node to allow rules to apply to image
                cameraNode = drawNode?.insertNode(node, .below)

            case "camix":
                // insert cammix just before render to mix real and false color
                // TODO: is this sharing the same camera texture?
                camixNode = renderNode?.inNode?.insertNode(node, .below)
                
            case "record":
                recordNode = renderNode?.inNode?.insertNode(node, .below)

            default:
                // replace a compute node with cnew node
                cellNode = cellNode?.replace(with: node)
        }
        print("⟹ pipeline: " + scriptPipeline())
    }

    /// Called whenever view changes orientation or is resized
    static var mtkViewIsFirstTime = true

    public func mtkView(_ mtkView: MTKView, drawableSizeWillChange size: CGSize) {

        if size.width == 0 { return }
        viewSize = size // view.frame.size
        clipRect = MuAspect.fillClip(from: drawSize, to: viewSize).normalize()

        if  SkyPipeline.mtkViewIsFirstTime {
            SkyPipeline.mtkViewIsFirstTime = false
            setupSkyPipeline()
            mtkView.autoResizeDrawable = false

        } else {
            //TODO: setup resize for all active MtlNodes
        }
    }

    // delegates--------------------------------------

    /// Called whenever the view needs to render a frame
    public func draw(in inView: MTKView) {

        // PrintMetalRenderer("-");

        if nodeNamed.isEmpty { return } // nothing to draw yet

        settingup = false // done setting up

        if inView.currentRenderPassDescriptor == nil {
            print("🚫 SkyPipeline currentRenderPassDescriptor == nil ")
            return
        }

        if let command = mtlCommand?.makeCommandBuffer(),
            let firstNode = firstNode {
            command.label = "command"
            //??? firstNode.goCommand(command) //???
        }
        else {
            print("🚫 SkyPipeline could not get either mtlCommand, makeCommandBuffer, or firstNode")
        }
    }

}
