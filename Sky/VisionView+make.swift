// created by musesum on 9/7/25

import RealityKit
import SwiftUI
import MuFlo // PrintLog
#if os(visionOS)

extension VisionView {
    internal func makeBox() async -> Entity {
        let materials = await makeMaterials(viewModel, side: 512)
        let edge: Float = 0.25
        let mesh = MeshResource.generateBox(width  : edge,
                                            height : edge,
                                            depth  : edge,
                                            splitFaces: true)
        return ModelEntity(mesh: mesh, materials: materials)
    }
    /// Build 6 materials backed by live DrawableQueues
    internal func makeMaterials(_ vm: ViewModel, side: Int) async -> [RealityKit.Material] {
        do {
            let descriptor = TextureResource.DrawableQueue.Descriptor(
                pixelFormat: .bgra8Unorm,
                width: side,
                height: side,
                usage: [.renderTarget, .shaderRead],
                mipmapsMode: .none
            )

            // Create six queues (one per face) — synchronous
            let queues: [TextureResource.DrawableQueue] = try (0..<6).map { _ in try TextureResource.DrawableQueue(descriptor) }

            // Publish queues to the stable ViewModel immediately
            vm.drawQueue = queues

            // Create six in-memory textures and immediately back them with the queues (no asset load)
            var textures: [TextureResource] = []
            for i in 0..<6 {
                let cgImg = make1x1CGImage(UInt8(i))
                let tex = try await TextureResource(image: cgImg, options: .init(semantic: .color))
                tex.replace(withDrawables: queues[i])
                textures.append(tex)
            }

            vm.faceTex = textures
            PrintLog("✅ makeMaterials: faceTex.count=\(textures.count)")

            // Textured UnlitMaterial
            return textures.map {
                var m = UnlitMaterial()
                m.color = .init(texture: .init($0))
                m.faceCulling = .none
                return m
            }
        } catch {
            // Log and fallback: solid-color UnlitMaterial so RealityView always has a 3D entity
            PrintLog("⁉️ VisionView.makeMaterials error: \(error)")
            vm.drawQueue = []
            vm.faceTex = []
            let tints: [UIColor] = [.red, .green, .blue, .yellow, .cyan, .orange]
            return tints.map { tint in
                var m = UnlitMaterial()
                m.color = .init(tint: tint)
                return m
            }
        }
    }

    // temp 1×1 CGImage
    internal func make1x1CGImage(_ face: UInt8) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixel: [UInt8] = [0, 0, 0, 0] // transparent
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * 1
        let bitsPerComponent = 8

        guard let ctx = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let image = ctx.makeImage() else {
            // As a last resort, create a 1×1 opaque black pixel
            var fallbackPixel: [UInt8] = [0, 0, 0, 255]
            let fallbackCtx = CGContext(
                data: &fallbackPixel,
                width: 1,
                height: 1,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            return fallbackCtx!.makeImage()!
        }
        return image
    }

}
#endif
