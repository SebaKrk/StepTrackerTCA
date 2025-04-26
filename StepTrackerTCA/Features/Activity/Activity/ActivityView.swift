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
    
    var withoutNavigationDestination = false
    
    // MARK: - View
    
    public var body: some View {
        if withoutNavigationDestination {
            activityBody
        } else {
            activityBody
                .navigationDestination(
                    item: $store.scope(
                        state: \.destination?.detailItem,
                        action: \.destination.detailItem)) { store in
                            ActivityDetailsView(store: store)
                        }
                .navigationDestination(
                    item: $store.scope(
                        state: \.destination?.heartRateDetails,
                        action: \.destination.heartRateDetails)) { store in
                            HeartRateDetailsView(store: store)
                        }
        }
    }
    
    // MARK: - Subview
    
    private var activityBody: some View {
        VStack(spacing: 0) {
            activityPeriodPicker
            activityListView
        }
        .navigationTitle("Activity")
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    @ViewBuilder
    private var activityListView: some View {
        switch store.activityPeriod {
        case .day:
            activityList
        case .fourWeeks:
            hkWorkoutList
        }
    }
    
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
    
    private var hkWorkoutList: some View {
        List(selection: $store.selectedHKWorkout.sending(\.HKWorkoutSelected)) {
            ForEach(store.workouts, id: \.uuid) { item in
                Button {
                    send(.tapHKWorkout(item))
                } label: {
                    Text(item.workoutActivityType.name)
                }
            }
        }
        .listStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding(.top, 0)
        .padding([.leading, .trailing], 12)
    }
    
}

#Preview {
    NavigationStack {
        ActivityView(store: Store(initialState: ActivityFeature.State(workoutData: WorkoutData.mockData), reducer: {
            ActivityFeature()
        }))
    }
}


