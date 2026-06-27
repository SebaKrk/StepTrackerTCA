//
//  TemplatePickerView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 26/06/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Sheet z listą `TrainingSession` template'ów. Tap karty → sheet z `WorkoutDetailContent` (preview),
/// w sheet'cie toolbar "Wybierz" potwierdza wybór i emituje delegate w feature.
@ViewAction(for: TemplatePickerFeature.self)
struct TemplatePickerView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<TemplatePickerFeature>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                switch store.viewState {
                case .loading:
                    ProgressView()
                case .success:
                    templatesList
                case .failed:
                    failedView
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }
            }
            .onAppear {
                send(.viewDidAppear)
            }
        }
        .sheet(
            item: Binding(
                get: { store.previewTemplate },
                set: { _ in send(.previewDismissed) }
            )
        ) { template in
            planPreviewSheet(template)
        }
    }

    // MARK: - Templates list

    @ViewBuilder
    private var templatesList: some View {
        if store.templates.isEmpty {
            emptyView
        } else {
            List {
                ForEach(store.templates) { template in
                    templateRow(template)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Template row (Liquid Glass card — wzorem PlansView, bez stats)

    private func templateRow(_ template: TrainingSession) -> some View {
        GroupBox {
            templateExercisesPreview(template)
        } label: {
            VStack {
                templateHeaderButton(template)
                Divider()
            }
        }
        .styledGroupBox()
        .padding(4)
    }

    private func templateHeaderButton(_ template: TrainingSession) -> some View {
        Button {
            send(.templateTapped(template))
        } label: {
            templateHeader(template)
        }
        .buttonStyle(.plain)
    }

    private func templateHeader(_ template: TrainingSession) -> some View {
        HStack {
            templateActivityIcon(template)

            VStack(alignment: .leading, spacing: 4) {
                templateTitle(template)
                templateSubtitle(template)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
    }

    private func templateActivityIcon(_ template: TrainingSession) -> some View {
        Image(systemName: template.activity.iconName.replacingOccurrences(of: ".circle.fill", with: ""))
            .resizable()
            .scaledToFit()
            .foregroundColor(.primary)
            .frame(width: 40, height: 40)
    }

    private func templateTitle(_ template: TrainingSession) -> some View {
        Text(template.title)
            .foregroundColor(.primary)
            .font(.title2)
            .bold()
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func templateSubtitle(_ template: TrainingSession) -> some View {
        Text(template.date, style: .date)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    // MARK: - Exercises preview (na środku karty — caption, 2 linie, jak PlansView)

    private func templateExercisesPreview(_ template: TrainingSession) -> some View {
        Text(exercisesLine(template))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
    }

    // MARK: - Plan preview sheet (reuse `WorkoutDetailContent` — pure content, no actions)

    /// Sheet z read-only widokiem template'a. Używa `WorkoutDetailContent` — shared component
    /// (też w WorkoutPreviewView i PlanDetailView). Brak Edit / Start Workout / History — w preview
    /// mode user tylko ogląda strukturę i potwierdza wybór przyciskiem "Wybierz" w toolbar.
    /// Warmup/cooldown sekcje zawsze expanded (`.constant(true)`) — read-only display.
    private func planPreviewSheet(_ template: TrainingSession) -> some View {
        NavigationStack {
            ScrollView {
                WorkoutDetailContent(
                    session: template,
                    isWarmupExpanded: .constant(true),
                    isCooldownExpanded: .constant(true)
                )
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    previewCloseButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    selectFromPreviewButton(template)
                }
            }
        }
    }

    private var previewCloseButton: some View {
        Button {
            send(.previewDismissed)
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel(closeButtonAccessibilityLabel)
    }

    private func selectFromPreviewButton(_ template: TrainingSession) -> some View {
        Button {
            send(.selectFromPreviewTapped(template))
        } label: {
            Text(selectButtonTitle)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Close button

    private var closeButton: some View {
        Button {
            send(.closeButtonTapped)
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel(closeButtonAccessibilityLabel)
    }

    // MARK: - Empty / Failed

    private var emptyView: some View {
        ContentUnavailableView(
            emptyTitle,
            systemImage: "list.bullet.clipboard",
            description: Text(emptyDescription)
        )
    }

    private var failedView: some View {
        ContentUnavailableView(
            failedTitle,
            systemImage: "exclamationmark.triangle",
            description: Text(failedDescription)
        )
    }

    // MARK: - Helpers

    /// Lista unikalnych nazw ćwiczeń (wzorem PlansView.exercisesLine) — preview na karcie.
    private func exercisesLine(_ template: TrainingSession) -> String {
        var seen = Set<String>()
        let names = template.workouts
            .flatMap { $0.exercises }
            .map { $0.displayName }
            .filter { seen.insert($0).inserted }
        return names.isEmpty ? "–" : names.joined(separator: " · ")
    }

    // MARK: - Localized strings (UI facade)

    private var navigationTitle: String {
        String(localized: "Wybierz trening")
    }

    private var emptyTitle: String {
        String(localized: "Brak treningów")
    }

    private var emptyDescription: String {
        String(localized: "Stwórz najpierw plan treningu w zakładce Plany.")
    }

    private var failedTitle: String {
        String(localized: "Błąd ładowania")
    }

    private var failedDescription: String {
        String(localized: "Nie udało się załadować treningów.")
    }

    private var selectButtonTitle: String {
        String(localized: "Wybierz")
    }

    private var closeButtonAccessibilityLabel: String {
        String(localized: "Zamknij")
    }
}
