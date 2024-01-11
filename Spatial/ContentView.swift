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
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow

    func immersion(show: Bool) {

        let skyView = MenuSkyView.shared

        if show {
            immersiveSpaceIsShown = true
            NextFrame.shared.pause = true
            DepthRender.state = .vision
            //_ = skyView.disabled(true)
            //dismissWindow(id: "App")

        } else {
            immersiveSpaceIsShown = false
            showImmersiveSpace = false
            NextFrame.shared.pause = false
            DepthRender.state = .metal
            //_ = skyView.disabled(false)
            //openWindow(id: "App")

        }

    }

    var body: some View {

        ZStack(alignment: .bottom) {
            if !immersiveSpaceIsShown {
                MenuSkyView.shared
                    .frame(minWidth: 640, minHeight: 480)
            }

            Toggle(showImmersiveSpace
                   ? "Exit Immersive Space"
                   : "Launch Immersive Space",
                   isOn: $showImmersiveSpace)
            .toggleStyle(.button)
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
}
#endif
