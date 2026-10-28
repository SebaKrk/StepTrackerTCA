//
//  PublishPlanView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: PublishPlanFeature.self)
struct PublishPlanView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<PublishPlanFeature>

    // MARK: - Body (structure)

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        cancelButton
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        publishButton
                    }
                }
        }
        .interactiveDismissDisabled(store.isPublishing)
        .onAppear {
            send(.viewDidAppear)
        }
    }

    // MARK: - Content (structure)

    @ViewBuilder
    private var content: some View {
        switch store.viewState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .success:
            if store.plans.isEmpty {
                noPlansView
            } else {
                publishForm
            }
        case .failed:
            failedView
        }
    }

    private var publishForm: some View {
        Form {
            planSection
            scoredBlockSection
            classLengthSection
            errorSection
        }
    }

    private var planSection: some View {
        Section {
            planPicker
        } footer: {
            Text(planFooter)
        }
    }

    @ViewBuilder
    private var scoredBlockSection: some View {
        if let plan = store.selectedPlan {
            Section {
                scoredBlockPicker(plan)
            } footer: {
                Text(scoredBlockFooter)
            }
        }
    }

    private var classLengthSection: some View {
        Section {
            PlanBudgetBar(totalMinutes: store.plannedTotalMinutes, targetMinutes: PublishPlanFeature.State.classMinutes)
            if store.missingMinutes > 0 {
                fillClassLengthButton
            }
        } header: {
            Text(classLengthHeader)
        } footer: {
            Text(classLengthFooter)
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let message = store.errorMessage {
            Section {
                Text(message)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Implementation

    private var planPicker: some View {
        Picker(planTitle, selection: Binding(
            get: { store.selectedPlan?.id },
            set: { id in if let id { send(.planSelected(id)) } }
        )) {
            ForEach(store.plans) { plan in
                Text(plan.title)
                    .tag(Optional(plan.id))
            }
        }
        .pickerStyle(.navigationLink)
    }

    private func scoredBlockPicker(_ plan: TrainingSession) -> some View {
        Picker(scoredBlockTitle, selection: Binding(
            get: { store.scoredBlockId },
            set: { id in if let id { send(.scoredBlockSelected(id)) } }
        )) {
            ForEach(plan.workouts) { block in
                Text("\(block.name) · \(block.type.displayName)")
                    .tag(Optional(block.id))
            }
        }
        .pickerStyle(.menu)
    }

    private var fillClassLengthButton: some View {
        Button {
            send(.fillClassLengthTapped)
        } label: {
            Label(fillClassLengthTitle, systemImage: "wand.and.stars")
        }
    }

    private var cancelButton: some View {
        Button {
            send(.cancelTapped)
        } label: {
            Text(cancelTitle)
        }
        .disabled(store.isPublishing)
    }

    @ViewBuilder
    private var publishButton: some View {
        if store.isPublishing {
            ProgressView()
        } else {
            Button {
                send(.publishTapped)
            } label: {
                Text(publishTitle)
            }
            .disabled(!store.canPublish)
        }
    }

    private var noPlansView: some View {
        ContentUnavailableView {
            Label(noPlansTitle, systemImage: "doc.text")
        } description: {
            Text(noPlansMessage)
        }
    }

    private var failedView: some View {
        ContentUnavailableView {
            Label(failedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(failedMessage)
        }
    }

    // MARK: - Text

    private let navigationTitle = String(localized: "Today's Plan")
    private let planTitle = String(localized: "Plan")
    private let planFooter = String(localized: "The group sees the whole plan and can download it to their Plans.")
    private let scoredBlockTitle = String(localized: "Scored Block")
    private let scoredBlockFooter = String(localized: "The leaderboard ranks results of this block.")
    private let classLengthHeader = String(localized: "Class Length")
    private let classLengthFooter = String(localized: "A group plan lasts at least 60 minutes — everyone is measured over the same window.")
    private let fillClassLengthTitle = String(localized: "Fill to 60 Minutes")
    private let cancelTitle = String(localized: "Cancel")
    private let publishTitle = String(localized: "Publish")
    private let noPlansTitle = String(localized: "No Plans")
    private let noPlansMessage = String(localized: "Create or scan a plan in Activities → Plans first.")
    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to load your plans. Please try again.")
}
