import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision
import MetalKit
import MuMenu
import MuHands

#if os(visionOS)

final class ViewModel: ObservableObject {
    @Published var drawQueue: [TextureResource.DrawableQueue] = []
    @Published var faceTex: [TextureResource] = []
}

struct VisionView: View {
    let id = Visitor.nextId()
    @Environment(ImmersionModel.self) var immersionModel
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var handState: HandsPhase
    @ObservedObject var showTime = ShowTime()
    @ObservedObject var handsPhase: HandsPhase

    let appModel: VisionModel
    let skyModel: SkyModel
    let nextFrame: NextFrame
    let pipeline: Pipeline

    var _cubeNode: CubeNode?
    var cubeNode: CubeNode? {
        guard let _cubeNode = _cubeNode ?? pipeline.node["cube"] as? CubeNode else { return nil }
        return _cubeNode
    }
    @StateObject internal var viewModel = ViewModel()

    var showBoxView: Bool {
        let goImmersive = immersionModel.goImmersive
        let isImmersive = immersionModel.isImmersive
        NoDebugLog { P("🎬 SkyView go/is Immersive: \(goImmersive)/\(isImmersive) id: \(id)") }
        return !goImmersive
    }

    init(_ appModel: VisionModel) {
        self.appModel = appModel
        self.skyModel = appModel.skyModel
        self.nextFrame = skyModel.nextFrame
        self.handsPhase = skyModel.handsPhase
        self.pipeline = skyModel.pipeline
        PrintLog("🎬 VisionView")
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
        let title = "VisionView " + handsPhase.handsState
        TimeLog(title, interval: 1) { P(title) }
    }

    var immersed: Bool { immersionModel.isImmersive }
    var showOpacity: CGFloat { immersed ? showTime.opacity : 1 }
    var showAnimation: Animation { showTime.animation }

    var body: some View {
        ZStack(alignment: .bottom) {
            if showBoxView {
                RealityView { content in
                    let box = await makeBox()
                    content.add(box)
                    ManipulationComponent.configureEntity(box)
                } update: { _ in
                    if viewModel.drawQueue.count == 6 {
                        cubeNode?.boxFaces(to: viewModel.drawQueue)
                    }
                }
                .realityViewLayoutBehavior(.centered)
            }
            SkyView(skyModel)

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
            .offset(x: 0, y: -20)
            .padding(6)
        }
        .frame(minWidth  : immersionModel.goImmersive ? 640 : 800,
               minHeight : immersionModel.goImmersive ? 480 : 600)
        .frame(maxWidth  : immersionModel.goImmersive ? 800 : 1920,
               maxHeight : immersionModel.goImmersive ? 480 : 1280)

        .onAppear {
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
}
#endif
