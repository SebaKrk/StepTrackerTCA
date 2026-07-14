//
//  HRFormulaSettingsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/06/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

/// Settings UI dla wyboru formuły obliczania maksymalnego tętna.
///
/// **Behavior**: tylko UI + state — persistence (`@Shared(.appStorage)`) + snapshot table
/// dodawane w osobnym ticket'cie (IOS-00097-E). Tu testujemy UX picker'a.
///
/// **Filtrowanie**: `HRFormulaType.availableCases(for: biologicalSex)` ukrywa Gulati
/// dla mężczyzn — Gulati jest formula dedykowana dla kobiet.
@Reducer
struct HRFormulaSettingsFeature {

    // MARK: - Dependency

    @Dependency(\.personalDataManager) var personalDataManager
    @Dependency(\.heartRateCalculator) var heartRateCalculator
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now

    // MARK: - State

    @ObservableState
    struct State: Equatable {

        /// Aktualnie wybrana formuła — persisted w UserDefaults przez `@Shared(.appStorage)`.
        /// Default: Tanaka (modern statistical standard). Zmiana propaguje się natychmiast
        /// do wszystkich `MaxHeartRateClient` consumerów (Settings + workout flow).
        @Shared(.appStorage("hrFormula")) var selectedFormula: HRFormulaType = .tanaka

        /// User'owy wiek z HealthKit — używany do preview maxHR per formuła.
        var age: Int?

        /// Płeć biologiczna z HealthKit — filtruje dostępne formuły (Gulati dla kobiet only).
        var biologicalSex: BiologicalSex = .unknown

        /// Preview maxHR per formuła dla bieżącego user'a. `[HRFormulaType: Int]` —
        /// liczone after load age+sex w `.onAppear`.
        var previewValues: [HRFormulaType: Int] = [:]

        /// Formuły dostępne dla bieżącej płci (filtruje Gulati gdy male).
        var availableFormulas: [HRFormulaType] {
            HRFormulaType.availableCases(for: biologicalSex)
        }
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        /// User'owy age + sex załadowane z HealthKit (oraz preview values policzone).
        case personalDataLoaded(age: Int, sex: BiologicalSex, previews: [HRFormulaType: Int])

        @CasePathable
        enum View {
            case onAppear
            case formulaSelected(HRFormulaType)
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.onAppear):
                return .run { [heartRateCalculator, personalDataManager, calendar, now] send in
                    let birthDate = (try? await personalDataManager.getBirthDate()) ?? now
                    let sex = (try? await personalDataManager.getBiologicalSex()) ?? .unknown
                    let years = calendar.dateComponents([.year], from: birthDate, to: now).year ?? 30
                    let age = max(years, 0)
                    let previews = Dictionary(
                        uniqueKeysWithValues: HRFormulaType.allCases.map { formula in
                            (formula, heartRateCalculator.calculateMaxHeartRate(
                                age: age,
                                biologicalSex: sex,
                                formula: formula
                            ))
                        }
                    )
                    await send(.personalDataLoaded(age: age, sex: sex, previews: previews))
                }

            case let .personalDataLoaded(age, sex, previews):
                state.age = age
                state.biologicalSex = sex
                state.previewValues = previews
                return .none

            case let .view(.formulaSelected(formula)):
                state.selectedFormula = formula
                return .none
            }
        }
    }
}
