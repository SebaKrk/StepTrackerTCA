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
/// Pokazuje metadata (name, location, scheduledAt, capacity) + Start class button +
/// pencil toolbar (Edit). Edit prezentuje sheet z `ClassCreationFeature` w edit mode
/// (prefilled values), Save → upsert do gymClassRecords + propagate updated do State.
///
/// **Delegate pattern**: po tap "Start class" emit `.delegate(.startLiveClass(gymClass))`,
/// parent (ClassesListFeature) ustawia `state.liveClass = LiveClassFeature.State(...)`
/// i dismiss detail (fullScreenCover overrides nawigacja).
@Reducer
struct ClassDetailFeature {

    @ObservableState
    struct State: Equatable {
        /// Aktualnie wyświetlany template — `var` żeby Edit mógł go nadpisać po Save.
        var gymClass: GymClass

        /// Snapshot "teraz" (`@Dependency(\.date)`, set w `viewDidAppear`) — baseline
        /// do liczenia następnego terminu zajęć cyklicznych (`WeeklyRecurrence`).
        /// Fallback `.now` tylko dla preview/init; reducer nadpisuje kontrolowaną wartością.
        var now: Date = .now

        /// Sheet edit'ujący istniejący template. Otwiera się z ellipsis menu → "Edytuj".
        @Presents var editSheet: ClassCreationFeature.State?

        /// Confirm alert przed cascade delete z ellipsis menu → "Usuń".
        @Presents var alert: AlertState<Action.Alert>?
    }

    @CasePathable
    enum Action: ViewAction {
        case delegate(Delegate)
        case editSheet(PresentationAction<ClassCreationFeature.Action>)
        case alert(PresentationAction<Alert>)
        case view(View)

        enum Delegate: Equatable {
            /// User chce rozpocząć tę klasę — parent set'uje fullScreenCover LiveClass.
            case startLiveClass(GymClass)

            /// User skasował template z menu → parent ClassesList re-fetch list +
            /// pop detail z navigationStack. Parent jest source of truth dla `state.classes`.
            case classDeleted(UUID)
        }

        enum Alert: Equatable {
            /// Trener potwierdził cascade delete template'a + powiązanych danych.
            case confirmDelete
        }

        enum View {
            /// Pierwsze pojawienie się — snapshot `now` dla obliczenia następnego
            /// terminu zajęć cyklicznych.
            case viewDidAppear

            case startTapped

            /// Ellipsis menu → "Edytuj" — otwórz sheet z prefilled values.
            case editTapped

            /// Ellipsis menu → "Usuń" — present alert confirm.
            case deleteTapped
        }
    }

    @Dependency(\.gymClassClient) var gymClassClient
    @Dependency(\.date) var date

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

            case .view(.viewDidAppear):
                state.now = date.now
                return .none

            case .view(.startTapped):
                return .send(.delegate(.startLiveClass(state.gymClass)))

            case .view(.editTapped):
                state.editSheet = ClassCreationFeature.State(editing: state.gymClass)
                return .none

            case .view(.deleteTapped):
                state.alert = .deleteClass(state.gymClass.name)
                return .none

            case .alert(.presented(.confirmDelete)):
                // User potwierdził cascade delete → run async + emit delegate.
                // Parent (ClassesList) reaguje na `.classDeleted` → re-fetch + pop detail.
                let id = state.gymClass.id
                return .run { send in
                    try? await gymClassClient.deleteTemplate(id)
                    await send(.delegate(.classDeleted(id)))
                }

            case let .editSheet(.presented(.delegate(.classCreated(updated)))):
                // Save z sheet → update local snapshot + persist do bazy + dismiss.
                state.gymClass = updated
                state.editSheet = nil
                return .run { _ in
                    try? await gymClassClient.saveTemplate(updated)
                }

            case .editSheet, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$editSheet, action: \.editSheet) {
            ClassCreationFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
