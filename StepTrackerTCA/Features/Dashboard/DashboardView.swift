//
//  DashboardView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: DashboardFeature.self)
struct DashboardView: View {
    
    // MARK: - Properties
    
    var store: StoreOf<DashboardFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            ScrollView {
                groupBoxWalkView
                groupBoxCalendarView
            }
            .navigationTitle("Dashboard")
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    @ViewBuilder
    private var groupBoxWalkView: some View {
        GroupBox {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.secondary)
                .frame(height: 150)
        } label: {
            groupBoxTitle(
                "Steps",
                "figure.walk",
                "Avg: 10K Steps"
            )
        }
        .padding()
    }
    
    @ViewBuilder
    private var groupBoxCalendarView: some View {
        GroupBox {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.secondary)
                .frame(height: 240)
        } label: {
            groupBoxTitle("Averages",
                          "calendar",
                          "Last 28 Days",
                          destination: false)
        }
        .padding()
    }
        
    
    @ViewBuilder
    private func groupBoxTitle(_ title: String, _ systemImage: String, _ secondaryText: String, destination: Bool = true) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Label(title, systemImage: systemImage)
                    .font(.title3.bold())
                    .foregroundStyle(.pink)
                Text(secondaryText)
                    .font(.caption)
            }
            Spacer()
            if destination {
                Image(systemName: "chevron.right")
            }
        }
    }
    
}

#Preview {
    DashboardView(store: Store(initialState: DashboardFeature.State(), reducer: {
        DashboardFeature()
    }))
}
