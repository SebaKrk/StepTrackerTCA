//
//  RingActivitiesSummaryView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 19/10/2025.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: RingActivitiesSummaryFeature.self)
struct RingActivitiesSummaryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<RingActivitiesSummaryFeature>
    
    // MARK: - Body
    
    var body: some View {
        activitiesSummaryView
            .navigationDestination(
                item: $store.scope(
                    state: \.destination?.details,
                    action: \.destination.details)) { store in
                        RingActivitiesSummaryDetailsView(store: store)
                    }
    }
    
    private var activitiesSummaryView: some View {
        GroupBox {
            activityContentView
        } label: {
            VStack {
                headerTitle
                Divider()
            }
        }
        .backgroundStyle(.clear)
        .foregroundStyle(.secondary)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(.gray.opacity(0.5), lineWidth: 0.5)
            .fill(Color(.secondarySystemBackground).gradient.opacity(0.5)))
        .frame(height: 120)
        .onAppear {
            send(.viewDidAppear)
        }
        .skeleton(isLoading: store.viewState == .loading)
    }
    
    // MARK: - SubView
    
    private var activityContentView : some View {
        VStack {
            Spacer()
            if let data = store.activityRingData {
                activityView(data)
            } else {
                // TODO: - co chce tu pokzac
                Text("No data avialble")
            }
        }
    }
    
    private var headerTitle: some View {
        Button {
            send(.showDetailsButtonTapped)
        } label: {
            HStack {
                Text("Activities Summary")
                Spacer()
                currentTimeView
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.gray)
            .font(.caption)
        }
    }
    
    private var currentTimeView: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            Text(context.date.formatted(.dateTime.hour().minute()))
                .monospacedDigit()
        }
    }
    
    private func activityView(_ data: ActivityRingData) -> some View {
        HStack {
            activityMetric(
                title: "W ruchu",
                value: Int(data.moveValue),
                unit: "kcal",
                color: .pink
            )
            Divider()
            activityMetric(
                title: "Ćwiczenie",
                value: Int(data.exerciseValue),
                unit: "min",
                color: .green
            )
            Divider()
            activityMetric(
                title: "Na nogach",
                value: Int(data.standValue),
                unit: "godz.",
                color: .cyan
            )
            Divider()
            Spacer().frame(width: 50)
        }
        .font(.subheadline)
    }
    
    private func activityMetric(title: String, value: Int, unit: String, color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundStyle(color)
                .fontWeight(.semibold)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.title3)
                    .monospacedDigit()
                    .fontWeight(.semibold)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("success") {
    RingActivitiesSummaryView(
        store: .init(
            initialState: .init(
                viewState: .success, activityRingData: ActivityRingData(
                    moveValue: 14,
                    moveGoal: 500,
                    exerciseValue: 10,
                    exerciseGoal: 30,
                    standValue: 2,
                    standGoal: 12
                )
            ),
            reducer: { RingActivitiesSummaryFeature() }
        )
    )
    .padding()
}

#Preview("success") {
    RingActivitiesSummaryView(
        store: .init(
            initialState: .init(
                viewState: .loading, activityRingData: ActivityRingData(
                    moveValue: 14,
                    moveGoal: 500,
                    exerciseValue: 10,
                    exerciseGoal: 30,
                    standValue: 2,
                    standGoal: 12
                )
            ),
            reducer: { RingActivitiesSummaryFeature() }
        )
    )
    .padding()
}
