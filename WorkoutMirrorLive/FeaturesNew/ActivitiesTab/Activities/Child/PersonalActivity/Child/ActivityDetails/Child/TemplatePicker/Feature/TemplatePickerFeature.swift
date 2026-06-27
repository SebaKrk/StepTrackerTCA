//
//  TemplatePickerFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 26/06/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Picker do wyboru `TrainingSession` (template'a) — używany z `ActivityDetailsFeature`
/// w manual-entry flow (escape hatch po nieudanym `.saving → .summary` po treningu).
///
/// Flow:
/// 1. User tap'uje kartę template'a → `previewTemplate` ustawiony → sheet z `WorkoutDetailContent`
///    (reusable component pokazujący warmup + WOD'y + cooldown, **bez** Edit / Start workout).
/// 2. W sheet'cie toolbar "Wybierz" — tap potwierdza wybór.
/// 3. Emit `delegate(.didSelectTemplate(template))` → parent buduje `SummaryFeature.State`.
@Reducer
struct TemplatePickerFeature {

    // MARK: - Dependency

    @Dependency(\.trainingSessionClient) var trainingSessionClient
    @Dependency(\.dismiss) var dismiss

    // MARK: - State

    @ObservableState
    struct State {

        /// Loading/success/failed dla fetch'a templates'ów.
        var viewState: ViewState = .loading

        /// Wszystkie template'y dostępne do wyboru (sort'owane przez `TrainingSessionClient.fetchAll`
        /// po dacie desc).
        var templates: [TrainingSession] = []

        /// Template aktualnie pokazany w preview sheet'cie. `nil` = sheet zamknięty.
        /// `TrainingSession: Identifiable` pozwala użyć `sheet(item:)` w View.
        var previewTemplate: TrainingSession?
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        /// View-originated actions — dispatch przez `send(...)` w `@ViewAction` view.
        case view(View)

        /// Wiadomości do parent feature'a (chwytane przez parent reducer przez `.delegate(.X)`).
        case delegate(Delegate)

        /// Fetch zakończony sukcesem — internal, z effect'a.
        case templatesLoaded([TrainingSession])

        /// Fetch failed — internal, z effect'a (przejście do `.failed` state).
        case fetchFailed

        @CasePathable
        enum View {

            /// View pojawił się — triggeruje fetch templates'ów.
            case viewDidAppear

            /// User tap'nął kartę template'a → opens preview sheet (`WorkoutDetailContent`).
            case templateTapped(TrainingSession)

            /// User potwierdził wybór z toolbar'a preview sheet'a → emit delegate + dismiss self.
            case selectFromPreviewTapped(TrainingSession)

            /// User zamknął preview sheet (close / swipe-down) — reset previewTemplate.
            case previewDismissed

            /// User zamknął picker bez wyboru — dismiss self.
            case closeButtonTapped
        }

        @CasePathable
        enum Delegate: Equatable {
            /// User wybrał template — parent buduje SummaryFeature.State z tym template'em.
            case didSelectTemplate(TrainingSession)
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - View

            case .view(.viewDidAppear):
                state.viewState = .loading
                return .run { send in
                    let templates = try await trainingSessionClient.fetchAll()
                    await send(.templatesLoaded(templates))
                } catch: { _, send in
                    await send(.fetchFailed)
                }

            case let .view(.templateTapped(template)):
                state.previewTemplate = template
                return .none

            case let .view(.selectFromPreviewTapped(template)):
                state.previewTemplate = nil
                return .run { send in
                    await send(.delegate(.didSelectTemplate(template)))
                    await dismiss()
                }

            case .view(.previewDismissed):
                state.previewTemplate = nil
                return .none

            case .view(.closeButtonTapped):
                return .run { _ in
                    await dismiss()
                }

            // MARK: - Internal

            case let .templatesLoaded(templates):
                state.templates = templates
                state.viewState = .success
                return .none

            case .fetchFailed:
                state.viewState = .failed
                return .none

            // MARK: - Delegate

            case .delegate:
                return .none
            }
        }
    }
}
