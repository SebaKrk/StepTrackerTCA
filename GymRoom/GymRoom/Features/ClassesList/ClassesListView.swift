//
//  ClassesListView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Classes tab — schedule template list. NavigationStack z listą klas, toolbar `+` button
/// dla dodania nowej klasy, push do ClassDetail, fullScreenCover dla LiveClass.
@ViewAction(for: ClassesListFeature.self)
struct ClassesListView: View {

    @Bindable var store: StoreOf<ClassesListFeature>

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(navigationTitle)
                .toolbar { addButton }
                .navigationDestination(
                    item: $store.scope(state: \.destination?.detail, action: \.destination.detail)
                ) { detailStore in
                    ClassDetailView(store: detailStore)
                }
                .task { send(.viewDidAppear) }
        }
        .preferredColorScheme(.dark)
        .sheet(
            item: $store.scope(state: \.destination?.create, action: \.destination.create)
        ) { createStore in
            ClassCreationView(store: createStore)
        }
        .fullScreenCover(
            item: $store.scope(state: \.liveClass, action: \.liveClass)
        ) { liveStore in
            LiveClassView(store: liveStore)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Private views (struktura)

    @ViewBuilder
    private var content: some View {
        switch store.viewState {
        case .loading:
            loadingState
        case .success:
            if store.classes.isEmpty {
                emptyState
            } else {
                classesList
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
            Label(emptyTitle, systemImage: "figure.cross.training")
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

    private var classesList: some View {
        List {
            ForEach(scheduledGroups, id: \.day) { group in
                Section {
                    ForEach(group.classes) { gymClass in
                        classRowButton(for: gymClass)
                    }
                } header: {
                    dayHeader(for: group.day)
                }
            }
            if !undatedClasses.isEmpty {
                Section {
                    ForEach(undatedClasses) { gymClass in
                        classRowButton(for: gymClass)
                    }
                } header: {
                    Text(undatedHeader)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// Section header: dzień tygodnia leading + data jako footnote trailing.
    /// Style 1:1 z Apple Reminders/Calendar (np. "Środa" + "17 czerwca").
    private func dayHeader(for day: Date) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(weekday(for: day))
            Spacer()
            Text(dayAndMonth(for: day))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func classRowButton(for gymClass: GymClass) -> some View {
        Button {
            send(.classRowTapped(gymClass))
        } label: {
            classRow(for: gymClass)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                send(.classDeleteTapped(gymClass))
            } label: {
                Label(deleteTitle, systemImage: "trash")
            }
        }
    }

    /// Row layout: title HStack (name leading + time trailing) + subtitle (location).
    private func classRow(for gymClass: GymClass) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            titleRow(for: gymClass)
            Text(gymClass.location)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(.rect)
        .padding(.vertical, 4)
    }

    private func titleRow(for gymClass: GymClass) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(gymClass.name)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            if let scheduledAt = gymClass.scheduledAt {
                Text(timeFormatted(scheduledAt))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Grouping logic

    /// Klasy z `scheduledAt`, pogrupowane per startOfDay, sortowane chronologicznie.
    private var scheduledGroups: [(day: Date, classes: [GymClass])] {
        let calendar = Calendar.current
        let scheduled = store.classes.filter { $0.scheduledAt != nil }
        let grouped = Dictionary(grouping: scheduled) { gymClass in
            calendar.startOfDay(for: gymClass.scheduledAt!)
        }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (day: $0.key, classes: $0.value.sorted { $0.scheduledAt! < $1.scheduledAt! }) }
    }

    /// Klasy bez daty — osobna sekcja "Bez daty" na końcu.
    private var undatedClasses: [GymClass] {
        store.classes.filter { $0.scheduledAt == nil }
    }

    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                send(.addClassTapped)
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
            }
        }
    }

    // MARK: - Private content (implementacja)

    private var navigationTitle: String {
        String(localized: "Classes", bundle: .main)
    }

    private var emptyTitle: String {
        String(localized: "No classes yet", bundle: .main)
    }

    private var emptyDescription: String {
        String(localized: "Tap + to create your first class.", bundle: .main)
    }

    private var deleteTitle: String {
        String(localized: "Delete", bundle: .main)
    }

    private var undatedHeader: String {
        String(localized: "Without date", bundle: .main)
    }

    private var failedTitle: String {
        String(localized: "Loading failed", bundle: .main)
    }

    private var failedDescription: String {
        String(localized: "Couldn't load classes. Please try again.", bundle: .main)
    }

    private var retryTitle: String {
        String(localized: "Try again", bundle: .main)
    }

    /// "Środa" / "Wednesday" — sam dzień tygodnia, capitalized (lokalizacja przez current locale).
    private func weekday(for day: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: day).capitalized
    }

    /// "17 czerwca" / "17 June" — dzień + miesiąc bez roku (header sekcji już daje kontekst tygodnia).
    private func dayAndMonth(for day: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: day)
    }

    /// "18:00" — pure time in HH:mm.
    private func timeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview("Empty") {
    ClassesListView(
        store: Store(initialState: ClassesListFeature.State(viewState: .success)) {
            ClassesListFeature()
        }
    )
}

#Preview("With classes") {
    ClassesListView(
        store: Store(initialState: ClassesListFeature.State(
            viewState: .success,
            classes: [
                GymClass(name: "Morning CrossFit", location: "Sala 1", scheduledAt: .now.addingTimeInterval(3600)),
                GymClass(name: "Evening WOD", location: "Sala 2"),
                GymClass(name: "HIIT Tuesday", location: "Sala 1", scheduledAt: .now.addingTimeInterval(86400))
            ]
        )) {
            ClassesListFeature()
        }
    )
}

#Preview("Loading") {
    ClassesListView(
        store: Store(initialState: ClassesListFeature.State(viewState: .loading)) {
            ClassesListFeature()
        }
    )
}

#Preview("Failed") {
    ClassesListView(
        store: Store(initialState: ClassesListFeature.State(viewState: .failed)) {
            ClassesListFeature()
        }
    )
}
