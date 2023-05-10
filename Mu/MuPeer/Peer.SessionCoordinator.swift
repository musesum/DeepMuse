

import Combine
import Foundation
import MultipeerConnectivity

extension Peer {
    final class SessionCoordinator: NSObject, ObservableObject {
        @Published var connectedToChat = false

        @Published private(set) var messages: [Message] = []
        @Published private(set) var peers: [MCPeerID]
        @Published private(set) var browser: MCBrowserViewController.View?

        private let peerID: MCPeerID

        private var advertiser: MCNearbyServiceAdvertiser?
        private var session: MCSession?
        private var isHosting = false
        private var cancellables: Set<AnyCancellable> = []

        init(
            peers: [MCPeerID] = [],
            peerID: MCPeerID = .init(displayName: UIDevice.current.name)
        ) {
            self.peers = peers
            self.peerID = peerID
        }
    }
}

// MARK: - internal
extension Peer.SessionCoordinator {
    func host() {
        isHosting = true
        peers.removeAll()
        messages.removeAll()
        connectedToChat = true
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.session = session
        session.delegate = self

        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: nil,
            serviceType: .serviceType
        )
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser
    }

    func join() {
        peers.removeAll()
        messages.removeAll()

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.session = session
        session.delegate = self

        let browser = MCBrowserViewController.View(serviceType: .serviceType, session: session)
        self.browser = browser
        cancellables = [
            browser.didFinishPublisher.sink { [unowned self] in
                connectedToChat = true
                self.browser = nil
            },
            browser.wasCancelledPublisher.sink { [unowned self, unowned session] in
                session.disconnect()
                connectedToChat = false
                self.browser = nil
            }
        ]
    }

    func leaveChat() {
        isHosting = false
        connectedToChat = false
        advertiser?.stopAdvertisingPeer()
        messages.removeAll()
        session = nil
        advertiser = nil
    }

    func send(_ message: String) {
        let chatMessage = Peer.Message(displayName: peerID.displayName, body: message)
        messages.append(chatMessage)

        guard
            let session = session,
            let data = message.data(using: .utf8),
            !session.connectedPeers.isEmpty
        else { return }

        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - private
private extension Peer.SessionCoordinator {
    func sendHistory(to peer: MCPeerID) throws {
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("messages.data")
        let historyData = try PropertyListEncoder().encode(messages)
        try historyData.write(to: tempFile)
        session?.sendResource(at: tempFile, withName: "Chat_History", toPeer: peer) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}

private extension String {
    static let serviceType = "jobmanager-chat"
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension Peer.SessionCoordinator: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer _: MCPeerID,
                    withContext _: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension Peer.SessionCoordinator : MCSessionDelegate {
    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {

        guard let message = String(data: data, encoding: .utf8) else { return }

        DispatchQueue.main.async {
            [unowned self, chatMessage = Peer.Message(displayName: peerID.displayName, body: message)
            ] in

            messages.append(chatMessage)
        }
    }

    func session(_: MCSession, peer peerID: MCPeerID,
                 didChange state: MCSessionState) {

        switch state {
            case .connected:
                if !peers.contains(peerID) {
                    DispatchQueue.main.async { [unowned self] in
                        peers.insert(peerID, at: 0)
                    }
                    if isHosting {
                        try? sendHistory(to: peerID)
                    }
                }
            case .notConnected:
                DispatchQueue.main.async { [unowned self] in
                    if let index = peers.firstIndex(of: peerID) {
                        peers.remove(at: index)
                    }

                    if peers.isEmpty, !self.isHosting {
                        connectedToChat = false
                    }
                }
            case .connecting:
                print("Connecting to: \(peerID.displayName)")
            @unknown default:
                print("Unknown state: \(state)")
        }
    }

    func session(_: MCSession, didReceive _: InputStream, withName _: String, fromPeer _: MCPeerID) { }

    func session(_: MCSession, didStartReceivingResourceWithName _: String, fromPeer _: MCPeerID, with _: Progress) {
        print("Receiving chat history")
    }

    func session( _: MCSession,
                  didFinishReceivingResourceWithName _: String,
                  fromPeer _: MCPeerID,
                  at localURL: URL?,
                  withError _: Error?) {
        
        guard let localURL = localURL else { return }

        do {
            let data = try Data(contentsOf: localURL)
            let messages = try PropertyListDecoder().decode([Peer.Message].self, from: data)
            DispatchQueue.main.async { [unowned self] in
                self.messages.insert(contentsOf: messages, at: 0)
            }
        } catch { }
    }
}
