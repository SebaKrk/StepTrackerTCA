//
//  StrengthSummaryView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 07/03/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: StrengthSummaryFeature.self)
struct StrengthSummaryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<StrengthSummaryFeature>
    
    // MARK: - View
    
    var body: some View {
        Group {
            strengthSummaryWidgetBody
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - SubView
    
    private var strengthSummaryWidgetBody: some View {
        strengthSummaryWidget
    }
    
    private var strengthSummaryWidget: some View {
        GroupBox {
            if let summaries = store.movementSummary {
                strengthSummaryContent(summaries)
            } else {
                //unavailableViewGoalsView()
            }
        } label: {
            strengthSummaryTitleHeader
        }
        .frame(minHeight: 200)
    }
    
    private var strengthSummaryTitleHeader: some View {
        WidgetHeaderView(title: "Strength", systemImage: "dumbbell.fill", color: .green) {
            // dodać akcje przejscaia
        }
    }
    
    private func strengthSummaryContent<T: MovementType>(_ summaries: [MovementSummary<T>]) -> some View {
        VStack {
            titleContainerView
            Divider()
            Spacer().frame(height: 10)
            
            ForEach(summaries) { summary in
                workoutStrengthScore(summary)
                Divider()
            }
            
            Spacer()
        }
    }
    
    private var titleContainerView: some View {
        GeometryReader { geometry in
            HStack {
                titleView("Exercise")
                    .frame(width: geometry.size.width * 0.4, alignment: .leading)
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
    
    private func workoutStrengthScore(_ summary: MovementSummary<some MovementType>) -> some View {
        GeometryReader { geometry in
            HStack {
                Text(summary.movement.title)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .frame(width: geometry.size.width * 0.4, alignment: .leading)
                
                Text(summary.goal.map { "\($0) kg" } ?? "-")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .frame(width: geometry.size.width * 0.3, alignment: .center)
                
                Spacer(minLength: 5)
                
                Text(String(format: "%.2f kg", summary.latestResult))
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .frame(width: geometry.size.width * 0.28, alignment: .trailing)
                    .padding(.trailing, 10)
            }
        }
        .frame(height: 20)
    }
    
}
