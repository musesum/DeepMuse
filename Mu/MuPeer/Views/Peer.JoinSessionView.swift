

import SwiftUI

extension Peer {
    struct JoinSessionView: SwiftUI.View {
        @StateObject private var sessionCoordinator = Peer.SessionCoordinator()

        var body: some SwiftUI.View {
            VStack(spacing: 24) {
                Image(systemName: "network")
                    .resizable()
                    .frame(width: 100, height: 100)

                let mcBrowser = sessionCoordinator.browser

                NavigationLink(destination: mcBrowser?.navigationBarHidden(true),
                               tag: .browser,
                               selection: destination) {

                    Button(action: sessionCoordinator.join,
                           label: { Label("Join a Session", systemImage: "arrow.up.right.and.arrow.down.left.rectangle" ) } )
                    .buttonStyle(MultipeerButtonStyle()) }

                Button(action: sessionCoordinator.host,
                       label: { Label("Host a Session", systemImage: "plus.circle") } )
                .buttonStyle(MultipeerButtonStyle())

                let chat = Peer.View().environmentObject(sessionCoordinator)
                NavigationLink(destination: chat,
                               tag: .chat,
                               selection: destination) { }
            }
            .navigationTitle("Peer")
        }
    }
}

private extension Peer.JoinSessionView {
    struct MultipeerButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .font(.headline)
                .background(configuration.isPressed
                            ? Color("dark")
                            : Color.accentColor)
                .cornerRadius(9.0)
                .foregroundColor(.white)
        }
    }

    enum Destination {
        case browser, chat
    }

    var destination: Binding<Destination?> {
        .constant(
            sessionCoordinator.browser != nil
            ? .browser
            : sessionCoordinator.connectedToChat
            ? .chat
            : nil
        )
    }
}
