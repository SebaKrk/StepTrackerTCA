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
        // Dynamic grid: tile rozmiar dostosowuje się do liczby athletes.
        // 1 athlete → full screen. 2 → 2x1. 4 → 2x2. 9 → 3x3. Każdy tile wypełnia
        // proporcjonalnie dostępną wysokość, dzięki czemu nie ma pustego miejsca.
        GeometryReader { geo in
            let count = max(1, store.athletes.count)
            let cols = columnCount(for: count)
            let rows = Int(ceil(Double(count) / Double(cols)))
            let spacing: CGFloat = 16
            let tileHeight = (geo.size.height - CGFloat(rows - 1) * spacing) / CGFloat(rows)
            let columnsDef = Array(
                repeating: GridItem(.flexible(), spacing: spacing),
                count: cols
            )

            LazyVGrid(columns: columnsDef, spacing: spacing) {
                ForEach(store.athletes) { athlete in
                    AthleteTileView(athlete: athlete)
                        .frame(height: tileHeight)
                }
            }
            .animation(.snappy, value: store.athletes)
        }
    }

    /// Liczba kolumn dobrana do liczby athletes — typowy "Hollywood Squares" layout.
    /// Dla iPada landscape preferujemy szerszy układ (więcej kolumn), żeby tile
    /// były bardziej "card-like" niż "tall strip".
    private func columnCount(for count: Int) -> Int {
        switch count {
        case 0...1: return 1
        case 2...4: return 2
        case 5...9: return 3
        case 10...16: return 4
        default: return 5
        }
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

}

// MARK: - Previews

#Preview("Idle") {
    GymRoomView(
        store: Store(initialState: GymRoomFeature.State()) {
            GymRoomFeature()
        }
    )
}

#Preview("Live — 1") {
    livePreview(count: 1)
}

#Preview("Live — 2") {
    livePreview(count: 2)
}

#Preview("Live — 4") {
    livePreview(count: 4)
}

#Preview("Live — 8") {
    livePreview(count: 8)
}

#Preview("Live — 12") {
    livePreview(count: 12)
}

/// Helper dla preview'ów — buduje mock athletes z rotacyjną pulą nazw + zmiennymi metrykami.
@MainActor
private func livePreview(count: Int) -> some View {
    GymRoomView(
        store: Store(
            initialState: GymRoomFeature.State(
                isLive: true,
                athletes: mockAthletes(count: count)
            )
        ) {
            GymRoomFeature()
        }
    )
}

private func mockAthletes(count: Int) -> IdentifiedArrayOf<GymRoomFeature.AthleteTile> {
    let names = [
        "Sebastian", "Anna", "Janek", "Maria",
        "Tomek", "Kasia", "Piotr", "Ola",
        "Marek", "Ewa", "Adam", "Hania",
        "Bartek", "Zosia", "Filip", "Lena"
    ]
    let bpms = [152, 175, 128, 95, 165, 110, 180, 140, 155, 122, 168, 100, 144, 158, 130, 172]
    let athletes = (0..<count).map { index in
        GymRoomFeature.AthleteTile(
            id: names[index % names.count],
            bpm: bpms[index % bpms.count],
            maxHR: 190,
            activeEnergy: Double(45 + index * 38)
        )
    }
    return IdentifiedArray(uniqueElements: athletes)
}
