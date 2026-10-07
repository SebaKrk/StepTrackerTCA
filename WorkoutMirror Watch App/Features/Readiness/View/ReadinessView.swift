//
//  ReadinessView.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 27/09/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

/// Shows the daily training readiness score pushed from the paired iPhone.
///
/// Mirrors the Home Screen widget: the ring is the full 0-100 scale, while the
/// score itself is carried by the number in the centre and the colour of the
/// level below it.
@ViewAction(for: ReadinessFeature.self)
struct ReadinessView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ReadinessFeature>

    // MARK: - View

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let snapshot = store.snapshot, snapshot.isReliable {
                    scoreContent(for: snapshot)
                } else {
                    noDataView
                }
            }
            .navigationDestination(
                item: $store.scope(state: \.details, action: \.details)
            ) { detailsStore in
                ReadinessDetailsView(store: detailsStore)
            }
        }
        .onAppear {
            send(.onAppear)
        }
    }

    // MARK: - Subviews

    private func scoreContent(for snapshot: ReadinessSnapshot) -> some View {
        VStack(spacing: 4) {
            scoreButton(for: snapshot)
            levelLabel(for: snapshot)
            freshnessLabel(for: snapshot)
        }
    }

    private func scoreButton(for snapshot: ReadinessSnapshot) -> some View {
        Button {
            send(.scoreTapped)
        } label: {
            readinessChart(score: snapshot.overallScore, showScore: true)
        }
        .buttonStyle(.plain)
    }

    private func levelLabel(for snapshot: ReadinessSnapshot) -> some View {
        Text(snapshot.result.readinessLevel.title)
            .font(.caption2.bold())
            .foregroundStyle(snapshot.result.readinessLevel.color)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func freshnessLabel(for snapshot: ReadinessSnapshot) -> some View {
        Text(snapshot.calculatedAt.formatted(.relative(presentation: .named)))
            .font(.system(size: 9))
            .foregroundStyle(.tertiary)
    }

    private var noDataView: some View {
        ZStack {
            VStack(spacing: 4) {
                readinessChart(score: 0, showScore: false)
                Text(verbatim: "-")
            }
            .blur(radius: 6)

            VStack(spacing: 4) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text(String(localized: "No Data"))
                    .font(.caption.bold())

                Text(String(localized: "Open on iPhone"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Ring

    private func readinessChart(score: Int, showScore: Bool) -> some View {
        ZStack {
            backgroundTrack
            foregroundTrack

            if showScore {
                Text("\(score)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: ringDiameter, height: ringDiameter)
    }

    private var backgroundTrack: some View {
        Chart(ReadinessLevel.allCases, id: \.self) { level in
            SectorMark(
                angle: .value("Range", sliceWidth(of: level)),
                innerRadius: .ratio(0.55),
                angularInset: 0
            )
            .cornerRadius(2)
            .foregroundStyle(level.color.opacity(0.15))
        }
        .chartBackground { _ in Color.clear }
    }

    private var foregroundTrack: some View {
        Chart(ReadinessLevel.allCases, id: \.self) { level in
            SectorMark(
                angle: .value("Range", sliceWidth(of: level)),
                innerRadius: .ratio(0.62),
                outerRadius: .inset(4),
                angularInset: 0.8
            )
            .cornerRadius(4)
            .foregroundStyle(level.color)
        }
        .chartBackground { _ in Color.clear }
    }

    /// Angular width of a level's slice, taken from its own score range so the
    /// thresholds live in exactly one place.
    private func sliceWidth(of level: ReadinessLevel) -> Double {
        Double(level.range.count)
    }

    private var ringDiameter: CGFloat { 92 }
}

// MARK: - Preview

#Preview {
    ReadinessView(store: Store(initialState: ReadinessFeature.State()) {
        ReadinessFeature()
    })
}
