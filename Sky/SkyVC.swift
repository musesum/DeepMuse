
import UIKit
import SwiftUI
import Tr3
import MultipeerConnectivity

class SkyVC: UIViewController {

    static var shared = SkyVC()
    var tr3Root = SkyTr3.shared.root
    var touchDraw = TouchDraw(SkyTr3.shared.root)
    var mainPeer˚: Tr3?

    var peerID: MCPeerID!
    var mcSession: MCSession!
    //??? var browser: MCBrowserViewController!
    var mcNearbyServiceAdvertiser: MCNearbyServiceAdvertiser?

    override func viewDidLoad() {
        mainPeer˚ = SkyTr3.shared.root.bindPath("sky.main.peer") { t, _ in
            self.joinSession()
        }
    }
    func joinSession() {
        let mcBrowser = MCBrowserViewController(serviceType: "deepmuse", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    func startHosting() {
        mcNearbyServiceAdvertiser?.stopAdvertisingPeer()
        mcNearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "deepmuse")
        mcNearbyServiceAdvertiser?.delegate = self
        mcNearbyServiceAdvertiser?.startAdvertisingPeer()
    }

    override func viewDidAppear(_ animated: Bool) {

        let bounds = UIScreen.main.bounds
        view = SkyPipeline.shared.setViewFrame(bounds)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        setupMenuView()
        setupMCSession()
        SkyMetal.shared.makeShader(for: tr3Root)
        let _ = SkyMain.shared
        // MuAudio.shared.test()
        MuMidi.shared.test(root: tr3Root)
    }

    func setupMCSession() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        startHosting()
    }
    func setupMenuView() {
        // add menu
        let menuView = UIHostingController(rootView: MenuSkyView())
        view.addSubview(menuView.view)
        menuView.view.translatesAutoresizingMaskIntoConstraints = false
        menuView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        menuView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        menuView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        menuView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        menuView.view.backgroundColor = .clear
    }
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        get {
            UIDevice.current.userInterfaceIdiom == .phone
            ? UIInterfaceOrientationMask.allButUpsideDown
            : UIInterfaceOrientationMask.all
        }
    }

    override var shouldAutorotate: Bool { false }
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
    override var prefersStatusBarHidden: Bool { return true }
}

extension SkyVC: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
}
extension SkyVC: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Invitation Received"

        let declineAction = UIAlertAction(title: "Decline", style: .cancel) { [weak self] _ in
            invitationHandler(false, self?.mcSession)
        }
        let acceptAction = UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
            invitationHandler(true, self?.mcSession)
        }

        let ac = UIAlertController(title: appName, message: "'\(peerID.displayName)' wants to connect.", preferredStyle: .alert)
        ac.addAction(declineAction)
        ac.addAction(acceptAction)

        present(ac, animated: true)
    }
}

// MARK: - MCSessionDelegate
extension SkyVC: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let name = peerID.displayName
        switch state {
            case .connected: print("⚡️ Connected: \(name)")
            case .connecting: print("⚡️ Connecting: \(name)")
            case .notConnected: print("⚡️ Not Connected: \(name)")
            @unknown default: print("⚡️ unknown : \(name)")
        }
    }

    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        return certificateHandler(true)
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            //??? self.delegate?.received(data: data, from: peerID)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}

}

extension SkyVC {

    // Used to convert data into native Dictionary object.
    func unpack(json: Data) -> [String: Any] {
        var message = [String: Any]()
        message = try! JSONSerialization.jsonObject(with: json, options: .allowFragments) as! [String : Any]
        return message
    }

    // Creates data object for IoT/net communications and syncs with other player.
    func package(json message: [String : Any]) {
        var messageData : Data
        do {
            messageData = try JSONSerialization.data(withJSONObject: message, options: .prettyPrinted)
        } catch {
            print("Error packaging message: \(error.localizedDescription)")
            return
        }
//        syncPlayers(with: messageData)
    }

//    // Sends data objects to other IoT players/devices.
//    func syncPlayers(with message: Data) {
//        do {
//            try mpcHandler.session.send(message, toPeers: mpcHandler.session.connectedPeers, with: .reliable)
//        } catch {
//            print("Error sending: \(error.localizedDescription)")
//        }
//    }
}
