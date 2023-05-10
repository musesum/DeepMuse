import SwiftUI

extension Peer {
  struct ListView: SwiftUI.View {
    @EnvironmentObject var sessionCoordinator: Peer.SessionCoordinator

    var body: some SwiftUI.View {
      ScrollView {
        ScrollViewReader { reader in
          VStack(alignment: .leading, spacing: 20) {
            ForEach(sessionCoordinator.messages) { message in
              Peer.Message.BodyView(message: message)
                .onAppear {
                  if message == sessionCoordinator.messages.last {
                    reader.scrollTo(message.id)
                  }
                }
            }
          }
          .padding(16)
        }
      }
      .background(Color(UIColor.systemBackground))
    }
  }
}
