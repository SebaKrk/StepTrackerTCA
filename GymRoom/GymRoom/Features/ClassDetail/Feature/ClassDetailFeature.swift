//
//  ClassDetailFeature.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation

/// Reducer dla widoku szczegółów klasy (push destination z ClassesList).
///
/// Pokazuje metadata (name, location, scheduledAt) + Start class button. Future
/// scope: Edit / Delete actions.
///
/// **Delegate pattern**: po tap "Start class" emit `.delegate(.startLiveClass(gymClass))`,
/// parent (ClassesListFeature) ustawia `state.liveClass = LiveClassFeature.State(...)`
/// i dismiss detail (fullScreenCover overrides nawigacja).
@Reducer
struct ClassDetailFeature {

    @ObservableState
    struct State: Equatable {
        let gymClass: GymClass
    }

    @CasePathable
    enum Action: ViewAction {
        case delegate(Delegate)
        case view(View)

        enum Delegate: Equatable {
            /// User chce rozpocząć tę klasę — parent set'uje fullScreenCover LiveClass.
            case startLiveClass(GymClass)
        }

        enum View {
            case startTapped
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.startTapped):
                return .send(.delegate(.startLiveClass(state.gymClass)))
            case .delegate:
                return .none
            }
        }
    }
}
