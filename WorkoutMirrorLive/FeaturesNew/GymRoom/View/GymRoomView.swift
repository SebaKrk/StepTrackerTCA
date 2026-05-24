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
        .preferredColorScheme(.dark)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            send(.viewDidAppear)
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: - Private views (struktura)

    private var background: some View {
        // Neutralny dark gradient (jak w tile gradient pattern, ale bez zone color):
        // czarne u góry → ciemnoszare u dołu. Daje subtelną głębię bez akcentów kolorystycznych.
        LinearGradient(
            colors: [
                .black,
                Color(white: 0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var idleView: some View {
        startButton
    }

    private var liveView: some View {
        VStack(spacing: 16) {
            header
            grid
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(headerTitle)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text(headerSubtitle)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            athleteCountBadge
            endButton
        }
    }

    private var athleteCountBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.3.sequence.fill")
                .foregroundStyle(.primary)
                .font(.title3)
            Text(athleteCountText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(store.athletes.count)))
                .animation(.snappy, value: store.athletes.count)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(in: .capsule)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 20) {
                ForEach(store.athletes) { athlete in
                    AthleteTileView(athlete: athlete)
                }
            }
            .animation(.snappy, value: store.athletes)
        }
        .scrollIndicators(.hidden)
    }

    private var startButton: some View {
        Button {
            send(.startTapped)
        } label: {
            Label(startTitle, systemImage: "play.fill")
                .font(.title2.weight(.semibold))
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
    }

    private var endButton: some View {
        Button(role: .destructive) {
            send(.endTapped)
        } label: {
            Text(endTitle)
                .font(.headline)
                .foregroundStyle(.red)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
    }

    // MARK: - Private content (implementacja)

    private var headerTitle: String {
        String(localized: "Gym Room", bundle: .main)
    }

    private var headerSubtitle: String {
        String(localized: "LIVE", bundle: .main)
    }

    private var athleteCountText: String {
        String(localized: "\(store.athletes.count) athletes", bundle: .main)
    }

    private var startTitle: String {
        String(localized: "Start class", bundle: .main)
    }

    private var endTitle: String {
        String(localized: "End", bundle: .main)
    }

    /// Adaptive — system dobiera kolumny do dostępnej szerokości.
    /// iPad portrait: 2 kolumny (~ 360pt każda). iPad landscape: 3 kolumny.
    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 360), spacing: 20)]
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
        .init(id: "Maria", bpm: 95, maxHR: 180),
        .init(id: "Tomek", bpm: 165, maxHR: 192),
    ]
    return GymRoomView(
        store: Store(
            initialState: GymRoomFeature.State(isLive: true, athletes: mockAthletes)
        ) {
            GymRoomFeature()
        }
    )
}
