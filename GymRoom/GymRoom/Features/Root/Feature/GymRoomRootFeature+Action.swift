//
//  GymRoomRootFeature+Action.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation

extension GymRoomRootFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Child reducer actions

        case classesList(ClassesListFeature.Action)

        // MARK: - View Actions

        case view(View)

        enum View {
            /// User tap'nął nowy item w sidebar — switch detail content.
            case sidebarItemSelected(GymRoomRootFeature.SidebarItem)
        }
    }
}
