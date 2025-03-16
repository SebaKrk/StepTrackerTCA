//
//  SummaryView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SummaryFeature.self)
struct SummaryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<SummaryFeature>
    
    // MARK: - View
    
    var body: some View {
        Group {
            summaryBody
        }
        .onAppear {
            send(.viewDidAppear)
        }
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.open,
                action: \.destination.open)) { store in
                    ScoresView(store: store)
                }
        
    }
    
    // MARK: - SubView
    
    @ViewBuilder
    private var summaryBody: some View {
        if let data = store.groupedWorkouts {
            ForEach(data) { item in
                summaryWorkoutTypeWidget(item)
            }
        } else {
            unavailableView
        }
    }
    
    private func summaryWorkoutTypeWidget(_ data: GroupedWorkouts) -> some View {
        GroupBox {
            VStack {
                titleContainerView
                Divider()
                Spacer().frame(height: 10)
                ForEach(data.movements) { movement in
                    summaryByGroupedMovement(movement)
                    Divider()
                }
                Spacer()
            }
        } label: {
            summaryTitleHeader(data.workoutType.title, data.workoutType.icon, workoutType: data.workoutType)
        }
        .frame(minHeight: 200)
    }

    private func summaryByGroupedMovement(_ data: GroupedMovement) -> some View {
        GeometryReader { geometry in
            HStack {
                Text(data.movement.title)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .frame(width: geometry.size.width * 0.4, alignment: .leading)
                
                /// Text(summary.goal.map { "\($0) kg" } ?? "-")
                // TODO: - zaimplementować Goal
                Text("_")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .frame(width: geometry.size.width * 0.3, alignment: .center)
                Spacer(minLength: 5)
                Text(data.sessions.last?.value ?? "brak")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .frame(width: geometry.size.width * 0.28, alignment: .trailing)
                
            }
        }
        .frame(height: 20)
    }
    
    private func summaryTitleHeader(_ title: String, _ icon: String,
                                    workoutType: WorkoutType) -> some View {
        WidgetHeaderView(title: title, systemImage: icon, color: .green) {
            send(.navigationButtonTapped(workoutType))
        }
    }

    private var titleContainerView: some View {
        GeometryReader { geometry in
            HStack {
                titleView("Exercise")
                    .frame(width: geometry.size.width * 0.4, alignment: .leading)
                    .padding(.leading,2)
                titleView("Goal")
                    .frame(width: geometry.size.width * 0.3, alignment: .center)
                titleView("Result")
                    .frame(width: geometry.size.width * 0.3, alignment: .trailing)
                    .padding(.trailing, 5)
            }
            .frame(width: geometry.size.width)
        }
        .frame(height: 20)
    }
    
    private func titleView(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
    }
    
    private var unavailableView: some View {
        ChartContentUnavailable()
    }
    
}
