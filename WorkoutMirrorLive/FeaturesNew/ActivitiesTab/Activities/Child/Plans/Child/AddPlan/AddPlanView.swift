//
//  AddPlanView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: AddPlanFeature.self)
struct AddPlanView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<AddPlanFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection
                optionsSection
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [store.color.opacity(0.25), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Add Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        send(.dismissTapped)
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .navigationDestination(
                item: $store.scope(state: \.destination?.scanPlan, action: \.destination.scanPlan)
            ) { scanPlanStore in
                ScanPlanView(store: scanPlanStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.destination?.editor, action: \.destination.editor)
            ) { editorStore in
                TrainingSessionEditorView(store: editorStore)
            }
        }
    }
    
    // MARK: - SubViews
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(store.color)
            
            Text("Create a Workout Plan")
                .font(.title2)
                .bold()
            
            Text("Scan your handwritten notes or enter manually")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
    
    private var optionsSection: some View {
        VStack(spacing: 16) {
            optionButton(
                title: "Scan Plan",
                subtitle: "Take a photo of your workout notes",
                icon: "camera.fill",
                action: { send(.scanPlanTapped) }
            )
            
            optionButton(
                title: "Manual Entry",
                subtitle: "Enter workout details manually",
                icon: "pencil.line",
                action: { send(.manualEntryTapped) }
            )
        }
        .padding(.top, 20)
    }
    
    private func optionButton(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(store.color)
                    .frame(width: 44, height: 44)
                    .background(store.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
}
