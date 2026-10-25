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

    var body: some View {
        NavigationStack {
            segmentContent
                .safeAreaBar(edge: .top) {
                    segmentPicker
                }
                .background(backgroundGradient)
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        createGroupButton
                    }
                }
                .sheet(
                    item: $store.scope(state: \.destination?.createGroup, action: \.destination.createGroup)
                ) { createGroupStore in
                    CreateGroupView(store: createGroupStore)
                        .presentationDetents([.medium])
                }
        }
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
        if store.groups.isEmpty {
            noGroupsView
        } else {
            groupsList
        }
    }

    private var groupsList: some View {
        List {
            ForEach(store.groups) { group in
                groupRow(group)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Group Row (structure)

    private func groupRow(_ group: TeamGroup) -> some View {
        HStack(spacing: 12) {
            groupBadge(group)
            groupTitles(group)
            Spacer()
        }
        .padding(.vertical, 6)
    }

    // MARK: - Implementation

    private var segmentPicker: some View {
        Picker(segmentPickerTitle, selection: $store.segment.sending(\.view.segmentChanged)) {
            ForEach(TeamSegment.allCases) { segment in
                Text(segment.title)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .padding([.leading, .trailing], 6)
        .padding(.bottom, 12)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [store.color.opacity(0.25), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func groupBadge(_ group: TeamGroup) -> some View {
        Text(group.name.prefix(2).uppercased())
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(store.color.gradient, in: .rect(cornerRadius: 12))
    }

    private func groupTitles(_ group: TeamGroup) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(group.name)
                .font(.headline)
            if group.ownerUid == store.myUid {
                Text(ownGroupCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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

    private var createGroupButton: some View {
        Button {
            send(.createGroupTapped)
        } label: {
            Label(createGroupTitle, systemImage: "plus")
        }
        .disabled(store.myUid == nil)
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

    private let navigationTitle = String(localized: "Team")
    private let segmentPickerTitle = String(localized: "Team segment")
    private let ownGroupCaption = String(localized: "Your group")
    private let noGroupsTitle = String(localized: "No Groups Yet")
    private let noGroupsMessage = String(localized: "Create a group or scan an invite from a friend to train on the same plan and compare results.")
    private let publicTitle = String(localized: "Public Groups Coming Soon")
    private let publicMessage = String(localized: "For now, join private groups with a QR code from a friend.")
    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to load your groups. Check your connection and try again.")
    private let retryTitle = String(localized: "Try Again")
    private let createGroupTitle = String(localized: "Create Group")
}
