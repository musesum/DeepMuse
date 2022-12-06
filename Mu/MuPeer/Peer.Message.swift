

import UIKit

public enum Peer { }

extension Peer {
    struct Message: Equatable, Codable {
        let displayName: String
        let body: String
        let time: Date
    }
}

// MARK: - internal
extension Peer.Message {
    init(displayName: String, body: String) {
        self.displayName = displayName
        self.body = body
        time = .init()
    }

    var isUser: Bool { displayName == UIDevice.current.name }
}

// MARK: - Identifiable
extension Peer.Message: Identifiable {
    var id: some Hashable { time }
}
