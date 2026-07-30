//
//  ActivitiesView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

struct ActivitiesView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ActivitiesFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                switch store.context {
                case .activity:
                    personalActivityView
                case .plans:
                    plansView
                }
            }
            .safeAreaBar(edge: .top) {
                trainingTabPicker
            }
            .background(
                LinearGradient(
                    colors: [store.color.opacity(0.25), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - SubView
    
    private var trainingTabPicker: some View {
        Picker("trainingTabPicker", selection: $store.context.sending(\.selectedPickerChange)) {
            ForEach(ActivitiesFeature.TrainingTabContext.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.segmented)
        .padding([.leading, .trailing], 6)
        .padding(.bottom, 12)
    }
    
    private var personalActivityView: some View {
        PersonalActivityView(
            store: store.scope(state: \.personalActivity, action: \.personalActivity)
        )
    }
    private var plansView: some View {
        PlansView(
            store: store.scope(state: \.plans, action: \.plans)
        )
    }
    
}
