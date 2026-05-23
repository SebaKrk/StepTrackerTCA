//
//  PeerMirrorHostSession.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation
import MultipeerConnectivity
import SharedModels

/// Host role w MultipeerConnectivity — używana przez iPad (Gym Room display).
///
/// **Responsibilities**:
/// - Publikuje usługę `_mfj-gym._tcp` w sieci lokalnej (`MCNearbyServiceAdvertiser`)
/// - Auto-accepts incoming invitations od iPhone'ów
/// - Odbiera `HRSamplePayload` od connected peerów
/// - Forwarduje peer lifecycle + samples do callbacks (które domykają streams w `PeerMirrorService`)
///
/// **Lifecycle**: stworzona w `PeerMirrorService.startAdvertising`, dropped w `stopAdvertising`.
/// Wszystkie referencje (`session`, `advertiser`) są `let` → Sendable-safe across delegate threads.
public final class PeerMirrorHostSession: NSObject, @unchecked Sendable {

    // MARK: - Immutable refs (Sendable across delegate queues)

    private let myPeerID: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser

    private let onPeerEvent: @Sendable (PeerEvent) -> Void
    private let onSample: @Sendable (HRSamplePayload) -> Void

    // MARK: - Init

    public init(
        displayName: String,
        onPeerEvent: @escaping @Sendable (PeerEvent) -> Void,
        onSample: @escaping @Sendable (HRSamplePayload) -> Void
    ) {
        let peer = MCPeerID(displayName: displayName)
        self.myPeerID = peer
        // TODO IPAD-0088: encryptionPreference: .required + konfiguracja certyfikatu dla produkcji
        self.session = MCSession(
            peer: peer,
            securityIdentity: nil,
            encryptionPreference: .none
        )
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peer,
            discoveryInfo: nil,
            serviceType: PeerMirrorService.serviceType
        )
        self.onPeerEvent = onPeerEvent
        self.onSample = onSample
        super.init()
        self.session.delegate = self
        self.advertiser.delegate = self
        self.advertiser.startAdvertisingPeer()
    }

    // MARK: - Public

    public func stop() {
        advertiser.stopAdvertisingPeer()
        session.disconnect()
    }
}

// MARK: - MCSessionDelegate

extension PeerMirrorHostSession: MCSessionDelegate {

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
            // Proof of Concept: ignorujemy intermediate state (IPAD-0089)
            break
        @unknown default:
            break
        }
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let payload = try? JSONDecoder().decode(HRSamplePayload.self, from: data) else {
            return
        }
        onSample(payload)
    }

    // Resource / stream transfery — wymagane przez protokół, w Proof of Concept no-op.

    public func session(_: MCSession, didReceive _: InputStream, withName _: String, fromPeer _: MCPeerID) {}
    public func session(_: MCSession, didStartReceivingResourceWithName _: String, fromPeer _: MCPeerID, with _: Progress) {}
    public func session(_: MCSession, didFinishReceivingResourceWithName _: String, fromPeer _: MCPeerID, at _: URL?, withError _: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension PeerMirrorHostSession: MCNearbyServiceAdvertiserDelegate {

    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        // Auto-accept w Proof of Concept. session jest `let` (immutable),
        // więc bezpieczne do sync wywołania z każdego threadu MultipeerConnectivity.
        invitationHandler(true, session)
    }

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("[PeerMirror.Host] advertiser failed: \(error)")
    }
}
