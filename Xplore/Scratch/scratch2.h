SpatialMetal2 {

    renderLoop() {
        renderFrame() {
            queryAnchor()
            updateUniforms(drawable) {
                earthEyeBuf?.updateUniforms(drawable, earthMatrix) {
                    updateTripleBufferedUniform() {
                        uniformEyes = UnsafeMutableRawPointer(uniformPtr)
                            .bindMemory(to: UniEyes.self, capacity: 1)
                    }
                    self.uniformEyes[0].eye.0 = uniformForEyeIndex(0)
                    self.uniformEyes[0].eye.1 = uniformForEyeIndex(1)
                }
                starsEyeBuf?.updateUniforms(drawable, starsMatrix) {...}
            }

            drawLayer(commandBuf, frame, drawable) {
                let renderPass = makeRenderPass(drawable: drawable)
                let renderCmd = commandBuf.makeRenderCommandEncoder(...)
                renderCmd.setViewports(drawable.views.map { $0.textureMap.viewport })

                starsEyeBuf.setMappings(drawable, viewports, renderCmd) {
                    setOptionalStereoAmplification()
                    renderCommand.setVertexBuffer(...)
                }
                starsEyeBuf.draw(renderCmd, pipeline, winding) {
                    for in mesh..layouts {
                        renderCmd.setVertexBuffer(vb.buffer, vb.offset, index)
                    }
                    renderCmd.setFragmentTexture(texture, index: TextureIndex.colori)

                    for submesh in mesh.submeshes {
                        renderCmd.drawIndexedPrimitives(...)
                    }
                }
                earthEyeBuf.setMappings(drawable, viewports, renderCmd) {...}
                earthMesh.draw(renderCmd, earthPipe, .counterClockwise) {...}
            }
        }
    }
}

DeepMuse {
    SkyCanvas::nextFrame {
        MetPipeline::drawNodes {

            tripleSemaphore.wait(...)
            
            let commandBuf = ...
            let drawable = ...
            
            let computeCmd = ...
            for node in .computing {
                node?.updateTextures
                note?.computeNode(computeCmd)
            }
            computeCmd.endEncoding

            let renderCmd = ...
            for node in .rendering {
                node?.updateTextures
                node?.
            }
            func computeNode(computeCmd) {
                computeCmd.setTexture(inTex, 0)
                computeCmd.setTexture(outTex, 1)
                computeCmd.setTexture(altTex, 2)
                for buf in nameBuffer.values {
                    computeCmd.setBuffer(buf.mtlBuffer, offset: 0, index: buf.bufIndex)
                }
                computeCmd.setComputePipelineState(computeState)
                computeCmd.dispatchThreadgroups(...)
            }

            MetNodeCompute("slide")::computeNode(commandBuf, drawable) {...}
            MetNodeCompute("color")::computeNode(commandBuf, drawable) {...}
            MetNodeCompute("slide")::computeNode(commandBuf, drawable) {...}

            MetNodeFlatmap::renderNode(renderCmd) {
                    renderCmd.setViewport(MTLViewport(viewSize))
                    renderCmd.setRenderPipelineState(flatPipe)
                    // vertex
                    renderCmd.setVertexBuffer(vertices, offset: 0, index: 0)
                    renderCmd.setVertexBytes(&viewSize , length: Float2Len, index: 1)
                    renderCmd.setVertexBytes(&clipFrame, length: Float4Len, index: 2)
                    // fragment
                    renderCmd.setFragmentTexture(inTex, index: 0)
                    
                    for buf in nameBuffer.values {
                        renderCmd.setFragmentBuffer(buf.mtlBuffer, offset: 0, index: buf.bufIndex)
                    }
                    renderCmd.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                }
            MetNodeCompute("plato")::nextCommand(commandBuf, drawable)) {
                updateTextures() {
                    updateUniforms() {
                        var platoUniforms = PlatoUniforms(...)
                        memcpy(uniformBuf.contents() + uniformLen, &platoUniforms, uniformLen)
                    }
                    altTex.replace(...  palBytes)
                    inTex = (inNode as? MetNodeCubemap.cubeTex) ?? inNode?.outTex
                }
                renderNode(renderCmd) { ...
                    renderCmd.setVertexBuffer(platonic.platoModel.vertexBuf, offset: 0, index: 0)
                    renderCmd.setVertexBuffer(uniformBuf, offset: uniformLen, index: 1)
                    renderCmd.setFragmentBuffer(uniformBuf, offset: uniformLen, index: 1)

                    renderCmd.setFragmentTexture(cubeTex, index: 0)
                    renderCmd.setFragmentTexture(inTex, index: 1)
                    renderCmd.setFragmentTexture(altTex, index: 2)

                    renderCmd.drawPrimitives(vertexCount: indexCount)
                }
            }
        }
    }
}





