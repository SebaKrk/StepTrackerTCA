//
//  CurrentWeightView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: CurrentWeightFeature.self)
struct CurrentWeightView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<CurrentWeightFeature>
    
    // MARK: - View
    
    var body: some View {
        currentWeightBody
            .onAppear {
                send(.viewDidAppear)
            }
            .sheet(item: $store.scope(state: \.destination?.openHealthKitPermissionScreen,
                                      action: \.destination.openHealthKitPermissionScreen)) { store in
                HealthKitPermissionPrimingView(store: store)
            }
    }
    
    // MARK: - Subview
    
    private var currentWeightBody: some View {
        weightBodyWidget(store.latestWeight)
    }

    private func weightBodyWidget(_ data: HealthData?) -> some View {
        GroupBox {
            weightBodyContent(data)
        } label: {
            weightBodyTitleHeader(data)
        }
        .frame(minHeight: 200)
    }
    
    private func weightBodyContent(_ data: HealthData?) -> some View {
        VStack {
            Spacer()
            WidgetBodyContent(title: "Current Weight", value: data?.value, color: .green)
            Spacer()
            weightBodyTitleFooter(data)
        }
    }
    
    @ViewBuilder
    private func weightBodyTitleHeader( _ data: HealthData?) -> some View {
        WidgetHeaderView(title: "Weight", systemImage: "figure", date: data?.date, color: .green) {
            send(.navigationButtonTapped)
        }
    }
    
    @ViewBuilder
    private func weightBodyTitleFooter( _ data: HealthData?) -> some View {
        WidgetTitleFooterHour(date: data?.date, color: .green)
    }
    
}

#Preview {
    let latestWeight = HealthData(date: .now, value: 100)
    NavigationStack {
        CurrentWeightView(store: Store(initialState: CurrentWeightFeature.State(latestWeight: latestWeight), reducer: {
            CurrentWeightFeature(service: DefaultCurrentWeightService())
        }))
    }
}
