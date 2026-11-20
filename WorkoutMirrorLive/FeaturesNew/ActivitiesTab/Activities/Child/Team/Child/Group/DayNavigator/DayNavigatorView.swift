//
//  DayNavigatorView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/10/2026.
//

import SwiftUI

/// Day switcher of the group screen: the week strip in a card, then glass arrows around the selected day.
struct DayNavigatorView: View {

    // MARK: - Properties

    let weekDays: [GroupDay]
    let selectedDay: String
    let today: String
    let daysWithPlan: Set<String>
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSelect: (String) -> Void

    // MARK: - Body (structure)

    var body: some View {
        // Week first as context, then the chosen day right above the content it shows.
        VStack(spacing: 12) {
            weekStripCard
            header
        }
    }

    // Floats above the content like the title bar in Photos: arrows and the day share one glass container.
    private var header: some View {
        GlassEffectContainer(spacing: 8) {
            HStack {
                previousButton
                Spacer(minLength: 8)
                titles
                Spacer(minLength: 8)
                nextButton
            }
        }
        .tint(.primary)
    }

    private var weekStripCard: some View {
        GroupBox {
            weekStrip
        }
        .styledGroupBox()
    }

    private var weekStrip: some View {
        HStack(spacing: 4) {
            ForEach(weekDays) { day in
                dayButton(day)
            }
        }
    }

    // MARK: - Implementation

    private var titles: some View {
        VStack(spacing: 0) {
            Text(weekdayTitle)
                .font(.headline)
            Text(dateSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .lineLimit(1)
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
    }

    private var previousButton: some View {
        Button(action: onPrevious) {
            Label(previousTitle, systemImage: "chevron.left")
                .labelStyle(.iconOnly)
                .font(.title3.weight(.semibold))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }

    private var nextButton: some View {
        Button(action: onNext) {
            Label(nextTitle, systemImage: "chevron.right")
                .labelStyle(.iconOnly)
                .font(.title3.weight(.semibold))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .disabled(selectedDay >= today)
    }

    private func dayButton(_ day: GroupDay) -> some View {
        let isSelected = day.id == selectedDay
        return Button {
            onSelect(day.id)
        } label: {
            VStack(spacing: 4) {
                Text(day.date.formatted(.dateTime.weekday(.short)).capitalized)
                    .font(.footnote.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                planDot(isVisible: daysWithPlan.contains(day.id))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? AnyShapeStyle(.fill.tertiary) : AnyShapeStyle(.clear), in: .rect(cornerRadius: 10))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // Future days stay in the strip so it keeps seven columns.
        .disabled(day.id > today)
        .opacity(day.id > today ? 0.4 : 1)
    }

    private func planDot(isVisible: Bool) -> some View {
        Circle()
            .fill(.tint)
            .frame(width: 5, height: 5)
            .opacity(isVisible ? 1 : 0)
    }

    private var selectedDate: Date? {
        weekDays.first { $0.id == selectedDay }?.date
    }

    private var weekdayTitle: String {
        selectedDate?.formatted(.dateTime.weekday(.wide)).capitalized ?? ""
    }

    private var dateSubtitle: String {
        guard let selectedDate else { return "" }
        let date = selectedDate.formatted(.dateTime.day(.twoDigits).month(.twoDigits))
        return selectedDay == today ? "\(date) · \(todayLabel)" : date
    }

    // MARK: - Text

    private let previousTitle = String(localized: "Previous Day")
    private let nextTitle = String(localized: "Next Day")
    private let todayLabel = String(localized: "today")
}
