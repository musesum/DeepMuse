import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu
import MuHands

#if os(visionOS)

struct VolumeView: View {
    
    @Environment(ImmersionModel.self) var immersionModel
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var handState: HandsPhase
    @ObservedObject var showTime = ShowTime()
    @ObservedObject var handsPhase: HandsPhase
    
    let appModel: VisionModel
    let skyModel: SkyModel
    let nextFrame: NextFrame
    let pipeline: SkyPipeline
    
    func logScenePhase(_ phase: ScenePhase, changed: Bool) {
        var msg = "🎬 VolumeView scenePhase: "
        switch phase {
        case .active     : msg += "🟩 .active"
        case .inactive   : msg += "🟥 .inactive"
        case .background : msg += "🟦 .background"
        @unknown default : break
        }
        DebugLog { P(msg) }
    }
    
    init(_ appModel: VisionModel) {
        self.appModel = appModel
        self.skyModel = appModel.skyModel
        self.nextFrame = skyModel.nextFrame
        self.handsPhase = skyModel.handsPhase
        self.pipeline = skyModel.pipeline
        PrintLog("🎬 VolumeView")
    }
    
    func changeHandsPhase(_ handsPhase: HandsPhase) {
        let state = handsPhase.state
        if let phase = state.left {
            switch phase {
            case .ended : showTime.startAutoFade()
            default     : showTime.showNow()
            }
        }
        if let phase = state.right {
            switch phase  {
            case .ended : showTime.startAutoFade()
            default     : showTime.showNow()
            }
        }
        let title = "VolumeView "+handsPhase.handsState
        TimeLog(title, interval: 1) { P(title) }
    }
    
    var immersed: Bool { immersionModel.isImmersive }
    var showOpacity: CGFloat {  immersed ? showTime.opacity : 1 }
    var showAnimation: Animation { showTime.animation }
    
    var body: some View {
        ZStack {
            // Create a RealityKit view for the volume
            RealityView { content in
                // Create the cube entity using the CubeNode's mesh
                if let cubeEntity = createCubeEntity() {
                    content.add(cubeEntity)
                }
            } update: { content in
                // Update rotation animation
                content.entities.forEach { entity in
                    updateRotation(entity)
                }
            }
            
            // Overlay controls
            VStack {
                Spacer()
                
                Button {
                    immersionModel.goImmersive.toggle()
                } label: {
                    Image(immersionModel.goImmersive
                          ? "icon.room.white"
                          : "icon.galaxy.white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                }
                .padding(20)
            }
        }
        .onAppear {
            logScenePhase(scenePhase, changed: false)
            skyModel.setImmersion(immersionModel.goImmersive)
            Task {
                if let handsTracker = appModel.handsTracker {
                    await handsTracker.startHands()
                }
            }
        }
        .opacity(showOpacity)
        .animation(showAnimation, value: showOpacity)
        .onChange(of: handsPhase.update) { changeHandsPhase(handsPhase) }
    }
    
    private func createCubeEntity() -> Entity? {
        // Create a cube entity that will be rendered with the pipeline's CubeNode
        let cubeMesh = MeshResource.generateBox(size: 0.4, cornerRadius: 0.02)
        
        // Create a material with visual effects
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .white.withAlphaComponent(0.9))
        material.metallic = .init(floatLiteral: 0.2)
        material.roughness = .init(floatLiteral: 0.3)
        material.emissiveColor = .init(color: .init(white: 0.1, alpha: 1.0))
        material.emissiveIntensity = 0.5
        
        // Create the model entity
        let cubeEntity = ModelEntity(mesh: cubeMesh, materials: [material])
        
        // Position the cube at the center
        cubeEntity.position = [0, 0, 0]
        
        // Add rotation animation component
        cubeEntity.components.set(RotationComponent())
        
        // Add scale for better visibility
        cubeEntity.scale = [1.0, 1.0, 1.0]
        
        // Create a container entity to hold the cube
        let containerEntity = Entity()
        containerEntity.addChild(cubeEntity)
        
        // Add lighting
        let lightEntity = createLighting()
        containerEntity.addChild(lightEntity)
        
        return containerEntity
    }
    
    private func createLighting() -> Entity {
        let lightEntity = Entity()
        
        // Add point light
        var pointLightComponent = PointLightComponent()
        pointLightComponent.intensity = 10000
        pointLightComponent.color = .white
        
        let pointLightEntity = Entity()
        pointLightEntity.components.set(pointLightComponent)
        pointLightEntity.position = [0, 1, 1]
        lightEntity.addChild(pointLightEntity)
        
        return lightEntity
    }
    
    private func updateRotation(_ entity: Entity) {
        // Recursively update rotation for all entities with RotationComponent
        if let rotationComponent = entity.components[RotationComponent.self] {
            let angle = Float(Date().timeIntervalSince1970) * rotationComponent.speed
            entity.transform.rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
        }
        
        // Update children
        entity.children.forEach { child in
            updateRotation(child)
        }
    }
}

// Simple rotation component for animation
struct RotationComponent: Component {
    var speed: Float = 0.5
}

#endif
