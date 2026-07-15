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
            ForEach(weekdayOrder, id: \.self) { weekday in
                Section {
                    weekdaySection(for: weekday)
                } header: {
                    Text(weekdayName(weekday))
                }
            }
            if !oneTimeClasses.isEmpty {
                // Divider bez nazwy sekcji — jednorazowe zajęcia poniżej grafiku tygodnia.
                Section {
                    ForEach(oneTimeClasses) { gymClass in
                        classRowButton(for: gymClass)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// Wiersze zajęć cyklicznych w danym dniu tygodnia — lub placeholder "Brak zajęć"
    /// gdy dzień jest pusty (grafik tygodnia zawsze pokazuje wszystkie 7 dni).
    @ViewBuilder
    private func weekdaySection(for weekday: Int) -> some View {
        let classes = recurringClasses(on: weekday)
        if classes.isEmpty {
            noClassesRow
        } else {
            ForEach(classes) { gymClass in
                classRowButton(for: gymClass)
            }
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
            scheduleTrailing(for: gymClass)
        }
    }

    /// Recurring rows show only the time — their weekday is the section header.
    /// One-off rows carry the full date + time because they sit under the unnamed
    /// divider with no day header to give context.
    @ViewBuilder
    private func scheduleTrailing(for gymClass: GymClass) -> some View {
        if let scheduledAt = gymClass.scheduledAt {
            Text(gymClass.isRecurring ? timeFormatted(scheduledAt) : oneTimeSchedule(scheduledAt))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Grouping logic

    /// Kolejność dni tygodnia Pon→Ndz (Calendar `.weekday`: Ndz=1 … Sob=7).
    private var weekdayOrder: [Int] { [2, 3, 4, 5, 6, 7, 1] }

    /// Zajęcia cykliczne przypadające na dany dzień tygodnia (wg `scheduledAt`),
    /// sortowane po porze dnia.
    private func recurringClasses(on weekday: Int) -> [GymClass] {
        store.classes
            .filter {
                guard $0.isRecurring, let date = $0.scheduledAt else { return false }
                return Calendar.current.component(.weekday, from: date) == weekday
            }
            .sorted { timeOfDayMinutes(for: $0) < timeOfDayMinutes(for: $1) }
    }

    /// Zajęcia jednorazowe (nie-cykliczne) — z datą chronologicznie, bez daty na
    /// końcu. Lądują pod dividerem, poniżej grafiku tygodnia.
    private var oneTimeClasses: [GymClass] {
        store.classes
            .filter { !$0.isRecurring }
            .sorted { lhs, rhs in
                switch (lhs.scheduledAt, rhs.scheduledAt) {
                case let (left?, right?): return left < right
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return lhs.createdAt < rhs.createdAt
                }
            }
    }

    /// Minuty od północy — sortowanie zajęć w obrębie jednego dnia po godzinie
    /// (data bazowa bywa z różnych tygodni, liczy się tylko pora dnia).
    private func timeOfDayMinutes(for gymClass: GymClass) -> Int {
        guard let date = gymClass.scheduledAt else { return 0 }
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private var noClassesRow: some View {
        Text(noClassesText)
            .font(.subheadline)
            .foregroundStyle(.secondary)
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

    private var noClassesText: String {
        String(localized: "No classes", bundle: .main)
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

    /// "Poniedziałek" / "Monday" — nazwa dnia tygodnia (Calendar `.weekday`: Ndz=1 … Sob=7),
    /// capitalized, lokalizowana przez current locale.
    private func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.standaloneWeekdaySymbols // index 0 = Sunday
        let index = (weekday - 1) % symbols.count
        return symbols[index].capitalized
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

    /// "22 czerwca 19:30" — pełny termin dla zajęć jednorazowych pod dividerem
    /// (brak nagłówka dnia, więc wiersz niesie datę i godzinę).
    private func oneTimeSchedule(_ date: Date) -> String {
        "\(dayAndMonth(for: date)) \(timeFormatted(date))"
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
