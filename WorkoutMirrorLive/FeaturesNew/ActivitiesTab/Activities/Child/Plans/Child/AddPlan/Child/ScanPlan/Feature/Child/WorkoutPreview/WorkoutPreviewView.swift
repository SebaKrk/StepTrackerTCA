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

    /// The scanned plan as it will be saved, with its review findings.
    @Bindable var store: StoreOf<WorkoutPreviewFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if store.canGenerateNotes {
                    generateNotesCard
                        .transition(.opacity.combined(with: .move(edge: .top)))
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
                // Read after the whole plan: the doubts make sense once the user has seen the blocks.
                if hasOpenFindings {
                    findingsCard
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding()
            .animation(.snappy, value: hasOpenFindings)
        }
        .background(
            LinearGradient(
                colors: [store.color.opacity(0.25), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .animation(.snappy, value: store.canGenerateNotes)
        // The id changes only when an AI correction rebuilds the plan, so editor saves do not re-animate.
        .animation(.snappy, value: store.trainingSession.id)
        .navigationTitle(store.trainingSession.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert($store.scope(state: \.alert, action: \.alert))
        .navigationDestination(
            item: $store.scope(state: \.destination?.editor, action: \.destination.editor)
        ) { editorStore in
            TrainingSessionEditorView(store: editorStore)
        }
        .sheet(
            item: $store.scope(state: \.destination?.planChat, action: \.destination.planChat)
        ) { chatStore in
            PlanChatView(store: chatStore)
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
            .disabled(store.isGeneratingNotes)
        }

        if store.scannedBoard != nil {
            ToolbarItem(placement: .topBarTrailing) {
                correctWithAIToolbarButton
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            saveButton
        }
    }

    // MARK: - Generate Notes Card (structure)

    private var generateNotesCard: some View {
        GroupBox {
            HStack(spacing: 12) {
                generateNotesText
                Spacer(minLength: 0)
                generateNotesButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .styledGroupBox()
    }

    // MARK: - Implementation

    private var generateNotesText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(generateNotesTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(generateNotesHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var generateNotesButton: some View {
        Button {
            send(.generateNotesTapped)
        } label: {
            if store.isGeneratingNotes {
                ProgressView()
            } else {
                Text(generateTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.glass)
        .disabled(store.isGeneratingNotes)
    }

    private var findingsCard: some View {
        ScanFindingsCard(
            findings: store.findings,
            onConfirm: { send(.confirmFindingTapped($0)) },
            onCorrectWithAI: store.canCorrectWithAI ? { send(.correctWithAITapped) } : nil
        )
    }

    /// The card shows while something is left to check; once all is settled the plan stands on its own.
    private var hasOpenFindings: Bool {
        store.findings.contains(where: \.isOpen)
    }

    private var correctWithAIToolbarButton: some View {
        Button {
            send(.correctWithAITapped)
        } label: {
            Label(String(localized: "Correct with AI"), systemImage: "sparkles")
        }
        .disabled(!store.canCorrectWithAI)
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

    // MARK: - Text

    private var generateNotesTitle: String {
        switch (store.trainingSession.warmUp == nil, store.trainingSession.coolDown == nil) {
        case (true, true):
            return String(localized: "No warm-up or cool-down on the board")
        case (true, false):
            return String(localized: "No warm-up on the board")
        default:
            return String(localized: "No cool-down on the board")
        }
    }

    private let generateNotesHint = String(localized: "Generate them from the scanned blocks; you can edit the text afterwards.")
    private let generateTitle = String(localized: "Generate")
}
