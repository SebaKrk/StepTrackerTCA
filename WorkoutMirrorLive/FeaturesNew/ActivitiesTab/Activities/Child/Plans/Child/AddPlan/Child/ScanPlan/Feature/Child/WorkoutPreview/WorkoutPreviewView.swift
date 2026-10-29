//
//  WorkoutPreviewView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: WorkoutPreviewFeature.self)
struct WorkoutPreviewView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WorkoutPreviewFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !store.findings.isEmpty {
                    findingsCard
                }
                WorkoutDetailContent(
                    session: store.trainingSession,
                    isWarmupExpanded: Binding(
                        get: { store.isWarmupExpanded },
                        set: { _ in send(.warmupToggleTapped) }
                    ),
                    isCooldownExpanded: Binding(
                        get: { store.isCooldownExpanded },
                        set: { _ in send(.cooldownToggleTapped) }
                    ),
                    blockFlagCounts: store.openFindingCountsByBlock,
                    flaggedExerciseIds: store.flaggedExerciseIds
                )
            }
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
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.editButtonTapped)
            } label: {
                Text("Edit")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            saveButton
        }
    }

    // MARK: - Implementation

    private var findingsCard: some View {
        ScanFindingsCard(findings: store.findings) { id in
            send(.confirmFindingTapped(id))
        }
    }

    // Disabled until every finding is closed, so a doubtful plan never reaches the database.
    private var saveButton: some View {
        Button {
            send(.saveButtonTapped)
        } label: {
            Text("Save")
                .fontWeight(.semibold)
        }
        .disabled(!store.canSave)
    }
}
