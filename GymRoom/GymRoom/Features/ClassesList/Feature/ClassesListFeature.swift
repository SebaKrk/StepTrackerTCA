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
                // Swipe-to-delete NIE kasuje od razu — present alert z confirmation
                // (cascade delete kasuje też wszystkie past sessions + athlete records).
                state.classToDelete = gymClass
                state.alert = .deleteClass(gymClass.name)
                return .none

            case .alert(.presented(.confirmDelete)):
                // User potwierdził → optimistic remove ze state + cascade delete w bazie.
                guard let gymClass = state.classToDelete else { return .none }
                state.classes.remove(id: gymClass.id)
                state.classToDelete = nil
                return .run { _ in
                    try await gymClassClient.deleteTemplate(gymClass.id)
                } catch: { error, _ in
                    Logger.gymRoom.error("❌ cascade delete failed: \(error.localizedDescription)")
                }

            case .alert(.dismiss), .alert:
                // Cancel lub dismiss alert'u — wyczyść snapshot, nic nie kasuj.
                state.classToDelete = nil
                return .none

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

            case let .destination(.presented(.detail(.delegate(.classDeleted(id))))):
                // User skasował template z menu w ClassDetailView. Cascade delete już
                // wykonany w child (gymClassClient). Tu: optimistic remove ze state.classes
                // + pop detail. Następny `viewDidAppear` re-fetch potwierdzi zgodność z DB.
                state.classes.remove(id: id)
                state.destination = nil
                return .none

            case .liveClass(.presented(.delegate(.classEnded))):
                // Live class skończona — close cover. Klasa **zostaje** w liście (template).
                state.liveClass = nil
                return .none

            case .destination, .liveClass, .view:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
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
