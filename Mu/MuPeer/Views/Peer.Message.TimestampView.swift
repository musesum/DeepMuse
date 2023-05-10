
import SwiftUI

extension Peer.Message {
  struct TimestampView: View {
    let message: Peer.Message

    var body: some View {
      HStack(spacing: 2) {
        Text(message.displayName)
        Text("@")
        Text("\(message.time, formatter: DateFormatter.timestampFormatter)")
        if !message.isUser {
          Spacer()
        }
      }
      .font(.caption)
      //.foregroundColor(Color("dark"))
    }
  }
}
