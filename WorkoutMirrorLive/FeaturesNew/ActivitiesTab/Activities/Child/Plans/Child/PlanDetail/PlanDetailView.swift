//
//  PlanDetailView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: PlanDetailFeature.self)
struct PlanDetailView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<PlanDetailFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            WorkoutDetailContent(
                session: store.trainingSession,
                isWarmupExpanded: Binding(
                    get: { store.isWarmupExpanded },
                    set: { _ in send(.warmupToggleTapped) }
                ),
                isCooldownExpanded: Binding(
                    get: { store.isCooldownExpanded },
                    set: { _ in send(.cooldownToggleTapped) }
                )
            )
            .padding()
        }
        .background(
            LinearGradient(
                colors: [store.color.opacity(0.25), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(store.trainingSession.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .navigationDestination(
            item: $store.scope(state: \.destination?.editor, action: \.destination.editor)
        ) { editorStore in
            TrainingSessionEditorView(store: editorStore)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Edit") { send(.editTapped) }
        }
    }
}
