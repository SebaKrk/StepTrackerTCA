//
//  HRFormulaSettingsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/06/2026.
//

import ComposableArchitecture
import HealthHub
import SharedModels
import SwiftUI

/// Settings UI dla wyboru formuły obliczania maxHR. Layout: List z `DisclosureGroup` per
/// formuła — selected auto-expanded, reszta collapsed. Preview maxHR per row.
///
/// **Gulati ukryta dla mężczyzn** — `store.availableFormulas` filtruje na podstawie
/// `biologicalSex`. Formula dedykowana dla kobiet (Fox/Tanaka overestimate ich maxHR).
@ViewAction(for: HRFormulaSettingsFeature.self)
struct HRFormulaSettingsView: View {

    @Bindable var store: StoreOf<HRFormulaSettingsFeature>

    var body: some View {
        List {
            Section {
                ForEach(store.availableFormulas, id: \.self) { formula in
                    formulaRow(formula)
                }
            } footer: {
                Text(footerHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            send(.onAppear)
        }
    }

    // MARK: - Row

    private func formulaRow(_ formula: HRFormulaType) -> some View {
        let isSelected = store.selectedFormula == formula
        return DisclosureGroup(
            isExpanded: .constant(isSelected)
        ) {
            VStack(alignment: .leading, spacing: 6) {
                Text(formula.formulaText)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
                Text(formula.description)
                    .font(.callout)
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 4)
        } label: {
            formulaRowLabel(formula, isSelected: isSelected)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            send(.formulaSelected(formula))
        }
    }

    private func formulaRowLabel(_ formula: HRFormulaType, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(formula.title)
                        .font(.body.weight(.semibold))
                    targetBadge(formula.targetAudience)
                }
            }
            Spacer()
            if let preview = store.previewValues[formula] {
                Text("\(preview) BPM")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func targetBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(.tint.opacity(0.15))
            )
            .foregroundStyle(.tint)
    }

    // MARK: - Localized strings

    private var navigationTitle: String {
        String(localized: "Max HR formula")
    }

    private var footerHint: String {
        String(localized: "Changing the formula won't affect saved workouts — each workout keeps the formula from the moment it was saved.")
    }
}
