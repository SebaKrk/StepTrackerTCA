//
//  GymRoomView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 11/06/2026.
//


//
//  GymRoomView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels
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
        .alert($store.scope(state: \.alert, action: \.alert))
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
        .overlay(alignment: .bottomTrailing) {
            if let token = store.sessionToken {
                qrCornerWidget(token: token)
                    .padding(24)
            }
        }
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
        // Tile fixed size ~320×213pt (3:2 aspect). Athletes dodawane kolejno z lewej-góry.
        // Auto-fit dla dużej liczby: zwiększa cols i proporcjonalnie zmniejsza tile szerokość
        // (zachowując aspect ratio), żeby wszystko zmieściło się w dostępnym obszarze BEZ
        // pustych obszarów po bokach. Tile NIGDY nie urośnie ponad default size.
        GeometryReader { geo in
            let layout = computeGridLayout(
                availableSize: geo.size,
                count: max(1, store.athletes.count)
            )
            let columnsDef = Array(
                repeating: GridItem(.fixed(layout.tileWidth), spacing: layout.spacing),
                count: layout.cols
            )

            LazyVGrid(columns: columnsDef, alignment: .leading, spacing: layout.spacing) {
                ForEach(store.athletes) { athlete in
                    AthleteTileView(athlete: athlete, tileHeight: layout.tileHeight)
                        .frame(width: layout.tileWidth, height: layout.tileHeight)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .animation(.snappy, value: store.athletes)
        }
    }

    /// Iteracyjnie zwiększa liczbę kolumn dopóki wszystkie rzędy nie zmieszczą się w dostępnej wysokości.
    /// Tile NIGDY nie urośnie ponad default (320×213), tylko shrinkuje gdy potrzeba.
    private func computeGridLayout(availableSize: CGSize, count: Int) -> GridLayout {
        let spacing: CGFloat = 16
        let aspectRatio: CGFloat = 3.0 / 2.0
        let defaultTileWidth: CGFloat = 320
        let defaultTileHeight = defaultTileWidth / aspectRatio

        var cols = max(1, Int((availableSize.width + spacing) / (defaultTileWidth + spacing)))
        var rows = Int(ceil(Double(count) / Double(cols)))
        var tileWidth = defaultTileWidth
        var tileHeight = defaultTileHeight
        var requiredHeight = tileHeight * CGFloat(rows) + spacing * CGFloat(rows - 1)

        while requiredHeight > availableSize.height && cols < count {
            cols += 1
            rows = Int(ceil(Double(count) / Double(cols)))
            tileWidth = max(40, (availableSize.width - spacing * CGFloat(cols - 1)) / CGFloat(cols))
            tileHeight = tileWidth / aspectRatio
            requiredHeight = tileHeight * CGFloat(rows) + spacing * CGFloat(rows - 1)
        }

        return GridLayout(cols: cols, tileWidth: tileWidth, tileHeight: tileHeight, spacing: spacing)
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

    // MARK: - QR widget (corner overlay)

    /// Pokaż QR card gdy widoczny, lub ikoniczny toggle button gdy schowany.
    /// Trener może togglować — wszystko związane z QR żyje tylko gdy `sessionToken != nil`.
    @ViewBuilder
    private func qrCornerWidget(token: UUID) -> some View {
        if store.isQRVisible {
            qrCard(token: token)
        } else {
            qrToggleButton
        }
    }

    /// Pełen QR card z code'em + caption. Tap gdziekolwiek w kontener = schowaj QR
    /// (przejście do `qrToggleButton`). `.contentShape` rozszerza hit area na cały
    /// container włącznie z paddingami i tłem.
    private func qrCard(token: UUID) -> some View {
        VStack(spacing: 8) {
            QRCodeView(payload: qrPayloadJSON(token: token))
                .frame(width: 180, height: 180)
                .padding(12)
                .background(.white)
                .clipShape(.rect(cornerRadius: 12))
            Text(qrCaption)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
        .contentShape(.rect(cornerRadius: 20))
        .onTapGesture {
            send(.toggleQR)
        }
    }

    /// Małęj ikoniczny button który pokazuje QR z powrotem.
    private var qrToggleButton: some View {
        Button {
            send(.toggleQR)
        } label: {
            Image(systemName: "qrcode")
                .font(.title)
                .padding(12)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
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

    private var qrCaption: String {
        String(localized: "Skanuj kodem QR", bundle: .main)
    }

    /// Buduje JSON payload dla QR z `sessionToken` + `iPadID` + `gymName` + `createdAt`.
    /// ISO-8601 daty żeby było czytelne po dekodowaniu (peer może debugować w log'u).
    /// Pusty string fallback jeśli encoding fails (rzadkie — wszystkie pola Codable).
    private func qrPayloadJSON(token: UUID) -> String {
        let payload = QRSessionPayload(
            token: token,
            iPadID: store.iPadID,
            gymName: store.gymName
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload),
              let json = String(data: data, encoding: .utf8) else {
            return ""
        }
        return json
    }

}

// MARK: - Grid Layout

/// Wynik obliczeń layoutu siatki — używany przez `computeGridLayout(...)`.
private struct GridLayout {
    let cols: Int
    let tileWidth: CGFloat
    let tileHeight: CGFloat
    let spacing: CGFloat
}

// MARK: - Preview Data

private let previewNames = [
    "Sebastian", "Anna", "Janek", "Maria",
    "Tomek", "Kasia", "Piotr", "Ola",
    "Marek", "Ewa", "Adam", "Hania",
    "Bartek", "Zosia", "Filip", "Lena",
    "Igor", "Nina", "Karol", "Aga",
    "Dawid", "Iza", "Wojtek", "Magda"
]
private let previewBPMs = [
    152, 175, 128, 95, 165, 110, 180, 140,
    155, 122, 168, 100, 144, 158, 130, 172,
    138, 96, 148, 162, 178, 105, 115, 135
]

private func previewAthletes(_ count: Int) -> IdentifiedArrayOf<GymRoomFeature.AthleteTile> {
    IdentifiedArray(uniqueElements: (0..<count).map { index in
        GymRoomFeature.AthleteTile(
            id: UUID(),
            nick: previewNames[index % previewNames.count],
            bpm: previewBPMs[index % previewBPMs.count],
            maxHR: 190,
            activeEnergy: Double(45 + index * 38)
        )
    })
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
    GymRoomView(
        store: Store(initialState: GymRoomFeature.State(isLive: true, athletes: previewAthletes(1), sessionToken: UUID())) {
            GymRoomFeature()
        }
    )
}

#Preview("Live — 2") {
    GymRoomView(
        store: Store(initialState: GymRoomFeature.State(isLive: true, athletes: previewAthletes(2), sessionToken: UUID())) {
            GymRoomFeature()
        }
    )
}

#Preview("Live — 4") {
    GymRoomView(
        store: Store(initialState: GymRoomFeature.State(isLive: true, athletes: previewAthletes(4), sessionToken: UUID())) {
            GymRoomFeature()
        }
    )
}

#Preview("Live — 8") {
    GymRoomView(
        store: Store(initialState: GymRoomFeature.State(isLive: true, athletes: previewAthletes(8), sessionToken: UUID())) {
            GymRoomFeature()
        }
    )
}

#Preview("Live — 12") {
    GymRoomView(
        store: Store(initialState: GymRoomFeature.State(isLive: true, athletes: previewAthletes(12), sessionToken: UUID())) {
            GymRoomFeature()
        }
    )
}

#Preview("Live — 24 (auto-shrink)") {
    GymRoomView(
        store: Store(initialState: GymRoomFeature.State(isLive: true, athletes: previewAthletes(24), sessionToken: UUID())) {
            GymRoomFeature()
        }
    )
}

#Preview("Live — QR hidden") {
    GymRoomView(
        store: Store(initialState: GymRoomFeature.State(isLive: true, athletes: previewAthletes(4), sessionToken: UUID(), isQRVisible: false)) {
            GymRoomFeature()
        }
    )
}
