//
//  ClassesListFeature.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation

/// Root reducer Classes tab — schedule template list. Lista grafiku + add sheet +
/// detail push + LiveClass fullScreenCover.
///
/// **Template pattern**: klasy zostają w liście po End. Re-usable.
@Reducer
struct ClassesListFeature {

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

            case .view(.addClassTapped):
                state.destination = .create(ClassCreationFeature.State())
                return .none

            case let .view(.classRowTapped(gymClass)):
                state.destination = .detail(ClassDetailFeature.State(gymClass: gymClass))
                return .none

            case let .view(.classDeleteTapped(gymClass)):
                state.classes.remove(id: gymClass.id)
                return .none

            case let .destination(.presented(.create(.delegate(.classCreated(newClass))))):
                state.classes.append(newClass)
                state.destination = nil
                return .none

            case let .destination(.presented(.detail(.delegate(.startLiveClass(gymClass))))):
                // Pop detail + open fullScreenCover z context (name + location dla header).
                state.destination = nil
                state.liveClass = LiveClassFeature.State(
                    className: gymClass.name,
                    location: gymClass.location,
                    maxParticipants: gymClass.maxParticipants
                )
                return .none

            case .liveClass(.presented(.delegate(.classEnded))):
                // Live class skończona — close cover. Klasa **zostaje** w liście (template).
                state.liveClass = nil
                return .none

            case .destination, .liveClass, .view:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$liveClass, action: \.liveClass) {
            LiveClassFeature()
        }
    }

    @Reducer
    enum Destination {
        case detail(ClassDetailFeature)
        case create(ClassCreationFeature)
    }
}
