import SwiftUI

extension Peer.Message {
  struct BodyView: SwiftUI.View {
    let message: Peer.Message

    var body: some View {
      HStack {
        if message.isUser {
          Spacer()
        }
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
          Text(message.body)
            .font(.body)
            .padding(8)
            .foregroundColor(.white)
            .background(message.isUser ? .green : Color("dark"))
            .cornerRadius(9)
          Peer.Message.TimestampView(message: message)
        }
      }
    }
  }
}
