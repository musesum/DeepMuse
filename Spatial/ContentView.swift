import SwiftUI
import RealityKit
import MuFlo // NextFrame
import MuVision

#if os(visionOS)
struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var touchesView = MenuSkyView.shared.skyCanvas.touchView

    func immersion(show: Bool) {
        if show {
            immersiveSpaceIsShown = true
            NextFrame.shared.pause = true
            DepthRender.state = .vision
            touchesView.isHidden = true

        } else {
            immersiveSpaceIsShown = false
            showImmersiveSpace = false
            NextFrame.shared.pause = false
            DepthRender.state = .metal
            touchesView.isHidden = false
        }

    }

    var body: some View {

        Toggle(showImmersiveSpace
               ? "Exit Immersive Space"
               : "Launch Immersive Space",
               isOn: $showImmersiveSpace)
        .toggleStyle(.button)
        .padding()
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
    }
}
#endif
