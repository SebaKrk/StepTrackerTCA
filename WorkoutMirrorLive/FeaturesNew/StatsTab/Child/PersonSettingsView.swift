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
            }
            Section {
                coreMetricsCell("Name", "Sebastian")
                coreMetricsCell("Height", "182 cm")
                coreMetricsCell("Age", "38")
                coreMetricsCell("Weight", "78 kg")
                coreMetricsCell("Sex", "Male")
            } header: {
                Text("Personal Info")
            }
            Section {
                coreMetricsCell("Resting HR", "65 bpm")
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
