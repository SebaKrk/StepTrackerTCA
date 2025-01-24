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
    }
    
    // MARK: - Subview
    
    private var currentWeightBody: some View {
        VStack {
            if let weightData = store.latestWeight {
                weightBodyWidget(weightData)
            } else {
                emptyWeightBodyWidget()
            }
        }
    }

    private func weightBodyWidget(_ data: HealthData) -> some View {
        GroupBox {
            weightBodyContent(data)
        } label: {
            weightBodyTitleHeaderWithImage(data)
        }
        .frame(width: 200, height: 200)
    }
    
    private func emptyWeightBodyWidget() -> some View {
        GroupBox {
            VStack {
                Spacer()
                Text("brak danych")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        } label: {
            VStack {
                HStack {
                    Label("Weight", systemImage: "figure")
                        .foregroundStyle(.green)
                        .bold()
                    Spacer()
                }
                Divider()
            }
        }
        .frame(width: 200, height: 200)
    }
    
    private func weightBodyContent(_ data: HealthData) -> some View {
        VStack {
            Spacer()
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Weight")
                        .foregroundStyle(.secondary)
                    
                    Text("\(data.value, format: .number.precision(.fractionLength(1))) kg")
                        .font(.title)
                        .bold()
                }
                Spacer()
            }
            Spacer()
            weightBodyTitleFooter(data)
        }
    }
    
    private func weightBodyTitleHeaderWithImage( _ data: HealthData) -> some View {
        VStack {
            HStack {
                Group {
                    Label("Weight", systemImage: "figure")
                    Spacer()
                    Text("\(data.date, format: .dateTime.month(.defaultDigits).day().year(.twoDigits))")
                        .font(.caption)
                }
                .foregroundStyle(.green)
                .bold()
            }
            Divider()
        }
    }
    
    private func weightBodyTitleFooter( _ data: HealthData) -> some View {
        HStack {
            Spacer()
            Text("\(data.date, format: .dateTime.hour().minute())")
                .foregroundStyle(.green)
                .font(.caption)
                .bold()
        }
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
