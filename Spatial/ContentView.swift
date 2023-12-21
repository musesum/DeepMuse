import SwiftUI
import RealityKit
import MuFlo // NextFrame
#if os(visionOS)
struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {

        Toggle(showImmersiveSpace
               ? "Exit Immersive Space"
               : "Launch Immersive Space",
               isOn: $showImmersiveSpace)
        .toggleStyle(.button)

        .padding()
        .glassBackgroundEffect()

        .onChange(of: showImmersiveSpace) { _,newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        immersiveSpaceIsShown = true
                        NextFrame.shared.pause = true
                    default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                        NextFrame.shared.pause = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                    NextFrame.shared.pause = false
                }
            }
        }
    }
}
#endif
