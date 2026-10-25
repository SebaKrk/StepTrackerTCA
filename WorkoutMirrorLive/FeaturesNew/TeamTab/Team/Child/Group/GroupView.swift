//
//  GroupView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: GroupFeature.self)
struct GroupView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<GroupFeature>

    // MARK: - Body (structure)

    var body: some View {
        content
            .navigationTitle(store.group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    inviteButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    publishPlanButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    moreMenu
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .sheet(
                item: $store.scope(state: \.destination?.invite, action: \.destination.invite)
            ) { inviteStore in
                InviteView(store: inviteStore)
            }
            .sheet(
                item: $store.scope(state: \.destination?.publishPlan, action: \.destination.publishPlan)
            ) { publishStore in
                PublishPlanView(store: publishStore)
            }
            .sheet(
                item: $store.scope(state: \.destination?.planPreview, action: \.destination.planPreview)
            ) { previewStore in
                PlanPreviewView(store: previewStore)
            }
            .onAppear {
                send(.viewDidAppear)
            }
    }

    // MARK: - Content (structure)

    @ViewBuilder
    private var content: some View {
        switch store.viewState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .success:
            membersList
        case .failed:
            failedView
        }
    }

    private var membersList: some View {
        List {
            todaySection
            Section {
                ForEach(store.members) { member in
                    memberRow(member)
                }
            } header: {
                Text(membersHeader)
            }
        }
    }

    private var todaySection: some View {
        Section {
            todayContent
        } header: {
            Text(todayHeader)
        }
    }

    @ViewBuilder
    private var todayContent: some View {
        switch store.todayPlanState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
        case .failed:
            Text(todayFailedText)
                .foregroundStyle(.secondary)
        case .success:
            if let plan = store.todayPlan {
                todayPlanCard(plan)
            } else {
                noTodayPlanText
            }
        }
    }

    private func todayPlanCard(_ plan: TeamPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            todayPlanTitles(plan)
            todayPlanBlocks(plan)
            todayPlanButtons
        }
        .padding(.vertical, 4)
    }

    // MARK: - Implementation

    private func todayPlanTitles(_ plan: TeamPlan) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(plan.session.title)
                .font(.headline)
            Text(String(localized: "By \(plan.authorName) · \(plan.sessionMinutes) min"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func todayPlanBlocks(_ plan: TeamPlan) -> some View {
        Text(plan.session.workouts.map(\.name).joined(separator: " · "))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
    }

    private var todayPlanButtons: some View {
        HStack(spacing: 10) {
            previewTodayPlanButton
            downloadTodayPlanButton
        }
    }

    private var previewTodayPlanButton: some View {
        Button {
            send(.todayPlanPreviewTapped)
        } label: {
            Text(previewTitle)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private var downloadTodayPlanButton: some View {
        Button {
            send(.todayPlanDownloadTapped)
        } label: {
            Group {
                if store.isDownloadingTodayPlan {
                    ProgressView()
                } else if store.isTodayPlanDownloaded {
                    Label(downloadedTitle, systemImage: "checkmark")
                } else {
                    Text(downloadTitle)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.isTodayPlanDownloaded || store.isDownloadingTodayPlan)
    }

    private var noTodayPlanText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(noTodayPlanTitle)
            Text(noTodayPlanHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func memberRow(_ member: TeamMember) -> some View {
        HStack(spacing: 12) {
            memberInitials(member)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName)
                    .font(.body)
                memberCaption(member)
            }
        }
    }

    private func memberInitials(_ member: TeamMember) -> some View {
        Text(member.displayName.prefix(2).uppercased())
            .font(.caption.weight(.bold))
            .frame(width: 34, height: 34)
            .background(.fill.tertiary, in: .circle)
    }

    @ViewBuilder
    private func memberCaption(_ member: TeamMember) -> some View {
        let labels = [
            member.uid == store.group.ownerUid ? ownerLabel : nil,
            member.uid == store.myUid ? youLabel : nil,
        ].compactMap { $0 }
        if !labels.isEmpty {
            Text(labels.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var inviteButton: some View {
        Button {
            send(.inviteTapped)
        } label: {
            Label(inviteTitle, systemImage: "qrcode")
        }
    }

    private var publishPlanButton: some View {
        Button {
            send(.publishPlanTapped)
        } label: {
            Label(publishPlanTitle, systemImage: "plus")
        }
    }

    private var moreMenu: some View {
        Menu {
            leaveButton
        } label: {
            Label(moreTitle, systemImage: "ellipsis")
        }
        .disabled(store.isLeaving)
    }

    private var leaveButton: some View {
        Button(role: .destructive) {
            send(.leaveTapped)
        } label: {
            Label(leaveTitle, systemImage: "rectangle.portrait.and.arrow.right")
        }
    }

    private var failedView: some View {
        ContentUnavailableView {
            Label(failedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(failedMessage)
        }
    }

    // MARK: - Text

    private let membersHeader = String(localized: "Members")
    private let todayHeader = String(localized: "Today's Plan")
    private let todayFailedText = String(localized: "Couldn't load today's plan.")
    private let noTodayPlanTitle = String(localized: "No plan for today yet")
    private let noTodayPlanHint = String(localized: "Tap + to publish one from your Plans.")
    private let previewTitle = String(localized: "Preview")
    private let downloadTitle = String(localized: "Download to Plans")
    private let downloadedTitle = String(localized: "In Your Plans")
    private let inviteTitle = String(localized: "Invite")
    private let publishPlanTitle = String(localized: "Publish Today's Plan")
    private let ownerLabel = String(localized: "Owner")
    private let youLabel = String(localized: "You")
    private let moreTitle = String(localized: "More")
    private let leaveTitle = String(localized: "Leave Group")
    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to load the group members. Check your connection and try again.")
}
