//
//  PeerMirrorPeerSession.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation
import MultipeerConnectivity
import SharedModels

/// Peer role w MultipeerConnectivity — używana przez iPhone (athlete dołączający do klasy).
///
/// **Responsibilities**:
/// - Browsuje sieć lokalną szukając hosta (`MCNearbyServiceBrowser`)
/// - Auto-invituje pierwszego znalezionego hosta
/// - Wysyła `HRSamplePayload` do hosta
/// - Forwarduje host lifecycle do callback
///
/// **Lifecycle**: stworzona w `PeerMirrorService.startBrowsing`, dropped w `stopBrowsing`.
public final class PeerMirrorPeerSession: NSObject, @unchecked Sendable {

    // MARK: - Immutable refs

    private let myPeerID: MCPeerID
    private let session: MCSession
    private let browser: MCNearbyServiceBrowser

    private let onPeerEvent: @Sendable (PeerEvent) -> Void

    // MARK: - Init

    public init(
        displayName: String,
        onPeerEvent: @escaping @Sendable (PeerEvent) -> Void
    ) {
        let peer = MCPeerID(displayName: displayName)
        self.myPeerID = peer
        // TODO IPAD-0088: encryptionPreference: .required + konfiguracja certyfikatu dla produkcji
        self.session = MCSession(
            peer: peer,
            securityIdentity: nil,
            encryptionPreference: .none
        )
        self.browser = MCNearbyServiceBrowser(
            peer: peer,
            serviceType: PeerMirrorService.serviceType
        )
        self.onPeerEvent = onPeerEvent
        super.init()
        self.session.delegate = self
        self.browser.delegate = self
        self.browser.startBrowsingForPeers()
    }

    // MARK: - Public

    public func stop() {
        browser.stopBrowsingForPeers()
        session.disconnect()
    }

    public func send(_ payload: HRSamplePayload) {
        guard !session.connectedPeers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(payload)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("[PeerMirror.Peer] send failed: \(error)")
        }
    }
}

// MARK: - MCSessionDelegate

extension PeerMirrorPeerSession: MCSessionDelegate {

    public func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        let name = peerID.displayName
        switch state {
        case .connected:
            onPeerEvent(.connected(peerID: name, nick: name))
        case .notConnected:
            onPeerEvent(.disconnected(peerID: name))
        case .connecting:
            break
        @unknown default:
            break
        }
    }

    public func session(_: MCSession, didReceive _: Data, fromPeer _: MCPeerID) {
        // No-op: iPhone w Proof of Concept nie odbiera danych, tylko wysyła.
    }

    public func session(_: MCSession, didReceive _: InputStream, withName _: String, fromPeer _: MCPeerID) {}
    public func session(_: MCSession, didStartReceivingResourceWithName _: String, fromPeer _: MCPeerID, with _: Progress) {}
    public func session(_: MCSession, didFinishReceivingResourceWithName _: String, fromPeer _: MCPeerID, at _: URL?, withError _: Error?) {}
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PeerMirrorPeerSession: MCNearbyServiceBrowserDelegate {

    public func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        // Auto-invite pierwszego znalezionego hosta w Proof of Concept.
        // session jest `let` (immutable) → bezpieczne wywołanie z delegate queue.
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // No-op — session.delegate (didChange) załatwi disconnect event.
    }

    public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("[PeerMirror.Peer] browser failed: \(error)")
    }
}
