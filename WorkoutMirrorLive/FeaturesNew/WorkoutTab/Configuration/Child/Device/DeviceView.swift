//
//  DeviceFeatureView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/08/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

@ViewAction(for: DeviceFeature.self)
struct DeviceView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<DeviceFeature>
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(availableOptions, id: \.self) { option in
                Button {
                    send(.buttonTapped(option))
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: option.symbolName)
                            .frame(width: 55, height: 55)
                            .glassEffect(.regular.interactive(true), in: .capsule)
                            .animation(.snappy, value: store.selected == option)
                            .foregroundStyle(store.selected == option ? .pink : .secondary)
                        
                        Text(option.title)
                            .font(.footnote)
                            .foregroundStyle(store.selected == option ? .pink : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(store.selected == option ? .isSelected : [])
            }
        }
    }

    // MARK: - Implementation

    /// `.mirror` hidden — the join-a-running-Watch-session flow is not implemented
    /// yet (`startButtonTapped` no-ops for it), so showing the icon only confuses.
    /// The enum case stays for the future ticket; we filter at the UI level only.
    private var availableOptions: [DeviceOption] {
        DeviceOption.allCases.filter { $0 != .mirror }
    }
}
