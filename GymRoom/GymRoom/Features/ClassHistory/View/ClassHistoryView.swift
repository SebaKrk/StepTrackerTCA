//
//  ClassHistoryView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import AppDatabase
import ComposableArchitecture
import SharedModels
import SwiftUI

/// History tab — lista past sessions reverse-chrono. Tap row → nothing (subtask E
/// doda push do detail z wykresami). Empty state gdy brak sessions w bazie.
@ViewAction(for: ClassHistoryFeature.self)
struct ClassHistoryView: View {

    @Bindable var store: StoreOf<ClassHistoryFeature>

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(navigationTitle)
                .task { send(.viewDidAppear) }
                .navigationDestination(
                    item: $store.scope(state: \.detail, action: \.detail)
                ) { detailStore in
                    ClassHistoryDetailView(store: detailStore)
                }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .preferredColorScheme(.dark)
    }

    // MARK: - Private views (struktura)

    @ViewBuilder
    private var content: some View {
        switch store.viewState {
        case .loading:
            loadingState
        case .success:
            if store.sessions.isEmpty {
                emptyState
            } else {
                sessionsList
            }
        case .failed:
            failedState
        }
    }

    private var loadingState: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(emptyTitle, systemImage: "clock.arrow.circlepath")
        } description: {
            Text(emptyDescription)
        }
    }

    /// Failed state z retry button — re-emit `.viewDidAppear` resetuje
    /// viewState do `.loading` i ponawia fetch.
    private var failedState: some View {
        ContentUnavailableView {
            Label(failedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(failedDescription)
        } actions: {
            Button {
                send(.viewDidAppear)
            } label: {
                Label(retryTitle, systemImage: "arrow.clockwise")
            }
        }
    }

    private var sessionsList: some View {
        List(store.sessions, id: \.id) { session in
            sessionRowButton(for: session)
        }
        .listStyle(.insetGrouped)
    }

    private func sessionRowButton(for session: ClassSessionRecord) -> some View {
        Button {
            send(.sessionRowTapped(session))
        } label: {
            sessionRow(for: session)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            sessionDeleteButton(for: session)
            if session.endedAt == nil {
                sessionEndButton(for: session)
            }
        }
    }

    private func sessionDeleteButton(for session: ClassSessionRecord) -> some View {
        Button(role: .destructive) {
            send(.sessionDeleteTapped(session))
        } label: {
            Label(deleteLabel, systemImage: "trash")
        }
    }

    /// Force-end button — visible **tylko gdy `endedAt == nil`** (ongoing sesja).
    /// Recovery dla pre-existing bug C (WC end-flow gdy Watch unreachable).
    /// `.tint(.orange)` differentiates od destructive delete (czerwony).
    private func sessionEndButton(for session: ClassSessionRecord) -> some View {
        Button {
            send(.sessionEndTapped(session))
        } label: {
            Label(endLabel, systemImage: "stop.circle")
        }
        .tint(.orange)
    }

    private func sessionRow(for session: ClassSessionRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(session.className)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(dateLabel(for: session.startedAt))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(subtitleLabel(for: session))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(.rect)
        .padding(.vertical, 4)
    }

    // MARK: - Private content (implementacja)

    private var navigationTitle: String {
        String(localized: "History", bundle: .main)
    }

    private var emptyTitle: String {
        String(localized: "No past classes yet", bundle: .main)
    }

    private var emptyDescription: String {
        String(localized: "Run a class to see it here.", bundle: .main)
    }

    private var deleteLabel: String {
        String(localized: "Delete", bundle: .main)
    }

    private var endLabel: String {
        String(localized: "End", bundle: .main)
    }

    private var failedTitle: String {
        String(localized: "Loading failed", bundle: .main)
    }

    private var failedDescription: String {
        String(localized: "Couldn't load class history. Please try again.", bundle: .main)
    }

    private var retryTitle: String {
        String(localized: "Try again", bundle: .main)
    }

    /// "Today" / "Yesterday" / "17 cze" (locale-aware przez DateFormatter).
    /// Apple Reminders pattern.
    private func dateLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return String(localized: "Today", bundle: .main)
        }
        if calendar.isDateInYesterday(date) {
            return String(localized: "Yesterday", bundle: .main)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    /// "Sala 1 · 2m 24s"  lub  "Sala 1 · Ongoing" gdy `endedAt == nil`.
    private func subtitleLabel(for session: ClassSessionRecord) -> String {
        let duration = durationLabel(for: session)
        if session.location.isEmpty {
            return duration
        }
        return "\(session.location) · \(duration)"
    }

    /// Format duration jako "Xh Ym" / "Xm Ys" / "Xs" zależnie od długości. Jeśli
    /// `endedAt == nil` — "Ongoing" (klasa nie została zakończona, znany bug C).
    private func durationLabel(for session: ClassSessionRecord) -> String {
        guard let endedAt = session.endedAt else {
            return String(localized: "Ongoing", bundle: .main)
        }
        let seconds = Int(endedAt.timeIntervalSince(session.startedAt))
        return formattedDuration(seconds)
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }
}

#Preview("Empty") {
    ClassHistoryView(
        store: Store(initialState: ClassHistoryFeature.State(viewState: .success)) {
            ClassHistoryFeature()
        }
    )
}

#Preview("Loading") {
    ClassHistoryView(
        store: Store(initialState: ClassHistoryFeature.State(viewState: .loading)) {
            ClassHistoryFeature()
        }
    )
}

#Preview("Failed") {
    ClassHistoryView(
        store: Store(initialState: ClassHistoryFeature.State(viewState: .failed)) {
            ClassHistoryFeature()
        }
    )
}
