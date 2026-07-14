//
//  ClassResultsView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 09/07/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// End-of-class ranking presented as a fullScreenCover — stats banner over the
/// shared ranking table (`ClassResultsTableView`). "Done" hands control back to
/// `LiveClassFeature`, which only then emits `delegate(.classEnded)`.
@ViewAction(for: ClassResultsFeature.self)
struct ClassResultsView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ClassResultsFeature>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                topStatsBanner
                ClassResultsTableView(store: store)
            }
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { doneToolbarItem }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Structure

    /// Class-level aggregates over the table — same four cards and definitions
    /// as `ClassHistoryDetailView.topStatsBanner`, so the end-of-class screen
    /// and the history detail read identically.
    private var topStatsBanner: some View {
        HStack(spacing: 12) {
            statCard(label: athletesLabel, value: "\(store.rows.count)")
            statCard(label: durationLabel, value: classDurationValue)
            statCard(label: caloriesLabel, value: "\(store.totalCalories)")
            statCard(label: avgHRLabel, value: averageHRValue)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var doneToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.doneTapped)
            } label: {
                Text(doneButtonTitle)
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Implementation

    /// Style copied 1:1 from `ClassHistoryDetailView.statCard`.
    private func statCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private var navigationTitleText: String {
        String(localized: "Results — \(store.className)", bundle: .main)
    }

    private var doneButtonTitle: String {
        String(localized: "Done", bundle: .main)
    }

    private var athletesLabel: String {
        String(localized: "Athletes", bundle: .main)
    }

    private var durationLabel: String {
        String(localized: "Duration", bundle: .main)
    }

    private var caloriesLabel: String {
        String(localized: "Calories", bundle: .main)
    }

    private var avgHRLabel: String {
        String(localized: "Avg HR", bundle: .main)
    }

    private var classDurationValue: String {
        String(localized: "\(store.classDurationMinutes) min", bundle: .main)
    }

    private var averageHRValue: String {
        store.averageHR.map { "\($0)" } ?? "—"
    }
}

// MARK: - Preview

#Preview("ranking") {
    ClassResultsView(store: Store(
        initialState: ClassResultsFeature.State(
            className: "Morning CrossFit",
            rows: [
                .init(id: UUID(), nick: "Seba", points: 187, hasPoints: true, avgHR: 152, peakHR: 181, calories: 612, durationMinutes: 47),
                .init(id: UUID(), nick: "Magda", points: 203, hasPoints: true, avgHR: 158, peakHR: 189, calories: 655, durationMinutes: 47),
                .init(id: UUID(), nick: "Tomek", points: 141, hasPoints: true, avgHR: 139, peakHR: 172, calories: 498, durationMinutes: 42),
                .init(id: UUID(), nick: "Ola (stara apka)", points: 0, hasPoints: false, avgHR: 145, peakHR: 176, calories: 530, durationMinutes: 47)
            ]
        )
    ) {
        ClassResultsFeature()
    })
}
