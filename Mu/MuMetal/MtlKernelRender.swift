
//
//  MetaDraw.h
//  Sky
//
//  Created by warren on 2/22/19.
//  Copyright © 2019 DeepMuse All rights reserved.
//

import Foundation
import Metal
import MetalKit
import QuartzCore

public class MtlKernelRender: MtlKernel {

    private var mtlPipeline: MTLRenderPipelineState?
    public var renderedTex: MTLTexture? { get {
        return  mtkView?.currentDrawable?.texture ?? nil
       }
    }

    private var mtkView: MTKView?
    private var vertices: MTLBuffer? // Metal buffer for vertex data
    private var vertexCount = 6 // number of vertices in our vertex buffer
    private var viewSize   = SIMD2<Float>(repeating: 0) // size of view for render pipeline
    private var clipOffset = SIMD2<Float>(repeating: 0) // size of view for render pipeline
    private var clipSize   = SIMD2<Float>(repeating: 0) // size of view for render pipeline

    public init(_ name:     String,
                _ device:   MTLDevice,
                _ drawSize: CGSize,
                _ type:     String,
                _ mtkView:  MTKView) {

        self.mtkView = mtkView
        let viewSize = mtkView.frame.size * mtkView.contentScaleFactor
        super.init(name, device, viewSize, type)
        nameIndex["frame"] = 0
        nameIndex["repeat"] = 1
        nameIndex["mirror"] = 2
        setupRenderPipeline(viewSize, drawSize)
    }

    override func setupInOutTextures() {

        inTex = inNode?.outTex // render to screen
        // not output texture here
    }
    
    func setupRenderPipeline(_ viewSize: CGSize, _ drawSize: CGSize) {
        
        self.viewSize = SIMD2<Float>(Float(viewSize.width),
                                     Float(viewSize.height))
        
        let clip = MuAspect.fillClip(from: drawSize, to: viewSize).normalize()
        clipSize = SIMD2<Float>(Float(clip.width),
                                Float(clip.height))

        clipOffset = SIMD2<Float>(Float(clip.minX),
                                  Float(clip.minY))

        print("  MtlKernelRender::fillClip: \(clip)")

        let w2 = Float(viewSize.width / 2)
        let h2 = Float(viewSize.height / 2)
        let v0 = Float(0)
        let v1 = Float(1)

        func MV(_ w: Float, _ h: Float, _ x: Float, _ y: Float) -> MtlVertex {
            return MtlVertex(position: simd_make_float2(w, h),
                             texCoord: simd_make_float2(x, y))
        }
        let quadVertices: [MtlVertex] = [

            MV( w2, -h2, v1, v1),
            MV(-w2, -h2, v0, v1),
            MV(-w2,  h2, v0, v0),
            MV( w2, -h2, v1, v1),
            MV(-w2,  h2, v0, v0),
            MV( w2,  h2, v1, v0)]

        let quadSize = MemoryLayout<MtlVertex>.size * vertexCount

        // Create our vertex buffer, and initialize it with our quadVertices array
        vertices = device.makeBuffer(bytes: quadVertices, length: quadSize, options: .storageModeShared)

        if  let defLib = device.makeDefaultLibrary(),
            let vertexFunc = defLib.makeFunction(name: "vertexShader"),
            let fragmentFunc = defLib.makeFunction(name: "fragmentShader") {

            // descriptor pipeline state object
            let d = MTLRenderPipelineDescriptor()
            d.label = "Texturing Pipeline"
            d.vertexFunction = vertexFunc
            d.fragmentFunction = fragmentFunc
            d.colorAttachments[0].pixelFormat = mtkView?.colorPixelFormat ?? .bgra8Unorm

            do { mtlPipeline = try device.makeRenderPipelineState(descriptor: d) }
            catch { print("🚫 Failed to created _renderPipeline, error \(error)") }
        }
        setupSampler()
    }

    public override func goCommand(_ command: MTLCommandBuffer?) {

        setupInOutTextures()

        if  let command = command,
            let descriptor = mtkView?.currentRenderPassDescriptor,
            let render = command.makeRenderCommandEncoder(descriptor: descriptor),
            let mtlPipeline = mtlPipeline {

            let vx = Double(viewSize.x)
            let vy = Double(viewSize.y)
            let viewPort = MTLViewport(originX: 0, originY: 0,
                                       width: vx, height: vy,
                                       znear: 0, zfar: 1)
            render.setViewport(viewPort)
            render.setRenderPipelineState(mtlPipeline)

            // vertex
            render.setVertexBuffer(vertices, offset: 0, index: 0)
            render.setVertexBytes(&viewSize, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
            render.setVertexBytes(&clipSize, length: MemoryLayout<SIMD2<Float>>.size, index: 2)
            render.setVertexBytes(&clipOffset, length: MemoryLayout<SIMD2<Float>>.size, index:3)

            // fragment
            render.setFragmentTexture(inTex, index: 0)
            render.setFragmentSamplerState(mtlSampler, index: 0)
            
            for buf in nameBuffer.values {
                render.setFragmentBuffer(buf.mtlBuffer, offset: 0, index: buf.bufIndex)
            }
            render.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
            render.endEncoding()
            
            if let currentDrawable = mtkView?.currentDrawable {
                command.present(currentDrawable)
                command.commit()
                command.waitUntilCompleted()
            }
            else {
                print("🚫 MetaKernalRender could not get mtkView.currentDrawable")
            }
        }
        outNode?.goCommand(command)
    }
}
