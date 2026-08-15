//  created by musesum on 8/6/26.

import Foundation
import Metal
import MuFlo
import MuVision

/// carries render-side refs across the compile queue; published only on main
private struct EmbedJob: @unchecked Sendable {
    let shader: Shader
    let compute: ComputeNode
    let device: MTLDevice
    let done: (([EmbedError]) -> Void)?
}

extension SkyPipeline {

    /// bind compute nodes with a kernel template; recompile when their embed changes
    public func bindEmbeds() {
        if let pipeSource {
            bindEmbed(pipeSource)
        }
        bindRefEmbeds(root˚)
    }

    /// menu flos declaring `{{ @<file.metal> }}` edit the shader of that file
    private func bindRefEmbeds(_ flo: Flo) {
        if let embed = flo.embed,
           let fileRef = embed.fileRef {
            bindRefEmbed(flo, embed, fileRef)
        }
        flo.children.forEach { bindRefEmbeds($0) }
    }

    private func bindRefEmbed(_ flo: Flo, _ embed: Embed, _ fileRef: String) {

        let fileName = (fileRef as NSString).deletingPathExtension
        guard let node = pipeNode(fileName: fileName) else {
            return PrintLog("⁉️ embed \(flo.path()) has no pipe node for \(fileRef)")
        }
        // template body is the delta baseline; a parsed body stays the tweak
        if let template = MuVision.read(fileName, "metal") {
            if let body = Shader.templateBody(template) {
                embed.setTemplate(body)
            } else {
                PrintLog("⁉️ embed \(fileRef) has no {{ }} region — code leaf inert")
            }
        }
        if embed.hasDelta() {
            compileEmbed(node, body: embed.getVal() as? String)
        }
        flo.addClosure { [weak self, weak node] flo, _ in
            // an unseeded embed has nothing to stitch; every other flo change
            // (slider, selection) reaches here too, so keep it quiet
            guard let self, let node,
                  let body = flo.embed?.getVal() as? String, !body.isEmpty
            else { return }
            self.compileEmbed(node, body: body) // no-ops when the body is unchanged
        }
    }

    /// depth-first search for the pipe node whose shader reads `fileName.metal`
    public func pipeNode(fileName: String, from: PipeNode? = nil) -> PipeNode? {
        guard let node = from ?? pipeSource else { return nil }
        if node.shader?.fileName == fileName { return node }
        for child in node.pipeChildren {
            if let hit = pipeNode(fileName: fileName, from: child) { return hit }
        }
        return nil
    }

    private func bindEmbed(_ node: PipeNode) {
        if node is ComputeNode,
           let shader = node.shader,
           let fileName = shader.fileName {

            if let template = MuVision.read(fileName, "metal") {
                shader.compiledBody = Shader.templateBody(template)
            }
            if node.pipeFlo˚.embed != nil {
                compileEmbed(node)
            }
            node.pipeFlo˚.addClosure { [weak self, weak node] flo, _ in
                guard let self, let node, flo.embed != nil else { return }
                self.compileEmbed(node)
            }
        }
        node.pipeChildren.forEach { bindEmbed($0) }
    }

    /// depth-first search for the pipe node bound to flo
    public func pipeNode(for flo: Flo, from: PipeNode? = nil) -> PipeNode? {
        guard let node = from ?? pipeSource else { return nil }
        if node.pipeFlo˚ === flo { return node }
        for child in node.pipeChildren {
            if let hit = pipeNode(for: flo, from: child) { return hit }
        }
        return nil
    }

    /// stitch + compile + build pipe state off-main; publish the swap on main,
    /// where the render loop runs, so a frame never sees a torn write
    @discardableResult
    public func compileEmbed(_ node: PipeNode,
                             body: String? = nil,
                             done: (([EmbedError]) -> Void)? = nil) -> Bool {

        func fail(_ message: String) -> Bool {
            done?([EmbedError(line: 1, col: 0, message: message)])
            return false
        }
        guard let body = body ?? (node.pipeFlo˚.embed?.getVal() as? String)
        else { return fail("no embed body on \(node.pipeName)") }
        guard let compute = node as? ComputeNode
        else { return fail("\(node.pipeName) is not a compute node") }
        guard let shader = node.shader,
              let fileName = shader.fileName,
              let kernelName = shader.kernelName
        else { return fail("\(node.pipeName) has no kernel shader") }
        guard let template = MuVision.read(fileName, "metal")
        else { return fail("missing template \(fileName).metal") }

        if shader.compiledBody == body {
            done?([])
            return true
        }
        let job = EmbedJob(shader: shader, compute: compute, device: device, done: done)

        DispatchQueue.global(qos: .userInitiated).async {

            let finish: ([EmbedError]) -> Void = { errors in
                for e in errors {
                    DebugLog { P("⁉️ embed \(fileName).metal:\(e.line):\(e.col) \(e.message)") }
                }
                DispatchQueue.main.async { job.done?(errors) }
            }
            var bodyLine = 1
            do {
                let stitched = try Shader.stitch(template, body: body)
                bodyLine = stitched.bodyLine
                let library = try job.device.makeLibrary(source: stitched.source,
                                                         options: MTLCompileOptions())
                guard let function = library.makeFunction(name: kernelName) else {
                    return finish([EmbedError(line: 1, col: 0,
                                              message: "kernel \(kernelName) not found in compiled source")])
                }
                let pipeState = try job.device.makeComputePipelineState(function: function)
                DispatchQueue.main.async {
                    job.shader.runtimeLibrary = library
                    job.shader.kernelFunction = function
                    job.shader.compiledBody = body
                    job.compute.swapComputePipe(pipeState)
                    DebugLog { P("{} embed \(fileName).metal compiled · live") }
                    job.done?([])
                }
            } catch StitchError.bodyClosesEmbed {
                finish([EmbedError(line: 1, col: 0, message: "body contains }} which ends a .flo embed")])
            } catch StitchError.missingMarkers {
                finish([EmbedError(line: 1, col: 0, message: "template has no {{ }} region")])
            } catch {
                var errors = Shader.embedErrors(error.localizedDescription, bodyLine: bodyLine)
                if errors.isEmpty { // unparsed log must not read as success
                    errors = [EmbedError(line: 1, col: 0, message: error.localizedDescription)]
                }
                finish(errors)
            }
        }
        return true
    }
}
