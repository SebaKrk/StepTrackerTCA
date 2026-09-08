//
//  RoundSignalClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 06/09/2026.
//

import AVFoundation
import ComposableArchitecture

/// Audible boundary of a rounds-timer segment. Sound only — no haptics, the
/// phone lies across the gym during rounds, nobody holds it.
enum RoundSignal: Sendable {
    /// Work segment begins.
    case workStarted
    /// Rest segment begins.
    case restStarted
    /// 10 seconds of work left — single boxing bell.
    case tenSecondsLeft
    /// Last second of rest — single bell announcing the next round.
    case restEnding
    /// All rounds done — triple boxing bell.
    case finished
}

/// Plays round signals. Everything goes through the `.playback` audio session
/// so every signal cuts through the silent switch and a locked screen —
/// system sounds proved mute exactly when the phone lies silenced under the bag.
struct RoundSignalClient: Sendable {
    var play: @Sendable (RoundSignal) async -> Void
}

extension DependencyValues {
    var roundSignal: RoundSignalClient {
        get { self[RoundSignalClientKey.self] }
        set { self[RoundSignalClientKey.self] = newValue }
    }
}

// MARK: - Service

/// Owns the AVAudioPlayers (they must outlive `play()`) and the one-time
/// audio-session setup. Not a dependency itself — hidden behind the client.
@MainActor
private final class RoundSignalPlayer {

    static let shared = RoundSignalPlayer()

    private var players: [String: AVAudioPlayer] = [:]
    private var isSessionConfigured = false

    /// Bell audio: "Boxing Bell" by Benboncan (freesound.org), CC-BY.
    func play(resource: String) {
        configureSessionIfNeeded()
        if players[resource] == nil,
           let url = Bundle.main.url(forResource: resource, withExtension: "caf") {
            players[resource] = try? AVAudioPlayer(contentsOf: url)
            players[resource]?.prepareToPlay()
        }
        guard let player = players[resource] else { return }
        player.currentTime = 0
        player.play()
    }

    private func configureSessionIfNeeded() {
        guard !isSessionConfigured else { return }
        // .playback ignores the silent switch and keeps playing on a locked
        // screen; .mixWithOthers leaves the user's music untouched (duckOthers
        // would keep the music lowered for the whole active session).
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        isSessionConfigured = true
    }
}

// MARK: - DependencyKey

private enum RoundSignalClientKey: DependencyKey {

    static let liveValue = RoundSignalClient(
        play: { signal in
            await MainActor.run {
                switch signal {
                case .workStarted:
                    // Deliberately silent — the rest-ending bell a second
                    // earlier already announces the round.
                    break
                case .restStarted:
                    // End of a round = the real gym bell (original strike burst).
                    RoundSignalPlayer.shared.play(resource: "round_end_bell")
                case .tenSecondsLeft:
                    RoundSignalPlayer.shared.play(resource: "round_bell_single")
                case .restEnding:
                    RoundSignalPlayer.shared.play(resource: "round_bell_single")
                case .finished:
                    // Same gym bell as a round end — the tile's ✓ card tells the rest.
                    RoundSignalPlayer.shared.play(resource: "round_end_bell")
                }
            }
        }
    )

    static var testValue: RoundSignalClient {
        RoundSignalClient(play: { _ in })
    }

    static var previewValue: RoundSignalClient {
        RoundSignalClient(play: { _ in })
    }
}
