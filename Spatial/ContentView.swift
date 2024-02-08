import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision

#if os(visionOS)

struct ContentView: View {

    static var shared = ContentView()

    @State private var showImmersiveSpace = false
    @State public var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    func immersion(show: Bool) {

        let menuSkyView = MenuSkyView.shared
        let metalLayer = menuSkyView.skyCanvas.pipeline.metalLayer

        immersiveSpaceIsShown = show
        NextFrame.shared.pause = show
        metalLayer.opacity = show ? 0 : 1
        RenderDepth.state = show ? .immer : .metal
    }

    var body: some View {

        ZStack(alignment: .bottom) {
            if !immersiveSpaceIsShown {
                MenuSkyView.shared
                    .frame(minWidth: 640, minHeight: 480)
            } else {
                MenuSkyView.shared
                .frame(maxWidth: 320, maxHeight: 400)
            }

            Toggle(showImmersiveSpace
                   ? "Passthrough"
                   : "Immersive",
                   isOn: $showImmersiveSpace)
            .toggleStyle(.button)
            .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
            .glassBackgroundEffect()

            .onChange(of: showImmersiveSpace) { _, newValue in
                Task {
                    if newValue {
                        switch await openImmersiveSpace(id: "ImmersiveSpace") {
                        case .opened: immersion(show: true)
                        default     : immersion(show: false)

                        }
                    } else if immersiveSpaceIsShown {
                        await dismissImmersiveSpace()
                        immersion(show: false)
                    }
                }
            }
            .task {
                await HandsModel.shared.start()
            }
            .task {
                await HandsModel.shared.publishHandTrackingUpdates()
            }
            .task {
                await HandsModel.shared.monitorSessionEvents()
            }
        }

    }
}
#endif
