//
//  ClassesListFeature.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

/// Root reducer Classes tab — schedule template list. Lista grafiku + add sheet +
/// detail push + LiveClass fullScreenCover.
///
/// **Template pattern**: klasy zostają w liście po End. Re-usable.
/// **Persistence**: templates persistowane przez `gymClassClient` (SQLiteData).
/// Fetch przy `viewDidAppear`, save na create, delete na swipe.
@Reducer
struct ClassesListFeature {

    @Dependency(\.gymClassClient) var gymClassClient

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

            case .view(.viewDidAppear):
                return .run { send in
                    let classes = try await gymClassClient.fetchAllTemplates()
                    await send(.classesLoaded(classes))
                } catch: { error, _ in
                    // Silent log — empty list zostaje (state.classes = []), user widzi empty state.
                    // Real-world MVP: brak rollback / retry — defer do future ticket.
                    Logger.gymRoom.error("❌ fetchAllTemplates failed: \(error.localizedDescription)")
                }

            case let .classesLoaded(classes):
                state.classes = IdentifiedArrayOf(uniqueElements: classes)
                return .none

            case .view(.addClassTapped):
                state.destination = .create(ClassCreationFeature.State())
                return .none

            case let .view(.classRowTapped(gymClass)):
                state.destination = .detail(ClassDetailFeature.State(gymClass: gymClass))
                return .none

            case let .view(.classDeleteTapped(gymClass)):
                // Optimistic remove ze state + async delete w bazie.
                state.classes.remove(id: gymClass.id)
                return .run { _ in
                    try await gymClassClient.deleteTemplate(gymClass.id)
                }

            case let .destination(.presented(.create(.delegate(.classCreated(newClass))))):
                // Optimistic append + async save. Sheet zamykany przez parent (TCA dismiss).
                state.classes.append(newClass)
                state.destination = nil
                return .run { _ in
                    try await gymClassClient.saveTemplate(newClass)
                }

            case let .destination(.presented(.detail(.delegate(.startLiveClass(gymClass))))):
                // Pop detail + open fullScreenCover z context (name + location dla header).
                state.destination = nil
                state.liveClass = LiveClassFeature.State(
                    gymClassId: gymClass.id,
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
