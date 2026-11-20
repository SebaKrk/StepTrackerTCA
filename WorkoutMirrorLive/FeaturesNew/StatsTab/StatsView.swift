//
//  StatsView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import OSLog
import SwiftUI
import SharedModels

@ViewAction(for: StatsFeature.self)
struct StatsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<StatsFeature>
    
    @Namespace var zoomTransition
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            switch store.viewState {
            case .success:
                statsView
            case .failed:
                failedView
            case .loading:
                progressView
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
        .onDisappear {
            send(.viewDidDisappear)
        }
    }
    
    var statsView: some View {
        rootView
            .refreshable {
                Logger.stats.info("[PullToRefresh] closure START")
                // Wait for the blocking effect (cancelled by all children signalling
                // .delegate(.refreshDidComplete) — see StatsFeature.pullToRefresh handler).
                await send(.pullToRefresh).finish()
                Logger.stats.info("[PullToRefresh] closure END (all children completed)")
            }
            .toolbar {
                toolbarButton
            }
            .task {
                send(.checkDataAnalyzerAvailability)
            }
            .padding([.leading, .trailing], 8)
            .background(LinearGradient(colors: [store.color.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            .fullScreenCover(item: $store.scope(state: \.destination?.personSettings,
                                                action: \.destination.personSettings)) { store in
                PersonSettingsView(store: store)
                    .navigationTransition(.zoom(sourceID: "personSettings", in: zoomTransition))
            }
                                                .sheet(item: $store.scope(state: \.destination?.readinessAnalysis,
                                                                          action: \.destination.readinessAnalysis)) { store in
                                                    ReadinessAnalysisView(store: store)
                                                        .presentationDetents([.medium, .large])
                                                }
            .fullScreenCover(item: $store.scope(state: \.destination?.prBoard,
                                                action: \.destination.prBoard)) { store in
                PRBoardView(store: store)
                    .navigationTransition(.zoom(sourceID: "prBoard", in: zoomTransition))
            }
            .sheet(item: $store.scope(state: \.destination?.subscriptionOffer,
                                      action: \.destination.subscriptionOffer)) { store in
                SubscriptionOfferView(store: store)
            }
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        // Exercises segment swaps the global buttons for the PR Board entry (FR-010).
        if store.context == .exercises {
            ToolbarItem(placement: .topBarTrailing) {
                prBoardButton
            }
            .matchedTransitionSource(id: "prBoard", in: zoomTransition)
        } else {
#if DEBUG
            // A developer's switch: a shipped build must not let anyone pick their own tier.
            ToolbarItem(placement: .topBarLeading) {
                subscriptionTierMenu
            }
            let showDataAnalyzerButton = true
#else
            let showDataAnalyzerButton = store.isDataAnalyzerAvailable && store.subscriptionTier.opens(.dataAnalyzer)
#endif
            if showDataAnalyzerButton {
                ToolbarItem(placement: .topBarTrailing) {
                    dataAnalyzerButton
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                personButton
            }
            .matchedTransitionSource(id: "personSettings", in: zoomTransition)
        }
    }
    
    private var subscriptionTierMenu: some View {
        Menu {
            ForEach(SubscriptionTier.allCases.filter { $0 != store.subscriptionTier }) { tier in
                Button(tier.name) {
                    send(.subscriptionTierButtonTapped(tier))
                }
            }
            trialEndedPreviewButton(.appManaged, title: "Basic after 14 days — no card")
            trialEndedPreviewButton(.storeIntroOffer, title: "Basic after 14 days — with card")
            Divider()
            Text(store.subscriptionTier.name)
        } label: {
            Image(systemName: "crown")
        }
    }
    
    private func trialEndedPreviewButton(_ strategy: TrialStrategy, title: String) -> some View {
        Button {
            send(.trialEndedPreviewButtonTapped(strategy))
        } label: {
            Text(verbatim: title)
        }
    }

    private var dataAnalyzerButton: some View {
        Button {
            send(.dataAnalyzerButtonTapped)
        } label: {
            Image(systemName: "apple.intelligence")
        }
    }
    
    private var personButton: some View {
        Button {
            send(.personButtonTapped)
        } label: {
            Image(systemName: "person")
        }
    }

    private var prBoardButton: some View {
        Button {
            send(.prBoardButtonTapped)
        } label: {
            Image(systemName: "trophy")
        }
    }
    
    var failedView: some View {
        EmptyView()
    }
    
    var progressView: some View {
        ProgressView()
    }
    
    var rootView: some View {
        Group {
            switch store.context {
            case .today:
                todayView
            case .analytics:
                analyticsActivityView
            case .exercises:
                exerciseAnalyticsView
            }
        }
        .safeAreaBar(edge: .top) {
            statsContextPicker
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var statsContextPicker: some View {
        Picker("statsPicker", selection: $store.context.sending(\.selectedPickerChange)) {
            ForEach(StatsFeature.StatsFeatureContext.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.segmented)
        .padding([.leading, .trailing], 6)
        .padding(.bottom, 12)
    }
    
    private var todayView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    // A marker of its own, never a card: every card here is
                    // conditional, and `scrollTo` on an id that is not in the
                    // hierarchy does nothing at all, silently.
                    Color.clear
                        .frame(height: 0)
                        .id(Self.topAnchor)
                    ringActivitiesSummaryView()
                    trainingReadinessView()
                    summaryCards()
                }
            }
            // The offset at rest is the negated top inset, so the sum is zero
            // exactly when the view sits at its top.
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > 1
            } action: { _, isScrolled in
                store.send(.todayScrolledChanged(isScrolled))
            }
            .onChange(of: store.scrollToTopToken) {
                withAnimation { proxy.scrollTo(Self.topAnchor, anchor: .top) }
            }
        }
    }

    /// Identifies the first card, so the proxy has something to scroll back to.
    private static let topAnchor = "stats-today-top"
    
    @ViewBuilder
    private var analyticsActivityView: some View {
        if store.analytics != nil {
            analyticsView()
        } else {
            emptyAnalyticsActivityView
        }
    }
    
    // MARK: - Exercise Analytics
    
    @ViewBuilder
    private var exerciseAnalyticsView: some View {
        if let exerciseStore = store.scope(state: \.exerciseAnalytics, action: \.exerciseAnalytics) {
            ExerciseAnalyticsView(store: exerciseStore)
        }
    }
    
    // MARK: - Analytics Empty View
    
    private var emptyAnalyticsActivityView: some View {
        ContentUnavailableView {
            Label("Analytics Dashboard", systemImage: "chart.xyaxis.line")
        } description: {
            Text("Unlock insights into your training. Visualize your progress, heart rate zones, and performance trends over time.")
        } actions: {
            Button {
                // TODO: - Scroll to history or open charts
            } label: {
                Label("View History", systemImage: "clock.arrow.circlepath")
            }
        }
    }
    
}

