SpatialMetal2 {

    renderLoop() {

        renderFrame() {
            updates
            timing
            commandBuf
            tripleSemaphore.wait
            layerFrame.startSubmission
            queryDeviceAnchor

            delegate.renderLayer {

                renderCmd.setViewPorts
                setViewMappings
                updateUniforms

                starsNode::drawLayer {
                    eyebuf.setUniformBuf
                    renderCmd.setRenderPipelineState()
                    mesh.drawMesh {
                        renderCmd.setFragmentTexture()
                        renderCmd.setFrontFacing
                        for (index,layout) in .vertexDescriptor.layouts {
                            renderCmd.setVertexBuffer(buffer,offset,index)
                        }
                        for submesh in mtkMesh.submeshes {
                            renderCmd.drawIndexedPrimitives(...)
                        }
                    }
                }
                earthNode::drawLayer {...}

                rnderCmd.endEncoding
                layerDrawable.encodePresent(commandBuffer: commandBuf)
                commandBuf.commit
            }
            layerFrame.endSubmission
        }
    }
}

DeepMuse {

    SkyCanvas::nextFrame {

        Pipeline::renderFrame {
            tripleSemaphore.wait
            commandBuf, drawable = metalLayer.nextDrawable()

            renderNodes(commandbuf,drawable) {

                computeNodes()
                
                renderCmd.setViewPorts
                setViewMappings

                while renderNode ... {
                    renderNode.updateUniforms()
                    renderNode.updateTextures()

                    renderNode.renderNode(renderCmd) {
                        renderCmd.setRenderPipelineState
                        renderCmd.setVertexBuffer(uniformBuf)
                        renderCmd.setFragmentTexture(cubeTex, index: 0)
                        renderCmd.setFragmentTexture(inTex, index: 1)
                        for buf ... {
                            renderCmd.setFragmentBuffer(buf.mtlBuffer, offset: 0, index: buf.bufIndex)
                        }
                        cubemapMetal.drawMesh {
                            renderCmd.setFrontFacing
                            renderCmd.setDepthStencilState
                            for (index,layout) in .vertexDescriptor.layouts {
                                renderCmd.setVertexBuffer(buffer,offset,index)
                            }
                            for submesh in mtkMesh.submeshes {
                                renderCmd.drawIndexedPrimitives(...)
                            }
                        }
                    }

                }
                renderCmd.endEncodeing()
            }
            commandBuf.present(drawable)
            commandBuf.commit()
            commandBuf.waitUntilCompleted()
        }
    }

}





