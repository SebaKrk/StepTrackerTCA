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
    
    // MARK: - Body
    
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
                Button {
                    send(.addPlanTapped)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.addPlan, action: \.destination.addPlan)
        ) { addPlanStore in
            AddPlanView(store: addPlanStore)
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - SubViews
    
    @ViewBuilder
    private var plansListView: some View {
        // TODO: - implementacja listy
        emptyPlansView
    }
    
    private var failedView: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Unable to load workout plans. Please try again.")
        }
    }
    
    private var emptyPlansView: some View {
        ContentUnavailableView {
            Label("No Workout Plans", systemImage: "doc.text")
        } description: {
            Text("Create workout plans by scanning your training notes or add them manually. Compare your plans with actual HealthKit results.")
        } actions: {
            Button {
                send(.addPlanTapped)
            } label: {
                Label("Add Plan", systemImage: "plus")
            }
        }
    }
    
}
