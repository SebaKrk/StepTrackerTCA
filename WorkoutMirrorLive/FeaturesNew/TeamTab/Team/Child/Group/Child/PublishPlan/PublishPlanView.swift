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
                .background(backgroundGradient)
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        cancelButton
                    }
                }
                .navigationDestination(isPresented: planDetailBinding) {
                    planDetail
                }
        }
        .tint(store.color)
        .interactiveDismissDisabled(store.isPublishing)
        .onAppear {
            send(.viewDidAppear)
        }
    }

    // MARK: - Plan List (structure)

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
                planList
            }
        case .failed:
            failedView
        }
    }

    private var planList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                planListHint
                ForEach(store.plans) { plan in
                    PlanSummaryCard(session: plan) {
                        send(.planSelected(plan.id))
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Plan Detail (structure)

    @ViewBuilder
    private var planDetail: some View {
        if let plan = store.selectedPlan {
            ScrollView {
                VStack(spacing: 12) {
                    classLengthCard
                    scoredBlockCard(plan)
                    planContent(plan)
                }
                .padding()
            }
            .safeAreaBar(edge: .bottom) {
                publishBar
            }
            .background(backgroundGradient)
            .navigationTitle(plan.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var classLengthCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                PlanBudgetBar(totalMinutes: store.plannedTotalMinutes, targetMinutes: PublishPlanFeature.State.classMinutes)
                if store.missingMinutes > 0 {
                    fillClassLengthButton
                }
                cardFooter(classLengthFooter)
            }
        } label: {
            cardLabel(classLengthHeader)
        }
        .styledGroupBox()
    }

    private func scoredBlockCard(_ plan: TrainingSession) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                scoredBlockPicker(plan)
                cardFooter(scoredBlockFooter)
            }
        } label: {
            cardLabel(scoredBlockTitle)
        }
        .styledGroupBox()
    }

    // Same component as PlanDetail and the group preview — one way to read a plan.
    private func planContent(_ plan: TrainingSession) -> some View {
        WorkoutDetailContent(
            session: plan,
            isWarmupExpanded: $store.isWarmupExpanded,
            isCooldownExpanded: $store.isCooldownExpanded
        )
    }

    private var publishBar: some View {
        VStack(spacing: 8) {
            if let message = store.errorMessage {
                errorText(message)
            }
            publishButton
            cardFooter(planFooter)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Implementation

    private var planDetailBinding: Binding<Bool> {
        Binding(
            get: { store.selectedPlan != nil },
            set: { isPresented in
                if !isPresented { send(.planDetailClosed) }
            }
        )
    }

    private var planListHint: some View {
        Text(planListHintText)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cardLabel(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
            Divider()
        }
    }

    private func cardFooter(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
    }

    private var fillClassLengthButton: some View {
        Button {
            send(.fillClassLengthTapped)
        } label: {
            Label(fillClassLengthTitle, systemImage: "wand.and.stars")
        }
        .buttonStyle(.bordered)
    }

    private var publishButton: some View {
        Button {
            send(.publishTapped)
        } label: {
            Group {
                if store.isPublishing {
                    ProgressView()
                } else {
                    Label(publishTitle, systemImage: "paperplane.fill")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!store.canPublish)
    }

    private var cancelButton: some View {
        Button {
            send(.cancelTapped)
        } label: {
            Text(cancelTitle)
        }
        .disabled(store.isPublishing)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [store.color.opacity(0.25), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
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
    private let planListHintText = String(localized: "Pick a plan to see it in full before publishing.")
    private let planFooter = String(localized: "The group sees the whole plan and can download it to their Plans.")
    private let scoredBlockTitle = String(localized: "Scored Block")
    private let scoredBlockFooter = String(localized: "The leaderboard ranks results of this block.")
    private let classLengthHeader = String(localized: "Class Length")
    private let classLengthFooter = String(localized: "A group plan lasts at least 60 minutes — everyone is measured over the same window.")
    private let fillClassLengthTitle = String(localized: "Fill to 60 Minutes")
    private let cancelTitle = String(localized: "Cancel")
    private let publishTitle = String(localized: "Publish to Group")
    private let noPlansTitle = String(localized: "No Plans")
    private let noPlansMessage = String(localized: "Create or scan a plan in Activities → Plans first.")
    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to load your plans. Please try again.")
}
