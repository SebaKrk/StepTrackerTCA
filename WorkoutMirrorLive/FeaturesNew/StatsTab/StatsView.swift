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
                await store.send(.view(.pullToRefresh)).finish()
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
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            subscriptionTierMenu
        }
#if DEBUG
        let showDataAnalyzerButton = true
#else
        let showDataAnalyzerButton = store.isDataAnalyzerAvailable && store.subscriptionTier == .elite
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

    private var subscriptionTierMenu: some View {
        Menu {
            ForEach(SubscriptionTier.allCases.filter { $0 != store.subscriptionTier }) { tier in
                Button(tier.name) {
                    send(.subscriptionTierButtonTapped(tier))
                }
            }
            Divider()
            Text(store.subscriptionTier.name)
        } label: {
            Image(systemName: "crown")
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
    
    var failedView: some View {
        EmptyView()
    }
    
    var progressView: some View {
        ProgressView()
    }
    
    var rootView: some View {
        VStack {
            statsContextPicker
            switch store.context {
            case .today:
                todayView
            case .analytics:
                analyticsActivityView
            case .exercises:
                exerciseAnalyticsView
            }
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
        .padding([.leading, .trailing, .bottom], 6)
    }
    
    private var todayView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ringActivitiesSummaryView()
                trainingReadinessView()
                summaryCards()
            }
        }
    }
    
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

