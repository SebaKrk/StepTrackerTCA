//
//  ClassesListFeature+Action.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation

extension ClassesListFeature {

    @CasePathable
    enum Action: ViewAction {


        // MARK: - Internal (async db results)

        /// Result `gymClassClient.fetchAllTemplates()` — populates `state.classes`.
        /// Wywoływane po `.view(.viewDidAppear)` lub re-fetch po create/delete.
        case classesLoaded([GymClass])

        // MARK: - View Actions

        case view(View)

        enum View {
            /// Lifecycle — fetch templates z bazy przy pierwszym pojawieniu.
            case viewDidAppear

            /// User tap `+` button w toolbar — open creation sheet.
            case addClassTapped

            /// User tap row na liście — push ClassDetailView.
            case classRowTapped(GymClass)

            /// User swipe-to-delete row — remove klasę z grafiku.
            case classDeleteTapped(GymClass)
        }
        
        // MARK: - Destination + child reducer actions

        case destination(PresentationAction<Destination.Action>)

        case liveClass(PresentationAction<LiveClassFeature.Action>)

        // MARK: - Alert (delete confirmation)

        /// Akcje z alert'u — confirm cascade delete lub cancel (PresentationAction wraps obie).
        case alert(PresentationAction<Alert>)

        /// Wybory użytkownika w alert'cie cascade delete.
        enum Alert: Equatable {
            /// Trener potwierdził chęć usunięcia template'a + powiązanych danych.
            case confirmDelete
        }
    }
}
