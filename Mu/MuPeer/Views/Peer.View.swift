import SwiftUI

extension Peer {
    struct View: SwiftUI.View {
        @EnvironmentObject var sessionCoordinator: Peer.SessionCoordinator
        @State private var messageText = ""

        var body: some SwiftUI.View {
            VStack {
                chatInfoView
                Peer.ListView()
                    .environmentObject(sessionCoordinator)
                messageField
            }
            .navigationBarTitle("Chat", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Leave") {
                        sessionCoordinator.leaveChat()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

private extension Peer.View {
    var messageField: some SwiftUI.View {
        VStack(spacing: 0) {
            Divider()

            TextField("Enter Message",
                      text: $messageText,
                      onCommit: {
                guard !messageText.isEmpty else { return }
                sessionCoordinator.send(messageText)
                messageText = ""
            })
            .padding()
        }
    }

    var chatInfoView: some SwiftUI.View {
        VStack(alignment: .leading) {
            Divider()
            HStack {
                Text("People in chat:")
                    .fixedSize(horizontal: true, vertical: false)
                    .font(.headline)
                if sessionCoordinator.peers.isEmpty {
                    Text("Empty")
                        .font(Font.caption.italic())
                        .foregroundColor(Color("dark"))
                } else {
                    chatParticipants
                }
            }
            .padding(.top, 8)
            .padding(.leading, 16)
            Divider()
        }
        .frame(height: 44)
    }

    var chatParticipants: some SwiftUI.View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(sessionCoordinator.peers, id: \.self) { peer in
                    Text(peer.displayName)
                        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, 6)
                        .background(Color("dark"))
                        .foregroundColor(.white)
                        .font(Font.body.bold())
                        .cornerRadius(9)
                }
            }
        }
    }
}
