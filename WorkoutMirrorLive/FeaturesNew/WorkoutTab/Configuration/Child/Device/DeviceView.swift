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
                deviceButton(option)
            }
        }
        .alert($store.scope(state: \.broadcastAlert, action: \.broadcastAlert))
    }

    // MARK: - Implementation

    /// `.mirror` hidden — the join-a-running-Watch-session flow is not implemented
    /// yet (`startButtonTapped` no-ops for it), so showing the icon only confuses.
    /// The enum case stays for the future ticket; we filter at the UI level only.
    private var availableOptions: [DeviceOption] {
        DeviceOption.allCases.filter { $0 != .mirror }
    }

    private func deviceButton(_ option: DeviceOption) -> some View {
        Button {
            send(.buttonTapped(option))
        } label: {
            VStack(spacing: 6) {
                iconTile(option)
                title(option)
                    .font(.footnote)
            }
            .foregroundStyle(store.selected == option ? .pink : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title(option))
        .accessibilityAddTraits(store.selected == option ? .isSelected : [])
    }

    private func iconTile(_ option: DeviceOption) -> some View {
        icon(option)
            .frame(width: 55, height: 55)
            .glassEffect(.regular.interactive(true), in: .capsule)
            .animation(.snappy, value: store.selected == option)
    }

    @ViewBuilder
    private func icon(_ option: DeviceOption) -> some View {
        switch option {
        case .watch:
            Image(systemName: "applewatch")
        case .hrBelt:
            HRBeltIcon()
        case .airPods:
            Image(systemName: "airpods.pro")
        case .iphone, .mirror:
            Image(systemName: "iphone")
        }
    }

    private func title(_ option: DeviceOption) -> Text {
        switch option {
        case .watch:
            Text("Apple Watch")
        case .hrBelt:
            Text("HR belt")
        case .airPods:
            Text("AirPods")
        case .iphone, .mirror:
            Text("Other HR device")
        }
    }
}
