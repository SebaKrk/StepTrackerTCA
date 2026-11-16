//
//  DeveloperSettingsFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import ComposableArchitecture
import Foundation

/// Implementation of `DeveloperSettingsFeature` state
extension DeveloperSettingsFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// Whether the next diagnostics bundle carries a copy of the database.
        ///
        /// Off by default — the report alone describes the install without
        /// exposing anyone's training history.
        var includesDatabaseInDiagnostics = false

        /// Whether a diagnostics bundle is being built right now.
        var isBuildingDiagnostics = false

        /// Archive waiting in the pre-addressed mail composer, or `nil`.
        var diagnosticsMailURL: URL?

        /// Archive waiting in the share sheet, used when the device has no mail
        /// account — the composer would refuse to open at all.
        var diagnosticsShareURL: URL?

        // MARK: - Destination

        /// destination from DeveloperSettingsFeature
        @Presents var destination: Destination.State?
    }
}
