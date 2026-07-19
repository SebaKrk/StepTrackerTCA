//
//  ClassDetailView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Detail view klasy z metadata (name, location, scheduledAt) + Start class button
/// w prawym dolnym rogu (floating action). Future: Edit / Delete toolbar actions.
@ViewAction(for: ClassDetailFeature.self)
struct ClassDetailView: View {

    @Bindable var store: StoreOf<ClassDetailFeature>

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content
            startButton
                .padding(32)
        }
        .navigationTitle(store.gymClass.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { actionsMenu }
        .sheet(item: $store.scope(state: \.editSheet, action: \.editSheet)) { editStore in
            ClassCreationView(store: editStore)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .preferredColorScheme(.dark)
        .onAppear { send(.viewDidAppear) }
    }

    /// Ellipsis menu w prawym górnym rogu — struktura widoku (CO).
    /// Implementacja przycisków + label jako osobne `private var` poniżej (JAK).
    @ToolbarContentBuilder
    private var actionsMenu: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                editButton
                deleteButton
            } label: {
                menuLabel
            }
        }
    }

    private var editButton: some View {
        Button {
            send(.editTapped)
        } label: {
            Text(editLabel)
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            send(.deleteTapped)
        } label: {
            Label(deleteLabel, systemImage: "trash")
        }
    }

    private var menuLabel: some View {
        Image(systemName: "ellipsis")
//            .font(.title3.weight(.semibold))
    }

    // MARK: - Private views (struktura)

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                locationRow
                if let scheduledAt = store.gymClass.scheduledAt {
                    scheduledRow(scheduledAt)
                }
                athletesRow
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var locationRow: some View {
        metadataRow(label: locationLabel, value: store.gymClass.location)
    }

    /// Recurring classes show the NEXT occurrence (base date rolled forward weekly)
    /// plus a "weekly" tag, so the detail never gets stuck on a past base date.
    /// One-off classes show their single scheduled date as before.
    private func scheduledRow(_ date: Date) -> some View {
        metadataRow(
            label: store.gymClass.isRecurring ? nextClassLabel : scheduledLabel,
            value: store.gymClass.isRecurring ? recurringScheduleValue(base: date) : formattedDate(date)
        )
    }

    private func recurringScheduleValue(base: Date) -> String {
        let next = WeeklyRecurrence.nextOccurrence(of: base, notBefore: store.now)
        return "\(formattedDate(next)) · \(weeklyText)"
    }

    /// Capacity row — pokazuje `0/max` ratio. Pre-live zawsze `0` (klasa to template,
    /// real-time count w LiveClassView header'ze). Statyczny format `current/max`
    /// żeby trener od razu widział pojemność klasy.
    private var athletesRow: some View {
        metadataRow(label: athletesLabel, value: athletesValue)
    }

    private func metadataRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary)
        }
    }

    /// Floating Start class button w prawym dolnym rogu — manual Liquid Glass capsule
    /// z green tint (iOS 26 `.glassEffect()` material). Bardziej "natural" niż solid
    /// `.glassProminent` — depth + refraction Apple Liquid Glass design system.
    private var startButton: some View {
        Button {
            send(.startTapped)
        } label: {
            startButtonLabel
        }
        .buttonStyle(.plain)
    }

    private var startButtonLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "play.fill")
            Text(startTitle)
        }
        .font(.title3.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .capsule)
    }

    // MARK: - Private content (implementacja)

    private var locationLabel: String {
        String(localized: "Location", bundle: .main)
    }

    private var scheduledLabel: String {
        String(localized: "Scheduled", bundle: .main)
    }

    private var nextClassLabel: String {
        String(localized: "Next class", bundle: .main)
    }

    private var weeklyText: String {
        String(localized: "weekly", bundle: .main)
    }

    private var athletesLabel: String {
        String(localized: "Athletes", bundle: .main)
    }

    private var athletesValue: String {
        "0/\(store.gymClass.maxParticipants)"
    }

    private var startTitle: String {
        String(localized: "Start class", bundle: .main)
    }

    private var editLabel: String {
        String(localized: "Edit", bundle: .main)
    }

    private var deleteLabel: String {
        String(localized: "Delete", bundle: .main)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview("With schedule") {
    NavigationStack {
        ClassDetailView(
            store: Store(initialState: ClassDetailFeature.State(
                gymClass: GymClass(name: "Morning CrossFit", location: "Sala 1", scheduledAt: .now.addingTimeInterval(3600))
            )) {
                ClassDetailFeature()
            }
        )
    }
}

#Preview("No schedule") {
    NavigationStack {
        ClassDetailView(
            store: Store(initialState: ClassDetailFeature.State(
                gymClass: GymClass(name: "Anytime WOD", location: "Sala 2")
            )) {
                ClassDetailFeature()
            }
        )
    }
}
