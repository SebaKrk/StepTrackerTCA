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
                    if store.canDownload {
                        windowNote
                    }
                }
                .padding()
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .background(backgroundGradient)
            .navigationTitle(store.plan.session.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    closeButton
                }
                if store.canDownload {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        planActionButton
                    }
                }
            }
            .sheet(
                item: $store.scope(state: \.configuration, action: \.configuration)
            ) { configurationStore in
                ConfigurationView(store: configurationStore)
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

    // Last line of the scroll, under the plan the rule applies to.
    private var windowNote: some View {
        Text(String(localized: "Your group result counts the first \(store.plan.sessionMinutes) minutes from the start. Start when you begin the plan, warm-up included."))
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    // One slot in the bar: download first, then the same place offers the start.
    @ViewBuilder
    private var planActionButton: some View {
        if store.isDownloaded {
            startWorkoutButton
        } else {
            downloadButton
        }
    }

    // Same shape as "Start Workout" in plan detail: the activity's icon, bottom-right.
    private var startWorkoutButton: some View {
        Button {
            send(.startWorkoutTapped)
        } label: {
            Label(startWorkoutTitle, systemImage: activityIconName)
                .fontWeight(.semibold)
        }
    }

    private var downloadButton: some View {
        Button {
            send(.downloadTapped)
        } label: {
            if store.isDownloading {
                ProgressView()
            } else {
                Label(downloadTitle, systemImage: "arrow.down.circle")
                    .fontWeight(.semibold)
            }
        }
        .disabled(store.isDownloading)
    }

    private var activityIconName: String {
        store.plan.session.activity.iconName.replacingOccurrences(of: ".circle.fill", with: "")
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
    private let startWorkoutTitle = String(localized: "Start Workout")
    private let closeTitle = String(localized: "Close")
}
