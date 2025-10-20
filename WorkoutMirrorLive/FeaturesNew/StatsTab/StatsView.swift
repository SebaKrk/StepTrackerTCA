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
            .toolbar {
                toolbarButton
            }
            .fullScreenCover(item: $store.scope(state: \.destination?.personSettings,
                                                action: \.destination.personSettings)) { store in
                PersonSettingsView(store: store)
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
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.personButtonTapped)
            } label: {
                Image(systemName: "person")
            }
        }
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

