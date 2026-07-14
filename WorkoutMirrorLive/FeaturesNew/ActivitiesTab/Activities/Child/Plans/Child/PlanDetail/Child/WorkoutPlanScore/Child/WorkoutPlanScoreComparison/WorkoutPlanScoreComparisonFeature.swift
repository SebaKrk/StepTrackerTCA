//
//  WorkoutPlanScoreComparisonFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 08/03/2026.
//

import ComposableArchitecture
import SharedModels

// TODO: IOS-00070-G — Porównanie wyników treningowych
//
// Cel: umożliwić userowi zestawienie 2+ wybranych wyników (WorkoutPlanScore)
// z listy historii i pokazać ich progres na wykresach.
//
// Planowane funkcjonalności:
//
// 1. WYKRESY (Swift Charts)
//    - LineChart: oś X = daty sesji, oś Y = wynik danego WOD-a
//    - Każdy zaznaczony wynik jako osobna seria (kolor per seria)
//    - Marker/annotation z dokładną wartością przy każdym punkcie
//
// 2. SELEKTOR WOD-ów
//    - Jeśli plan ma kilka WOD-ów (np. "Weightlifting" + "WOD 1"),
//      user może przełączać który WOD jest aktualnie na wykresie
//    - Picker lub segmented control w toolbarze/nagłówku
//
// 3. OBSŁUGA TYPÓW WYNIKÓW
//    - Czas (np. "11:43") → konwersja na sekundy do wykresu
//    - Ciężar (np. "80kg") → konwersja na Double
//    - Inne formaty → fallback lub pominięcie
//
// 4. SUMMARY STATS
//    - Best / Worst / Average per WOD
//    - Trend (poprawa/pogorszenie między pierwszym a ostatnim)

@Reducer
struct WorkoutPlanScoreComparisonFeature {

    // MARK: - State

    @ObservableState
    struct State {

        /// Scores selected by the user for comparison.
        var scores: [WorkoutPlanScore]
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        @CasePathable
        enum View {

            /// Triggered when the view appears.
            case viewDidAppear
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .view(.viewDidAppear):
                return .none
            }
        }
    }
}
