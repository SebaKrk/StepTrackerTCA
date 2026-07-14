//
//  WODScoringView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/06/2026.
//
//  STUB — minimal kompilowalny widok. Integracja z SummaryView (kopia rendering'u
//  resultCard z linii 290-700) dzieje się w IOS-00096-C jako osobny krok. Tu tylko
//  fundament: bindable store, send dispatch, action wiring.

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: WODScoringFeature.self)
struct WODScoringView: View {

    @Bindable var store: StoreOf<WODScoringFeature>

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text(store.result.name)
                    .font(.subheadline.bold())
                if store.showResults {
                    expandedContent
                }
            }
        } label: {
            header
        }
        .styledGroupBox()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(store.result.name)
                .font(.subheadline.bold())
            Spacer()
            Toggle("", isOn: Binding(
                get: { store.showResults },
                set: { _ in send(.toggleResultsExpand) }
            ))
            .labelsHidden()
        }
    }

    // MARK: - Expanded content (stub — pełna struktura w SummaryView+WODCard po integracji)

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Button {
                send(.editExercisesTapped)
            } label: {
                Label(String(localized: "Edytuj ćwiczenia"), systemImage: "pencil")
            }
            if store.showNotes {
                TextField(String(localized: "Add note..."), text: $store.result.note, axis: .vertical)
                    .lineLimit(1...4)
            }
        }
    }
}
