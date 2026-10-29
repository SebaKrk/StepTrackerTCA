//
//  PlanPreviewView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: PlanPreviewFeature.self)
struct PlanPreviewView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<PlanPreviewFeature>

    // MARK: - Body (structure)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    authorCard
                    planDetail
                }
                .padding()
            }
            .safeAreaBar(edge: .bottom) {
                if store.canDownload {
                    downloadBar
                }
            }
            .background(backgroundGradient)
            .navigationTitle(store.plan.session.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    closeButton
                }
            }
        }
        .tint(store.color)
    }

    // MARK: - Implementation

    private var authorCard: some View {
        GroupBox {
            HStack(spacing: 8) {
                authorLabel
                Spacer()
                if store.isDownloaded {
                    InYourPlansBadge()
                }
            }
        }
        .styledGroupBox()
    }

    private var authorLabel: some View {
        Text(String(localized: "Published by \(store.plan.authorName) · \(store.plan.sessionMinutes) min"))
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    // Same component as PlanDetail and the QR import — one way to read a plan.
    private var planDetail: some View {
        WorkoutDetailContent(
            session: store.plan.session,
            isWarmupExpanded: $store.isWarmupExpanded,
            isCooldownExpanded: $store.isCooldownExpanded
        )
    }

    private var downloadBar: some View {
        VStack(spacing: 8) {
            if let message = store.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            if !store.isDownloaded {
                downloadButton
            }
            Text(String(localized: "Your group result counts the first \(store.plan.sessionMinutes) minutes from the start. Start when you begin the plan, warm-up included."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var downloadButton: some View {
        Button {
            send(.downloadTapped)
        } label: {
            Group {
                if store.isDownloading {
                    ProgressView()
                } else {
                    Label(downloadTitle, systemImage: "arrow.down.circle")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(store.isDownloading)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [store.color.opacity(0.25), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var closeButton: some View {
        Button {
            send(.closeTapped)
        } label: {
            Text(closeTitle)
        }
    }

    // MARK: - Text

    private let downloadTitle = String(localized: "Download to Plans")
    private let closeTitle = String(localized: "Close")
}
