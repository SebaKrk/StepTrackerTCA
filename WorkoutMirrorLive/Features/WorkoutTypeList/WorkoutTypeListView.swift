//
//  WorkoutTypeListView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 04/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutTypeListFeature.self)
struct WorkoutTypeListView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<WorkoutTypeListFeature>
    
    // MARK: - Body
    
    var body: some View {
        workoutTypeList
            .navigationTitle("Workout type list")
    }
    
    // MARK: - Subview
    
    @ViewBuilder
    private var workoutTypeList: some View {
        List(selection: $store.selectedWorkout.sending(\.selectedWorkout)) {
            ForEach(store.workoutTypes, id: \.self) { item in
                listCell(item)
            }
        }
        .padding()
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func listCell(_ item: WorkoutType) -> some View {
        HStack {
            Image(systemName: item.iconName)
                .fixedSize()
            Text(item.title)
            Spacer()
        }
        .tint(.primary)
    }
    
}

//List(WorkoutTypes.workoutConfigurations, id: \.self, selection: $workoutManager.selectedWorkout) { workoutConfiguration in
//    Label {
//        Text(workoutConfiguration.name)
//            .fontWeight(.semibold)
//            .padding(.leading)
//    } icon: {
//        Image(systemName: workoutConfiguration.symbol)
//            .font(.title)
//            .foregroundColor(.accent)
//            .padding(.leading)
//            .padding(.top, 5.0)
//            .padding(.bottom, 5.0)
//    }
//    .frame(minHeight: 50.0)
//    .listRowBackground(
//        RoundedRectangle(cornerRadius: 15.0, style: .continuous)
//            .fill(Color("AccentColor").opacity(0.16))
//    )
//}
