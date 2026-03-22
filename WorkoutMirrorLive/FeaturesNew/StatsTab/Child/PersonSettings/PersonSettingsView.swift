//
//  PersonSettingsView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import AppDatabase
import ComposableArchitecture
import SharedModels
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
                .navigationDestination(
                    item: $store.scope(state: \.destination?.apiKey, action: \.destination.apiKey)
                ) { apiKeyStore in
                    APIKeyEntryView(store: apiKeyStore)
                }
                .sheet(
                    item: $store.scope(state: \.destination?.editProfile, action: \.destination.editProfile)
                ) { editStore in
                    PersonProfileEditView(store: editStore)
                }
        }
    }
    
    // MARK: - SubView
    
    private var rootView: some View {
        List {
            Section {
                coreMetricsCell("Name", store.userProfile?.name ?? "-")
                coreMetricsCell("Surname", store.userProfile?.surname ?? "-")
                coreMetricsCell("Nickname", store.userProfile?.nickname ?? "-")
                coreMetricsCell("Email", store.userProfile?.email ?? "-")
            } header: {
                Text("Identity")
            } footer: {
                Text("Tap to edit your profile.")
            }
            .contentShape(Rectangle())
            .onTapGesture {
                send(.editProfileTapped)
            }
            Section {
                coreMetricsCell("Height", store.height.map { "\($0.value)" })
                coreMetricsCell("Age", store.age.map { "\($0)" })
                coreMetricsCell("Weight", store.weight.map { String(format: "%.1f", $0.value) })
                coreMetricsCell("Sex", store.sex?.displayName)
            } header: {
                Text("Personal Info")
            }
            Section {
                coreMetricsCell("Plan", store.subscriptionTier.name)
            } header: {
                Text("Subscription Plan")
            }
            Section {
                coreMetricsCell("Resting HR", store.restingHeartRate.map { "\(Int($0.value))" } ?? "-")
                coreMetricsCell("Max HR", store.maxHR.map { "\($0)" } ?? "-")
                
            } header: {
                Text("Heart Rate & Activity")
            } footer: {
                Text("Your personal data is used to calculate accurate heart rate zones, calorie burn, and training recommendations. All information remains private on your device.")
            }

            Section {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundStyle(.secondary)
                    Text("API Key")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    send(.apiKeyTapped)
                }
            } header: {
                Text("Developer")
            } footer: {
                Text("Manage API keys for AI-powered workout parsing and analysis.")
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
    
    private func coreMetricsCell(_ key: String, _ value: String?) -> some View {
        HStack {
            Text(key)
            Spacer()
            if let value, !value.isEmpty {
                Text(value)
            } else {
                Text("-")
            }
        }
    }

}

// MARK: - Preview

#Preview {
    let _ = prepareDependencies {
        try? $0.bootstrapDatabase()
    }
    PersonSettingsView(
        store: Store(
            initialState: PersonSettingsFeature.State(
                userProfile: UserProfile(
                    id: UUID(),
                    email: "jan@example.com",
                    name: "Jan",
                    surname: "Kowalski",
                    nickname: "janek"
                )
            )
        ) {
            PersonSettingsFeature()
        }
    )
}
