//
//  PersonSettingsView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: PersonSettingsFeature.self)
struct PersonSettingsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<PersonSettingsFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            rootView
                .onAppear {
                    send(.viewDidAppear)
                }
                .toolbar {
                    toolbarButton
                }
                .navigationTitle("Personal Settings")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - SubView
    
    private var rootView: some View {
        List {
            Section {
                coreMetricsCell("Name", "Sebastian")
                coreMetricsCell("Surename", "-")
            }
            Section {
                coreMetricsCell("Height", store.height)
                coreMetricsCell("Age", store.age)
                coreMetricsCell("Weight", store.weight)
                coreMetricsCell("Sex", store.sex)
            } header: {
                Text("Personal Info")
            }
            Section {
                coreMetricsCell("Resting HR", store.restingHeartRate)
                coreMetricsCell("Activity Level", "Active")
            } header: {
                Text("Heart Rate & Activity")
            } footer: {
                Text("Your personal data is used to calculate accurate heart rate zones, calorie burn, and training recommendations. All information remains private on your device.")
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.xMarkButtonTapped)
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
    
    private func coreMetricsCell(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
        }
    }
    
}
