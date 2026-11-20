//
//  PlansView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: PlansFeature.self)
struct PlansView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<PlansFeature>

    // MARK: - Body (structure)

    var body: some View {
        Group {
            switch store.viewState {
            case .loading:
                ProgressView()
            case .success:
                plansListView
            case .failed:
                failedView
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                importPlanButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                addPlanButton
            }
        }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.addPlan, action: \.destination.addPlan)
        ) { addPlanStore in
            AddPlanView(store: addPlanStore)
        }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.planDetail, action: \.destination.planDetail)
        ) { planDetailStore in
            NavigationStack {
                PlanDetailView(store: planDetailStore)
            }
        }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.session, action: \.destination.session)
        ) { sessionStore in
            SessionView(store: sessionStore)
        }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.importPlan, action: \.destination.importPlan)
        ) { importStore in
            ImportPlanView(store: importStore)
        }
        .sheet(
            item: $store.scope(
                state: \.destination?.subscriptionOffer,
                action: \.destination.subscriptionOffer
            )
        ) { offerStore in
            SubscriptionOfferView(store: offerStore)
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }

    // MARK: - List (structure)

    @ViewBuilder
    private var plansListView: some View {
        if store.sessions.isEmpty {
            emptyPlansView
        } else {
            ScrollViewReader { proxy in
                List {
                    planRows(store.unlockedSessions, isLocked: false)
                    if !store.lockedSessions.isEmpty {
                        Section {
                            planRows(store.lockedSessions, isLocked: true)
                        } header: {
                            unlockOlderPlansBanner
                        }
                    }
                }
                .animation(.default, value: store.subscriptionTier)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                // The offset at rest is the negated top inset, so the sum is
                // zero exactly when the list sits at its top.
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top > 1
                } action: { _, isScrolled in
                    send(.scrolledChanged(isScrolled))
                }
                .onChange(of: store.scrollToTopToken) {
                    guard let first = store.unlockedSessions.first ?? store.lockedSessions.first else { return }
                    withAnimation { proxy.scrollTo(first.id, anchor: .top) }
                }
            }
        }
    }

    private func planRows(_ sessions: [TrainingSession], isLocked: Bool) -> some View {
        ForEach(sessions) { workout in
            PlanSummaryCard(session: workout, isLocked: isLocked) {
                send(.workoutTapped(workout))
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    /// Pinned by the list while the locked plans scroll under it.
    private var unlockOlderPlansBanner: some View {
        UnlockOlderItemsBanner(
            title: String(localized: "Older plans in Pro"),
            lockedCount: store.lockedSessions.count
        ) {
            send(.unlockOlderTapped)
        }
        .textCase(nil)
        .listRowInsets(EdgeInsets())
    }

    // MARK: - Implementation

    private var importPlanButton: some View {
        Button {
            send(.importPlanTapped)
        } label: {
            Image(systemName: "qrcode.viewfinder")
        }
    }

    private var addPlanButton: some View {
        Button {
            send(.addPlanTapped)
        } label: {
            Image(systemName: "plus")
        }
    }

    // MARK: - Empty / Failed

    private var failedView: some View {
        ContentUnavailableView {
            Label(failedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(failedMessage)
        }
    }

    private var emptyPlansView: some View {
        ContentUnavailableView {
            Label(emptyTitle, systemImage: "doc.text")
        } description: {
            Text(emptyMessage)
        } actions: {
            emptyAddButton
        }
    }

    private var emptyAddButton: some View {
        Button {
            send(.addPlanTapped)
        } label: {
            Label(addPlanTitle, systemImage: "plus")
        }
    }

    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to load workout plans. Please try again.")
    private let emptyTitle = String(localized: "No Workout Plans")
    private let emptyMessage = String(localized: "Create workout plans by scanning your training notes or add them manually. Compare your plans with actual HealthKit results.")
    private let addPlanTitle = String(localized: "Add Plan")
}
