//
//  ClassesListFeature+State.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation

extension ClassesListFeature {

    @ObservableState
    struct State {

        /// Schedule template entries — wszystkie klasy w grafiku. In-memory (subtask A).
        /// Persistence w subtask B (SQLiteData).
        var classes: IdentifiedArrayOf<GymClass> = []

        /// Destination dla detail push lub creation sheet (TCA `@Presents` pattern).
        @Presents var destination: Destination.State?

        /// Active live class state — non-nil triggers fullScreenCover. Set gdy ClassDetail
        /// emit `.delegate(.startLiveClass(gymClass))`. Cleared gdy LiveClass emit
        /// `.delegate(.classEnded)` (cover dismiss, klasa **zostaje** w grafiku — template).
        @Presents var liveClass: LiveClassFeature.State?
    }
}
