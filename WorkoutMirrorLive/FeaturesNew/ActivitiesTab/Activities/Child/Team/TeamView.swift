//
//  TeamView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: TeamFeature.self)
struct TeamView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<TeamFeature>

    // MARK: - Body (structure)

    // Lives inside the Activities navigation stack — no stack, title or background of its own.
    var body: some View {
        segmentContent
            .tint(store.color)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    segmentFilterMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    addMenu
                }
            }
            .sheet(
                item: $store.scope(state: \.destination?.createGroup, action: \.destination.createGroup)
            ) { createGroupStore in
                CreateGroupView(store: createGroupStore)
                    .presentationDetents([.medium])
            }
            .navigationDestination(
                item: $store.scope(state: \.destination?.group, action: \.destination.group)
            ) { groupStore in
                GroupView(store: groupStore)
            }
            .fullScreenCover(
                item: $store.scope(state: \.destination?.invitationPreview, action: \.destination.invitationPreview)
            ) { previewStore in
                InvitationPreviewView(store: previewStore)
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .onAppear {
                send(.viewDidAppear)
            }
    }

    // MARK: - Segments (structure)

    @ViewBuilder
    private var segmentContent: some View {
        switch store.segment {
        case .private:
            privateContent
        case .public:
            publicGroupsComingSoonView
        }
    }

    @ViewBuilder
    private var privateContent: some View {
        switch store.viewState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .success:
            groupsListOrEmpty
        case .failed:
            failedView
        }
    }

    @ViewBuilder
    private var groupsListOrEmpty: some View {
        if store.groups.isEmpty && store.pendingInvitations.isEmpty {
            noGroupsView
        } else {
            groupsList
        }
    }

    // Cards in a plain List, like the activity list: drag to reorder, swipe to leave or delete.
    private var groupsList: some View {
        List {
            Group {
                invitationsSection
                groupsSection
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            await send(.refreshPulled).finish()
        }
    }

    @ViewBuilder
    private var invitationsSection: some View {
        if !store.pendingInvitations.isEmpty {
            sectionHeader(invitationsHeader)
            ForEach(store.pendingInvitations) { invitation in
                TeamInvitationRow(
                    invitation: invitation,
                    isResponding: store.respondingInvitationIds.contains(invitation.id),
                    onJoin: { send(.invitationJoinTapped(invitation)) },
                    onDecline: { send(.invitationDeclineTapped(invitation)) }
                )
            }
        }
    }

    @ViewBuilder
    private var groupsSection: some View {
        if !store.groups.isEmpty {
            sectionHeader(groupsHeader)
                .padding(.top, store.pendingInvitations.isEmpty ? 0 : 8)
            ForEach(store.orderedGroups) { group in
                TeamGroupCard(
                    group: group,
                    isMine: group.ownerUid == store.myUid,
                    today: store.today,
                    myEntry: store.myEntries[group.id],
                    onTap: { send(.groupTapped(group)) }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    groupSwipeButton(group)
                }
                .disabled(store.workingGroupIds.contains(group.id))
            }
            .onMove { source, destination in
                send(.groupsMoved(from: source, to: destination), animation: .snappy)
            }
        }
    }

    // MARK: - Implementation

    // Swipe on a card: the owner deletes, everyone else leaves — both confirmed by an alert.
    @ViewBuilder
    private func groupSwipeButton(_ group: TeamGroup) -> some View {
        if group.ownerUid == store.myUid {
            Button {
                send(.groupDeleteTapped(group))
            } label: {
                Label(deleteGroupTitle, systemImage: "trash")
            }
            .tint(.red)
        } else {
            Button {
                send(.groupLeaveTapped(group))
            } label: {
                Label(leaveGroupTitle, systemImage: "rectangle.portrait.and.arrow.right")
            }
            .tint(.red)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private var segmentFilterMenu: some View {
        Menu {
            Picker(segmentPickerTitle, selection: $store.segment.sending(\.view.segmentChanged)) {
                ForEach(TeamSegment.allCases) { segment in
                    Text(segment.title)
                        .tag(segment)
                }
            }
        } label: {
            Label(segmentPickerTitle, systemImage: segmentFilterIcon)
        }
    }

    // Filled while a non-default filter is on, like the system filter buttons.
    private var segmentFilterIcon: String {
        store.segment == .private ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
    }

    private var noGroupsView: some View {
        ContentUnavailableView {
            Label(noGroupsTitle, systemImage: "person.3")
        } description: {
            Text(noGroupsMessage)
        } actions: {
            emptyCreateGroupButton
        }
    }

    // Both ways into a group share one "+", so the bar keeps two items like the other segments.
    private var addMenu: some View {
        Menu {
            createGroupButton
            scanInviteButton
        } label: {
            Label(addTitle, systemImage: "plus")
        }
        .disabled(store.myUid == nil)
    }

    private var scanInviteButton: some View {
        Button {
            send(.scanInviteTapped)
        } label: {
            Label(scanInviteTitle, systemImage: "qrcode.viewfinder")
        }
    }

    private var createGroupButton: some View {
        Button {
            send(.createGroupTapped)
        } label: {
            Label(createGroupTitle, systemImage: "person.3")
        }
    }

    private var emptyCreateGroupButton: some View {
        Button {
            send(.createGroupTapped)
        } label: {
            Label(createGroupTitle, systemImage: "plus")
        }
    }

    private var publicGroupsComingSoonView: some View {
        ContentUnavailableView {
            Label(publicTitle, systemImage: "globe")
        } description: {
            Text(publicMessage)
        }
    }

    private var failedView: some View {
        ContentUnavailableView {
            Label(failedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(failedMessage)
        } actions: {
            retryButton
        }
    }

    private var retryButton: some View {
        Button {
            send(.retryTapped)
        } label: {
            Text(retryTitle)
        }
    }

    // MARK: - Text

    private let segmentPickerTitle = String(localized: "Groups")
    private let noGroupsTitle = String(localized: "No Groups Yet")
    private let noGroupsMessage = String(localized: "Create a group or scan an invite from a friend to train on the same plan and compare results.")
    private let publicTitle = String(localized: "Public Groups Coming Soon")
    private let publicMessage = String(localized: "For now, join private groups with a QR code from a friend.")
    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to load your groups. Check your connection and try again.")
    private let retryTitle = String(localized: "Try Again")
    private let addTitle = String(localized: "Add")
    private let createGroupTitle = String(localized: "Create Group")
    private let scanInviteTitle = String(localized: "Scan Invite")
    private let invitationsHeader = String(localized: "Invitations")
    private let groupsHeader = String(localized: "My Groups")
    private let deleteGroupTitle = String(localized: "Delete Group")
    private let leaveGroupTitle = String(localized: "Leave Group")
}
