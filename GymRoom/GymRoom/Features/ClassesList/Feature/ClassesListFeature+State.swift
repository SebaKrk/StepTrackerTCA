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

        /// Schedule template entries — wszystkie klasy w grafiku. Persisted przez
        /// `gymClassClient` w SQLiteData. Fetch w `viewDidAppear`.
        var classes: IdentifiedArrayOf<GymClass> = []

        /// Confirm dialog przed cascade delete template'a (kasuje też past sessions +
        /// athlete records). `nil` = brak alertu, non-nil = alert visible. Wzorzec
        /// 1:1 z `LiveClassFeature.endClass` alert (TCA AlertState pattern).
        @Presents var alert: AlertState<Action.Alert>?

        /// Snapshot tap'niętego template'a do delete — niezbędny żeby alert
        /// `confirmDelete` wiedział który `id` skasować z bazy. Set'owany przy
        /// `classDeleteTapped`, cleared przy alert dismiss / confirm.
        var classToDelete: GymClass?

        /// Destination dla detail push lub creation sheet (TCA `@Presents` pattern).
        @Presents var destination: Destination.State?

        /// Active live class state — non-nil triggers fullScreenCover. Set gdy ClassDetail
        /// emit `.delegate(.startLiveClass(gymClass))`. Cleared gdy LiveClass emit
        /// `.delegate(.classEnded)` (cover dismiss, klasa **zostaje** w grafiku — template).
        @Presents var liveClass: LiveClassFeature.State?
    }
}
