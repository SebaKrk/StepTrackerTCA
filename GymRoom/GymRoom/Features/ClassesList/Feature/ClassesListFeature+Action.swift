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

        // MARK: - Destination + child reducer actions

        case destination(PresentationAction<Destination.Action>)
        case liveClass(PresentationAction<LiveClassFeature.Action>)

        // MARK: - View Actions

        case view(View)

        enum View {
            /// User tap `+` button w toolbar — open creation sheet.
            case addClassTapped

            /// User tap row na liście — push ClassDetailView.
            case classRowTapped(GymClass)

            /// User swipe-to-delete row — remove klasę z grafiku.
            case classDeleteTapped(GymClass)
        }
    }
}
