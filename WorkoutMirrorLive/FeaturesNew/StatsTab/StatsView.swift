//
//  StatsView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
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
    }
    
    var statsView: some View {
        rootView
            .refreshable {
                send(.pullToRefresh)
            }
            .toolbar {
                toolbarButton
            }
            .task {
                send(.checkDataAnalyzerAvailability)
            }
            .padding([.leading, .trailing], 8)
            .background(LinearGradient(colors: [store.color.opacity(0.25
                                                             ), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            .fullScreenCover(item: $store.scope(state: \.destination?.personSettings,
                                                action: \.destination.personSettings)) { store in
                PersonSettingsView(store: store)
                    .navigationTransition(.zoom(sourceID: "personSettings", in: zoomTransition))
            }
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
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
        if #available(iOS 26, *) {
            if store.isDataAnalyzerAvailable {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        print("AnalyzerAvailable GO")
                    } label: {
                        Image(systemName: "apple.intelligence")
                    }
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.personButtonTapped)
            } label: {
                Image(systemName: "person")
            }
        }
        .matchedTransitionSource(id: "personSettings", in: zoomTransition)
    }
    
    var failedView: some View {
        EmptyView()
    }
    
    var progressView: some View {
        ProgressView()
    }
    
    var rootView: some View {
        ScrollView {
            statsContextPicker
            switch store.context {
            case .today:
                todayView
            case .analytics:
                Text("Analytics")
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
        VStack(spacing: 12) {
            ringActivitiesSummaryView()
            trainingReadinessView()
            summaryCards()
        }
    }
    
}

