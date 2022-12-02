 //
 //  MPCHandler.swift
 //  TicTacToe
 //
 //  Created by Михаил Колотилин on 25.03.2020.
 //  Copyright © 2020 Михаил Колотилин. All rights reserved.
 //
 
 import UIKit
 import MultipeerConnectivity
 
 class MPCHandler: NSObject {
    
    static var handler = MPCHandler()
    var peerID: MCPeerID!
    var session: MCSession!
    var browser: MCBrowserViewController!
    var advertiser: MCNearbyServiceAdvertiser?
    var delegate: MPCHandlerDelegate?
    
    override init() {
        super.init()
        setupPeerWithDisplayName(displayName: UIDevice.current.name)
        setupSession()
        advertiseSelf(advertise: true)
    }
    
    func setupPeerWithDisplayName(displayName: String) {
        peerID = MCPeerID(displayName: displayName)
    }
    
    func setupSession() {
        session = MCSession(peer: peerID)
        session.delegate = self
    }
    
    func setupBrowser() {
        browser = MCBrowserViewController(serviceType: "deepmuse", session: session)
    }
    
    func advertiseSelf(advertise: Bool) {
        guard advertise else {
            advertiser?.stopAdvertisingPeer()
            advertiser = nil
            return
        }
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "deepmuse")
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        //??? advertiser?.start()
    }
    
 }

extension MPCHandler: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browser.dismiss(animated: true, completion: nil)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browser.dismiss(animated: true, completion: nil)
    }
}
extension MPCHandler: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Invitation Received"

        let ac = UIAlertController(title: appName, message: "'\(peerID.displayName)' wants to connect.", preferredStyle: .alert)
        let declineAction = UIAlertAction(title: "Decline", style: .cancel) { [weak self] _ in invitationHandler(false, self?.session) }
        let acceptAction = UIAlertAction(title: "Accept", style: .default) { [weak self] _ in invitationHandler(true, self?.session) }

        ac.addAction(declineAction)
        ac.addAction(acceptAction)

        SkyVC.shared.present(ac, animated: true)
    }
}

 protocol MPCHandlerDelegate {
    func changed(state: MCSessionState, of peer: MCPeerID)
    func received(data: Data, from peer: MCPeerID)
 }
 
 
 // MARK: - MCSessionDelegate
 extension MPCHandler: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.delegate?.changed(state: state, of: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        
        return certificateHandler(true)
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.delegate?.received(data: data, from: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
 }
