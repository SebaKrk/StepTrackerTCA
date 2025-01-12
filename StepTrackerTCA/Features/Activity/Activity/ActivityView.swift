//
//  ActivityView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ActivityFeature.self)
struct ActivityView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ActivityFeature>
    
    // MARK: - View
    
    public var body: some View {
        VStack(spacing: 0) {
            activityPeriodPicker
            activityList
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.detailItem,
                action: \.destination.detailItem
            )
        ) { store in
            ActivityDetailsView(store: store)
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Subview
    
    @ViewBuilder
    private var activityPeriodPicker: some View {
        Picker("ActivityPeriodPicker", selection: $store.activityPeriod.sending(\.selectedPickerChange)) {
            ForEach(ActivityPeriod.allCases, id: \.id) { period in
                Text(period.title)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding([.leading, .trailing], 12)
    }
    
    @ViewBuilder
    private var activityList: some View {
        List(selection: $store.selectedWorkout.sending(\.workoutSelected)) {
            ForEach(WorkoutData.mockData) { item in
                Button {
                    send(.tapWorkout(item))
                } label: {
                    activityCell(item)
                }
            }
        }
        .listStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding(.top, 0)
        .padding([.leading, .trailing], 12)
    }
    
    @ViewBuilder
    private func activityCell(_ data: WorkoutData) -> some View {
        HStack {
            Image(systemName: data.image)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(.black)
                .bold()
            Text(data.title)
                .foregroundStyle(.primary)
            Text(data.date, format: .dateTime.month().day())
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(data.kcal, format: .number.precision(.fractionLength(0))) KCAL")
        }
        .tint(.primary)
    }
    
}

#Preview {
    NavigationStack {
        ActivityView(store: Store(initialState: ActivityFeature.State(workoutData: WorkoutData.mockData), reducer: {
            ActivityFeature()
        }))
    }
}

