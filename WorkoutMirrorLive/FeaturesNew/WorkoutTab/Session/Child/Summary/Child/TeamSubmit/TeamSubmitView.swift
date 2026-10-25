//
//  TeamSubmitView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: TeamSubmitFeature.self)
struct TeamSubmitView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<TeamSubmitFeature>

    // MARK: - Body (structure)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sendToggle
            content
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.loadState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .leading)
        case .failed:
            Text(unavailableText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .success:
            if store.isEnabled {
                divisionPicker
                kcalToggle
                windowCaption
            }
        }
    }

    // MARK: - Implementation

    private var sendToggle: some View {
        Toggle(isOn: $store.isEnabled.sending(\.view.enabledChanged)) {
            Label(sendTitle, systemImage: "person.3.fill")
                .font(.headline)
        }
        .disabled(store.loadState != .success)
    }

    private var divisionPicker: some View {
        Picker(divisionTitle, selection: $store.division.sending(\.view.divisionChanged)) {
            Text(rxTitle).tag(BoardDivision.rx)
            Text(scaledTitle).tag(BoardDivision.scaled)
        }
        .pickerStyle(.segmented)
    }

    private var kcalToggle: some View {
        Toggle(isOn: Binding(
            get: { store.includeKcal },
            set: { send(.includeKcalChanged($0)) }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text(kcalTitle)
                Text(kcalHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var windowCaption: some View {
        if let plan = store.context?.plan {
            Text(String(localized: "Effort counts the first \(plan.sessionMinutes) minutes from the workout start."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var sendTitle: String {
        guard let name = store.context?.groupName else { return String(localized: "Send to Group") }
        return String(localized: "Send to \(name)")
    }

    // MARK: - Text

    private let divisionTitle = String(localized: "Division")
    private let rxTitle = String(localized: "Rx")
    private let scaledTitle = String(localized: "Scaled")
    private let kcalTitle = String(localized: "Share kcal")
    private let kcalHint = String(localized: "Health data — the group sees it next to your result. Never used for ranking.")
    private let unavailableText = String(localized: "The group plan isn't available — the result stays only on this phone.")
}
