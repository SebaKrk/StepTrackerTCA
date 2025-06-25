//
//  HeartRateZoneInfoView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 25/06/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

@ViewAction(for: HeartRateZoneInfoFeature.self)
struct HeartRateZoneInfoView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HeartRateZoneInfoFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(HeartRateZone.allCases) { zone in
                        heartRateZoneCell(for: zone)
                    }
                }
                .padding()
            }
            .navigationTitle("Heart Rate Zone")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Private Views
    
    private func heartRateZoneCell(for zone: HeartRateZone) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(zone.color)
                    .frame(width: 20, height: 20)
                    .shadow(color: zone.color.opacity(0.3), radius: 2, x: 0, y: 1)
                HStack {
                    Text(zone.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(formatPercentageRange(zone.percentageRange))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
  
            }
            heartRateZoneDescription(for: zone)
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(zone.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func heartRateZoneDescription(for zone: HeartRateZone) -> some View {
        DisclosureGroup(zone.description,
            isExpanded: Binding(
                get: { store.selectedZone == zone && store.descriptionIsExpanded },
                set: { isExpanded in
                    if isExpanded {
                        send(.selectedZoneDescription(zone))
                    } else {
                        send(.selectedZoneDescription(nil))
                    }
                }
            )
        ) {
            Text(zone.detailedDescription)
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .padding(.top, 4)
        }
        .foregroundStyle(.primary)
    }
    
    // MARK: - Helper Methods
    
    private func formatPercentageRange(_ range: ClosedRange<Double>) -> String {
        let lowerBound = Int(range.lowerBound * 100)
        let upperBound = Int(range.upperBound * 100)
        return "\(lowerBound)% - \(upperBound)% HR max"
    }
}
