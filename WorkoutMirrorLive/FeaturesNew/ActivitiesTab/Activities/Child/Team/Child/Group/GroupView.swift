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

    // Fits ContentUnavailableView with its link, so a day with or without a plan keeps the card's height.
    @ScaledMetric(relativeTo: .body) private var planMinHeight: CGFloat = 220

    // MARK: - Body (structure)

    var body: some View {
        content
            .background(backgroundGradient)
            .tint(store.color)
            .navigationTitle(store.group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            groupCards
        case .failed:
            failedView
        }
    }

    private var groupCards: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                dayNavigatorCard
                sectionHeader(dayPlanHeader)
                    .padding(.top, 8)
                dayPlanCard
                sectionHeader(leaderboardHeader)
                    .padding(.top, 8)
                leaderboardCard
                sectionHeader(membersHeader)
                    .padding(.top, 8)
                membersCard
            }
            .padding()
        }
    }

    private var dayNavigatorCard: some View {
        GroupBox {
            DayNavigatorView(
                weekDays: store.weekDays,
                selectedDay: store.selectedDay,
                today: store.today,
                daysWithPlan: store.daysWithPlan,
                onPrevious: { send(.previousDayTapped) },
                onNext: { send(.nextDayTapped) },
                onSelect: { send(.daySelected($0)) }
            )
        }
        .styledGroupBox()
    }

    private var dayPlanCard: some View {
        GroupBox {
            dayPlanContent
                .frame(maxWidth: .infinity, minHeight: planMinHeight, alignment: .topLeading)
        }
        .styledGroupBox()
    }

    private var leaderboardCard: some View {
        GroupBox {
            GroupLeaderboardView(store: store.scope(state: \.leaderboard, action: \.leaderboard))
        }
        .styledGroupBox()
    }

    private var membersCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(store.members) { member in
                    memberRow(member)
                    if member.id != store.members.last?.id {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .styledGroupBox()
    }

    @ViewBuilder
    private var dayPlanContent: some View {
        switch store.dayPlanState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
        case .failed:
            emptyPlanState(
                title: failedTitle,
                systemImage: "exclamationmark.triangle",
                description: dayPlanFailedText,
                showsAddPlan: false
            )
        case .success:
            if let plan = store.dayPlan {
                dayPlanSummary(plan)
            } else {
                noDayPlanText
            }
        }
    }

    private func dayPlanSummary(_ plan: TeamPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            dayPlanPreviewButton(plan)
            if store.isSelectedDayToday && !store.isDayPlanDownloaded {
                downloadDayPlanButton
            }
        }
    }

    // The whole plan summary opens the preview, like plan cards elsewhere.
    private func dayPlanPreviewButton(_ plan: TeamPlan) -> some View {
        Button {
            send(.dayPlanPreviewTapped)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                dayPlanHeader(plan)
                Divider()
                PlanSummaryDetails(session: plan.session)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func dayPlanHeader(_ plan: TeamPlan) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // The title keeps its width; the badge shrinks to an icon when space runs out.
            dayPlanTitles(plan)
                .layoutPriority(1)
            Spacer(minLength: 0)
            if store.isDayPlanDownloaded {
                InYourPlansBadge()
            }
            chevron
        }
    }

    // MARK: - Implementation

    private func dayPlanTitles(_ plan: TeamPlan) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(plan.session.title)
                .font(.headline)
            Text(String(localized: "By \(plan.authorName) · \(plan.sessionMinutes) min"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
            .padding(.top, 4)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }


    private var downloadDayPlanButton: some View {
        Button {
            send(.dayPlanDownloadTapped)
        } label: {
            Group {
                if store.isDownloadingDayPlan {
                    ProgressView()
                } else {
                    Label(downloadTitle, systemImage: "arrow.down.circle")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.isDownloadingDayPlan)
    }

    private var noDayPlanText: some View {
        emptyPlanState(
            title: noPlanTitle,
            systemImage: store.isSelectedDayToday ? "calendar.badge.plus" : "calendar",
            description: store.isSelectedDayToday ? noTodayPlanHint : noPastPlanText,
            showsAddPlan: store.isSelectedDayToday
        )
    }

    private func emptyPlanState(title: String, systemImage: String, description: String, showsAddPlan: Bool) -> some View {
        // Smaller than the full-screen default — it sits inside a card.
        ContentUnavailableView {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                Image(systemName: systemImage)
            }
            .imageScale(.small)
        } description: {
            Text(description)
                .font(.footnote)
        } actions: {
            if showsAddPlan {
                emptyPublishPlanButton
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyPublishPlanButton: some View {
        Button {
            send(.publishPlanTapped)
        } label: {
            Label(addPlanTitle, systemImage: "plus")
                .font(.footnote.weight(.semibold))
        }
        .buttonStyle(.borderless)
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

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [store.color.opacity(0.25), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
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
        .disabled(!store.isSelectedDayToday)
    }

    private var moreMenu: some View {
        Menu {
            inviteButton
            Divider()
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
    private let dayPlanHeader = String(localized: "Plan of the Day")
    private let leaderboardHeader = String(localized: "Leaderboard")
    private let dayPlanFailedText = String(localized: "Couldn't load the plan.")
    private let noPlanTitle = String(localized: "No Plan Yet")
    private let noTodayPlanHint = String(localized: "Pick a plan from the list and add it for the whole group.")
    private let addPlanTitle = String(localized: "Add Plan")
    private let noPastPlanText = String(localized: "No plan was published that day.")
    private let downloadTitle = String(localized: "Download to Plans")
    private let inviteTitle = String(localized: "Invite")
    private let publishPlanTitle = String(localized: "Publish Today's Plan")
    private let ownerLabel = String(localized: "Owner")
    private let youLabel = String(localized: "You")
    private let moreTitle = String(localized: "More")
    private let leaveTitle = String(localized: "Leave Group")
    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to load the group members. Check your connection and try again.")
}
