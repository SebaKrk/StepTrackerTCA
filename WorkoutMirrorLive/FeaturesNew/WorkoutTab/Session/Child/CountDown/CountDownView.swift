//
//  CountDownView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 05/08/2025.
//

import ComposableArchitecture
import SwiftUI

struct CountDownView: View {

    let store: StoreOf<CountDownFeature>

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                workoutTypeHeader
                ringWithOverlay
                if store.phase == .waitingForWatch {
                    waitingText
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            store.send(.onAppear)
        }
    }

    // MARK: - Private views (struktura)

    private var workoutTypeHeader: some View {
        Group {
            if let type = store.workoutType {
                VStack(spacing: 6) {
                    Image(systemName: type.iconName.replacingOccurrences(of: ".circle.fill", with: ""))
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text(type.title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Same gray ring drawn for both phases. In `.countingDown` we overlay the pink trim
    /// progress + remaining-seconds number. In `.waitingForWatch` the ring stays empty.
    /// The transition between phases is continuous — same Circle stays on screen,
    /// only the overlay content appears.
    private var ringWithOverlay: some View {
        Circle()
            .stroke(.gray, style: .init(lineWidth: ringLineWidth))
            .frame(width: ringSize, height: ringSize)
            // Subtle pulse w `.waitingForWatch` to signal "active waiting".
            // `store.pulse` toggled przez `pulseToggled` action w CountDownFeature reducer
            // (timer 600ms). View tylko bindings to TCA Store — zero `@State`.
            .opacity(store.phase == .waitingForWatch && store.pulse ? 0.55 : 1.0)
            .animation(.easeInOut(duration: 0.6), value: store.pulse)
            .overlay {
                if store.phase == .countingDown {
                    progressTrim
                }
            }
            .overlay {
                if store.phase == .countingDown {
                    remainingNumber
                }
            }
    }

    private var progressTrim: some View {
        Circle()
            .trim(from: 0, to: store.trimValue)
            .stroke(.pink, style: .init(lineWidth: ringLineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .animation(store.isSettingTrim ? nil : .linear(duration: 1), value: store.timeRemaining)
    }

    private var remainingNumber: some View {
        Text("\(Int(store.timeRemaining.rounded(.up)))")
            .font(.system(size: 60))
            .foregroundColor(.pink)
            .fontWeight(.bold)
            .contentTransition(.numericText(countsDown: true))
            .animation(.easeInOut, value: store.timeRemaining)
    }

    private var waitingText: some View {
        Text("Rozpoczynam na Apple Watch")
            .font(.title.weight(.semibold))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }

    // MARK: - Private content (implementacja)

    private let ringSize: CGFloat = 220
    private let ringLineWidth: CGFloat = 20
}
