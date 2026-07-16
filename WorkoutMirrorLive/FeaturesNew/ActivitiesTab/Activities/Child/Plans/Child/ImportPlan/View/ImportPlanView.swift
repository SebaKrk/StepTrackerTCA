//
//  ImportPlanView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: ImportPlanFeature.self)
struct ImportPlanView: View {

    @Bindable var store: StoreOf<ImportPlanFeature>

    // MARK: - Body (structure)

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        cancelButton
                    }
                }
                .alert($store.scope(state: \.alert, action: \.alert))
        }
    }

    @ViewBuilder
    private var content: some View {
        if let plan = store.scannedPlan {
            preview(for: plan)
        } else {
            scanner
        }
    }

    private var scanner: some View {
        QRScannerView { scanned in
            send(.qrScanned(scanned))
        }
        .id(store.scanAttempt)
        .ignoresSafeArea()
    }

    private func preview(for plan: TrainingSession) -> some View {
        planDetail(for: plan)
            .safeAreaBar(edge: .bottom) {
                addButton
            }
            .background(backgroundGradient)
    }

    private func planDetail(for plan: TrainingSession) -> some View {
        ScrollView {
            // Reuse the same component PlanDetailView uses — one visual language.
            WorkoutDetailContent(
                session: plan,
                isWarmupExpanded: .constant(true),
                isCooldownExpanded: .constant(true)
            )
            .padding()
        }
    }

    private var addButton: some View {
        Button {
            send(.addTapped)
        } label: {
            Text(addTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .tint(.blue)
        .controlSize(.extraLarge)
        .buttonBorderShape(.capsule)
        .padding()
    }

    private var cancelButton: some View {
        Button {
            send(.cancelTapped)
        } label: {
            Text(cancelTitle)
        }
    }

    // MARK: - Implementation

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [store.color.opacity(0.25), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private let navigationTitle = String(localized: "Importuj plan")
    private let addTitle = String(localized: "Dodaj do moich planów")
    private let cancelTitle = String(localized: "Anuluj")
}
