//
//  InviteFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import CoreGraphics
import Foundation
import SharedModels

extension InviteFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// Group the invite leads to.
        var group: TeamGroup

        /// Name shown to people who scan the code.
        var displayName: String

        /// Invite behind the code on screen; `nil` until it is loaded.
        var invite: TeamInvite?

        /// Rendered QR code of the invite.
        var qrImage: CGImage?

        /// People who scanned this invite, newest first, with the status to show.
        var scans: [InviteScanRow] = []

        /// Loading state of the code.
        var viewState: ViewState = .loading

        /// Revoking and replacing the code is in flight.
        var isReplacing = false
    }

}
