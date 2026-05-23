//
//  GymRoomView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: GymRoomFeature.self)
struct GymRoomView: View {

    @Bindable var store: StoreOf<GymRoomFeature>

    var body: some View {
        ZStack {
            background
            if store.isLive {
                liveView
            } else {
                idleView
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            send(.viewDidAppear)
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: - Private views (struktura)

    private var background: some View {
        Color.black
            .ignoresSafeArea()
    }

    private var idleView: some View {
        startButton
    }

    private var liveView: some View {
        VStack(spacing: 0) {
            header
            grid
            Spacer()
        }
    }

    private var header: some View {
        HStack {
            Text(headerTitle)
                .font(.title)
                .foregroundStyle(.white)
            Spacer()
            endButton
        }
        .padding()
    }

    private var grid: some View {
        LazyVGrid(columns: gridColumns, spacing: 20) {
            ForEach(store.athletes) { athlete in
                AthleteTileView(athlete: athlete)
            }
        }
        .padding()
    }

    private var startButton: some View {
        Button {
            send(.startTapped)
        } label: {
            Text(startTitle)
                .font(startFont)
                .foregroundStyle(.white)
                .padding(.horizontal, 60)
                .padding(.vertical, 30)
                .background(startBackground)
        }
    }

    private var endButton: some View {
        Button {
            send(.endTapped)
        } label: {
            Text(endTitle)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(endBackground)
        }
    }

    // MARK: - Private content (implementacja)

    private var headerTitle: String {
        String(localized: "Gym Room · LIVE · \(store.athletes.count) athletes", bundle: .main)
    }

    private var startTitle: String {
        String(localized: "Start class", bundle: .main)
    }

    private var endTitle: String {
        String(localized: "End", bundle: .main)
    }

    private var startFont: Font {
        .system(size: 56, weight: .bold, design: .rounded)
    }

    private var startBackground: some View {
        Capsule().fill(.green)
    }

    private var endBackground: some View {
        Capsule().fill(.red)
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)
    }
}

#Preview("Idle") {
    GymRoomView(
        store: Store(initialState: GymRoomFeature.State()) {
            GymRoomFeature()
        }
    )
}

#Preview("Live") {
    let mockAthletes: IdentifiedArrayOf<GymRoomFeature.AthleteTile> = [
        .init(id: "Sebastian", bpm: 152, maxHR: 190),
        .init(id: "Anna", bpm: 175, maxHR: 185),
        .init(id: "Janek", bpm: 128, maxHR: 195),
    ]
    return GymRoomView(
        store: Store(
            initialState: GymRoomFeature.State(isLive: true, athletes: mockAthletes)
        ) {
            GymRoomFeature()
        }
    )
}
