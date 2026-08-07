//
//  SharePlanView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SharePlanFeature.self)
struct SharePlanView: View {

    @Bindable var store: StoreOf<SharePlanFeature>

    // MARK: - Body (structure)

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .onAppear {
                send(.viewDidAppear)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch store.qrResult {
        case let .ready(image):
            qrCard(image)
        case .tooLargeForQR:
            tooLargeState
        case .failed:
            failedState
        case nil:
            ProgressView()
        }
    }

    /// QR card matching GymRoom's `qrCard` — QR on a white plate inside a
    /// material card, so the two share one visual language.
    private func qrCard(_ image: CGImage) -> some View {
        VStack(spacing: 8) {
            qrCode(image)
            qrCaption
        }
        .padding(16)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
    }

    // MARK: - Implementation

    private func qrCode(_ image: CGImage) -> some View {
        PlanQRCodeView(cgImage: image)
            .frame(maxWidth: qrSize)
            .aspectRatio(1, contentMode: .fit)
            .padding(12)
            .background(.white)
            .clipShape(.rect(cornerRadius: 12))
    }

    private var qrCaption: some View {
        Text(scanPrompt)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
    }

    private var tooLargeState: some View {
        ContentUnavailableView {
            Label(tooLargeTitle, systemImage: "qrcode")
        } description: {
            Text(tooLargeMessage)
        }
    }

    private var failedState: some View {
        ContentUnavailableView {
            Label(failedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(failedMessage)
        }
    }

    private let qrSize: CGFloat = 250
    private let scanPrompt = String(localized: "Show this code to share the plan")
    private let tooLargeTitle = String(localized: "Plan too large for a QR code")
    private let tooLargeMessage = String(localized: "File sharing is coming in a future version.")
    private let failedTitle = String(localized: "Couldn't prepare the code")
    private let failedMessage = String(localized: "Try again in a moment.")
}
