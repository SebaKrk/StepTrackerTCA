//
//  PrivacySettingsFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 21/11/2026.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == PrivacySettingsFeature.Action.Alert {

    /// Before the AI consent is taken back — says scanning still works, it only asks again.
    static let confirmTurnOffAIProcessing = Self {
        TextState("Turn off AI features?")
    } actions: {
        ButtonState(action: .aiProcessingTurnOffConfirmed) {
            TextState("Turn off")
        }
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
    } message: {
        TextState("Scanning a board and generating a warm-up will ask for your permission the next time you use them. Nothing is sent until then.")
    }

    /// Last stop before the cloud data is erased — says what goes, what stays, and that it cannot come back.
    static let confirmDeleteCloudData = Self {
        TextState("Delete your cloud data?")
    } actions: {
        ButtonState(role: .destructive, action: .deleteCloudDataConfirmed) {
            TextState("Delete")
        }
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
    } message: {
        TextState("Your results, group memberships and account are erased from our server. Workouts in the Health app and plans on this iPhone stay. This cannot be undone.")
    }

    /// Shown once the server confirmed the erase.
    static let cloudDataDeleted = Self {
        TextState("Cloud data deleted")
    } message: {
        TextState("Nothing of yours is left on our server. A new, empty account is created when the app next needs one.")
    }

    /// The erase failed; nothing is assumed gone, and asking again finishes what was started.
    static func cloudDataDeletionFailed(_ message: String) -> Self {
        Self {
            TextState("Couldn't delete your cloud data")
        } message: {
            TextState(message)
        }
    }
}
