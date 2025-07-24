//
//  SessionConfigurationView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/07/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

@ViewAction(for: SessionConfigurationFeature.self)
struct SessionConfigurationView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<SessionConfigurationFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    goalPicker
                    if store.goal == .timeLimit {
                        timePickerView
                    }
                    infoButton
                }
            }
            .navigationTitle(store.title)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        send(.sheetDismissed)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        send(.sheetDismissed)
                    }
                }
            }
        }
        .sheet(isPresented: $store.isNoteSheetPresented) {
            noteSheet
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private var goalPicker: some View {
        List {
            Section(store.title) {
                ForEach(SimpleWorkoutGoal.allCases, id: \.self) { goal in
                    Button {
                        send(.goalButtonTapped(goal))
                    } label: {
                        HStack {
                            Text(goal.title)
                            Spacer()
                            if store.goal == goal {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.pink)
                            }
                        }
                        .padding()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets())
                }
            }
        }
    }
    
    private var timePickerView: some View {
        VStack {
            Picker("Time", selection: $store.time.sending(\.timeChanged)) {
                ForEach(store.availableTime, id: \.self) { time in
                    Text("\(time)")
                        .tag(time as Int?)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 125)
        }
    }
    
    private var infoButton: some View {
        Button {
            send(.noteButtonTapped)
        } label: {
            HStack {
                Text("Info")
                    .foregroundColor(.primary)
                Spacer()
                Text(store.infoButtonText)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var noteSheet: some View {
        NavigationStack {
            Form {
                TextEditor(text: $store.note.sending(\.noteChanged))
                    .overlay(
                        Group {
                            if store.note.isEmpty {
                                VStack {
                                    HStack {
                                        Text(store.notePlaceholder)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 8)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
            }
            .navigationTitle("\(store.title) Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        send(.noteDismissed)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
