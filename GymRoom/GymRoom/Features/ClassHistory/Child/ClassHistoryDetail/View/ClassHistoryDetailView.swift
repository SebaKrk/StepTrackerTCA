//
//  ClassHistoryDetailView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

/// Detail view klasy w History — push z `ClassHistoryView` row tap. Sekcje:
/// top stats banner, HR chart toggle (combined LineMark / perAthlete BarMark range
/// z selection). W `.combined` rząd dwóch donutów (kalorie per athlete + czas klasy
/// w strefach HR), responsywny iPad obok / iPhone pod sobą. W `.perAthlete` stacked
/// bar "time in zones" per uczestnik.
@ViewAction(for: ClassHistoryDetailFeature.self)
struct ClassHistoryDetailView: View {

    @Bindable var store: StoreOf<ClassHistoryDetailFeature>

    /// Read-only @Environment (NIE @State) — steruje wyłącznie layoutem rzędu donutów:
    /// `.regular` (iPad / split view) → obok siebie, `.compact` (iPhone) → pod sobą.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            switch store.viewState {
            case .loading:
                loadingState
            case .success:
                contentScrollView
            case .failed:
                failedState
            }
        }
        .navigationTitle(store.className)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { actionsMenu }
        .alert($store.scope(state: \.alert, action: \.alert))
        .task { send(.viewDidAppear) }
    }

    /// Wewnętrzny content (top stats + charts) — pokazywany tylko gdy
    /// `viewState == .success`. Wyciągnięty z body żeby switch po viewState
    /// trzymał całość loading/success/failed w jednym poziomie.
    private var contentScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                topStatsBanner
                hrChartSection
                if !store.athletes.isEmpty {
                    if store.chartViewMode == .combined {
                        combinedChartsRow
                    } else {
                        timeInZonesSection
                    }
                }
            }
            .padding()
        }
    }

    /// Centered ProgressView na pełnym ekranie — pokazywany podczas decode'u BLOB-ów
    /// (1-3 sek dla wielu athletes). Bez tego user widział pusty topStatsBanner (0/0/—).
    private var loadingState: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Failed state z retry button — re-emit `.viewDidAppear` resetuje
    /// viewState do `.loading` i ponawia decode.
    private var failedState: some View {
        ContentUnavailableView {
            Label(failedLoadTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(failedLoadDescription)
        } actions: {
            Button {
                send(.viewDidAppear)
            } label: {
                Label(retryLoadTitle, systemImage: "arrow.clockwise")
            }
        }
    }

    private var failedLoadTitle: String {
        String(localized: "Loading failed", bundle: .main)
    }

    private var failedLoadDescription: String {
        String(localized: "Couldn't load athlete data for this class. Please try again.", bundle: .main)
    }

    private var retryLoadTitle: String {
        String(localized: "Try again", bundle: .main)
    }

    // MARK: - Insufficient data state

    /// Klasy / atleci poniżej tego progu nie mają sensownej HR analytics —
    /// chart zostaje zastąpiony `ContentUnavailableView`. 5 min to typowy próg
    /// Apple Fitness dla workout history.
    private static let minDurationForAnalytics: TimeInterval = 300

    /// `nil endedAt` = klasa nadal trwa → false (nawet jeśli teraz ma 30 sek).
    /// Placeholder pojawia się **tylko po zakończeniu** krótszej klasy.
    private var isClassTooShort: Bool {
        guard let endedAt = store.endedAt else { return false }
        return endedAt.timeIntervalSince(store.startedAt) < Self.minDurationForAnalytics
    }

    /// Athlete-level — szczególny przypadek gdy klasa dłuższa niż 5 min, ale
    /// dany atleta był w niej krócej (joinedAt → leftAt < 5 min).
    private func hasInsufficientData(_ athlete: AthleteSummary) -> Bool {
        athlete.analytics.durationSeconds < Self.minDurationForAnalytics
    }

    /// Placeholder dla chartów z niewystarczającymi danymi — `ContentUnavailableView`
    /// z systemową typografią, ikoną i opisem. Pasuje wizualnie do `emptyHRChart` /
    /// `athleteEmptyChart` (oba też używają `ContentUnavailableView`).
    ///
    /// `systemImage` przekazywany przez caller'a — każdy chart wybiera semantycznie
    /// pasującą ikonę (HR / kalorie / strefy), żeby placeholder'y się nie powtarzały
    /// wizualnie gdy kilka chartów ma insufficient data jednocześnie.
    private func insufficientDataView(systemImage: String) -> some View {
        ContentUnavailableView {
            Label(insufficientDataTitle, systemImage: systemImage)
        } description: {
            Text(insufficientDataDescription)
        }
    }

    private var insufficientDataTitle: String {
        String(localized: "Za mało danych", bundle: .main)
    }

    private var insufficientDataDescription: String {
        String(localized: "Trening był zbyt krótki, by zanalizować HR — minimum 5 minut.", bundle: .main)
    }

    /// Ellipsis menu w prawym górnym rogu — struktura (CO).
    /// Aktualnie 1 akcja (Delete). Future: Share / Export — design ready dla rozbudowy.
    @ToolbarContentBuilder
    private var actionsMenu: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                deleteButton
            } label: {
                menuLabel
            }
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
    }

    // MARK: - Top stats banner

    private var topStatsBanner: some View {
        HStack(spacing: 12) {
            statCard(label: athletesLabel, value: "\(store.athletes.count)")
            statCard(label: durationLabelTitle, value: durationValue)
            statCard(label: caloriesLabel, value: caloriesValue)
            statCard(label: avgHRLabel, value: avgHRValue)
        }
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - HR chart section (toggle per athlete / combined)

    private var hrChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(hrSectionTitle)
                    .font(.headline)
                Spacer()
            }
            chartModePicker
            chartContent
        }
    }

    private var chartModePicker: some View {
        Picker(hrSectionTitle, selection: $store.chartViewMode) {
            ForEach(ClassHistoryDetailFeature.ChartViewMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var chartContent: some View {
        if store.athletes.isEmpty {
            emptyHRChart
        } else {
            switch store.chartViewMode {
            case .combined: combinedChart
            case .perAthlete: perAthleteCards
            }
        }
    }

    private var emptyHRChart: some View {
        ContentUnavailableView(
            emptyChartTitle,
            systemImage: "waveform.path.ecg",
            description: Text(emptyChartDescription)
        )
        .frame(height: 200)
    }

    /// Multi-series LineMark — wszyscy athletes na jednej skali czasu z legendą.
    /// Bez selection (do porównania overlay, scrub przez 5 linii byłby chaotyczny).
    /// W `GroupBox` dla spójności z resztą chartów w widoku.
    private var combinedChart: some View {
        GroupBox {
            if isClassTooShort {
                insufficientDataView(systemImage: "chart.xyaxis.line")
                    .frame(height: 280)
            } else {
                Chart {
                    ForEach(store.athletes) { athlete in
                        ForEach(athlete.samples, id: \.timestamp) { sample in
                            LineMark(
                                x: .value("Time", sample.timestamp),
                                y: .value("BPM", sample.bpm),
                                series: .value("Athlete", athlete.nick)
                            )
                            .foregroundStyle(by: .value("Athlete", athlete.nick))
                            .interpolationMethod(.monotone)
                        }
                    }

                    if let selectedTime = store.selectedCombinedTime {
                        RuleMark(x: .value("Selected Time", selectedTime))
                            .foregroundStyle(Color.secondary.opacity(0.4))
                            .annotation(
                                position: .top,
                                spacing: 8,
                                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                            ) {
                                combinedSelectionAnnotation(at: selectedTime)
                            }

                        ForEach(store.athletes) { athlete in
                            if let sample = nearestSample(in: athlete, to: selectedTime) {
                                PointMark(
                                    x: .value("Time", sample.timestamp),
                                    y: .value("BPM", sample.bpm)
                                )
                                .symbolSize(60)
                                .foregroundStyle(AthleteColor.color(for: athlete.deviceID))
                            }
                        }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartLegend(position: .bottom, alignment: .leading)
                .chartXSelection(value: combinedSelectionBinding.animation(.easeInOut))
                .frame(height: 280)
            }
        }
    }

    // MARK: - Combined chart selection (multi-series scrub)

    /// Custom binding routujący scrub przez akcję `combinedTimeSelected`.
    /// Analog `athleteSelectionBinding` ale dla single Date (nie keyed dict).
    private var combinedSelectionBinding: Binding<Date?> {
        Binding(
            get: { store.selectedCombinedTime },
            set: { store.send(.combinedTimeSelected($0)) }
        )
    }

    /// Najbliższy sample athlete'a do scrubowanej daty. O(n) per athlete — dla
    /// 360 sample'ów × 4 athletes = 1440 ops per redraw. Acceptable.
    private func nearestSample(in athlete: AthleteSummary, to date: Date) -> HRSample? {
        athlete.samples.min(by: {
            abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date))
        })
    }


    /// Annotation widoczna nad RuleMark — lista nick + BPM per athlete, sorted
    /// malejąco po BPM (najwyższy first = czytelny ranking w moment scrub'a).
    /// `overflowResolution(.fit(to: .chart))` zapewnia że nie wyjdzie poza chart.
    private func combinedSelectionAnnotation(at time: Date) -> some View {
        let entries = store.athletes
            .compactMap { athlete -> (athlete: AthleteSummary, sample: HRSample)? in
                guard let sample = nearestSample(in: athlete, to: time) else { return nil }
                return (athlete, sample)
            }
            .sorted { $0.sample.bpm > $1.sample.bpm }

        return VStack(alignment: .leading, spacing: 4) {
            Text(time, format: .dateTime.hour().minute())
                .font(.caption2)
                .foregroundStyle(.secondary)
            ForEach(entries, id: \.athlete.id) { entry in
                HStack(spacing: 6) {
                    Circle()
                        .fill(AthleteColor.color(for: entry.athlete.deviceID))
                        .frame(width: 6, height: 6)
                    Text(entry.athlete.nick)
                        .font(.caption.weight(.semibold))
                    Spacer(minLength: 12)
                    Text(verbatim: "\(entry.sample.bpm)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                    Text(verbatim: "BPM")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2, y: 1)
    }

    /// Lista kart per athlete — każda karta = header stats + BarMark range chart + selection.
    private var perAthleteCards: some View {
        VStack(spacing: 12) {
            ForEach(store.athletes) { athlete in
                athleteCard(for: athlete)
            }
        }
    }

    /// Karta athlete'a (facade — struktura CO; szczegóły implementacji JAK w subview helpers).
    /// `GroupBox` zamiast ręcznego VStack+padding+background — system styling spójny
    /// z resztą chartów w widoku (analog `hrGroupBox` w `HeartRateDetailsView`).
    @ViewBuilder
    private func athleteCard(for athlete: AthleteSummary) -> some View {
        let color = AthleteColor.color(for: athlete.deviceID)
        let ranges = store.hrRangesByAthlete[athlete.id] ?? []
        let selectedMinute = store.selectedMinutes[athlete.id]

        GroupBox {
            VStack(spacing: 4) {
                athleteCardChart(athlete: athlete, ranges: ranges, selectedMinute: selectedMinute, color: color)
                athleteCardFooter(athlete: athlete)
            }
        } label: {
            athleteCardHeader(athlete: athlete, color: color)
        }
    }

    // MARK: - Athlete card subviews (JAK)

    private func athleteCardHeader(athlete: AthleteSummary, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            athleteColorDot(color: color)
            Text(athlete.nick)
                .font(.headline)
            Spacer()
            athleteAvgPeakText(athlete)
                .font(.caption.monospacedDigit())
        }
    }

    private func athleteColorDot(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    /// Footer karty atlety — centred pod chart'em, secondary color (informacja
    /// supplementary do header'a). Pokazuje total kcal + czas athlety w klasie.
    /// Footer karty atlety — duration na lewo, kcal na prawo. `HStack + Spacer`
    /// rozdziela dwie wartości na krańce. `font` aplikowany raz na HStack
    /// (propagates to child Text'y).
    private func athleteCardFooter(athlete: AthleteSummary) -> some View {
        HStack(spacing: 8) {
            athleteDurationText(athlete)
            Spacer()
            athleteKcalText(athlete)
        }
        .font(.caption.monospacedDigit())
        .padding(.top, 4)
    }

    @ViewBuilder
    private func athleteCardChart(
        athlete: AthleteSummary,
        ranges: [HRMinuteRange],
        selectedMinute: Date?,
        color: Color
    ) -> some View {
        if ranges.isEmpty {
            athleteEmptyChart
        } else if hasInsufficientData(athlete) {
            insufficientDataView(systemImage: "chart.line.text.clipboard.fill")
                .frame(height: 200)
        } else {
            Chart {
                if let selectedMinute,
                   let selectedRange = selectedRange(in: ranges, for: selectedMinute) {
                    createRuleMark(with: selectedMinute) {
                        AthleteHRAnnotationView(range: selectedRange, athleteColor: color)
                    }
                }
                ForEach(ranges) { range in
                    createBarMark(
                        range,
                        isSelected: isMinuteSelected(range: range, selectedMinute: selectedMinute),
                        style: barGradient(for: range, maxHR: athlete.maxHR)
                    )
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXSelection(value: athleteSelectionBinding(athleteID: athlete.id).animation(.easeInOut))
            .chartXAxis {
                AxisMarks(preset: .aligned, values: .automatic) { _ in
                    AxisValueLabel()
                }
            }
            .frame(height: 140)
            .padding(.horizontal, 8)
        }
    }

    private var athleteEmptyChart: some View {
        ContentUnavailableView(
            athleteEmptyChartTitle,
            systemImage: "waveform.path.ecg",
            description: Text(athleteEmptyChartDescription)
        )
        .frame(height: 140)
    }

    // MARK: - Selection helpers (TCA bridge dla Charts)

    /// Custom binding routujący scrub przez akcję `minuteSelected`. NIE używa
    /// `BindingAction<State>` bo `selectedMinutes` to dict keyed by athleteID
    /// — akcja jest jednoznaczna i testowalna.
    private func athleteSelectionBinding(athleteID: UUID) -> Binding<Date?> {
        Binding(
            get: { store.selectedMinutes[athleteID] },
            set: { store.send(.minuteSelected(athleteID: athleteID, $0)) }
        )
    }

    /// Selection comparison po minutowej granularności. `Date == Date` nie zadziała
    /// — Charts wysyła selectedDate z dokładnością do ms, range.minute to początek minuty.
    private func isMinuteSelected(range: HRMinuteRange, selectedMinute: Date?) -> Bool {
        guard let selectedMinute else { return true }
        return Calendar.current.isDate(range.minute, equalTo: selectedMinute, toGranularity: .minute)
    }

    private func selectedRange(in ranges: [HRMinuteRange], for selectedMinute: Date) -> HRMinuteRange? {
        ranges.first {
            Calendar.current.isDate($0.minute, equalTo: selectedMinute, toGranularity: .minute)
        }
    }

    /// Vertical gradient od koloru strefy `minHR` (dół słupka) do strefy `maxHR`
    /// (góra słupka). Apple Fitness-style — bar ma "rainbow" effect odzwierciedlający
    /// range BPM tej minuty. Np. range 130-170 → gradient od green (fatBurning)
    /// na dole do orange (threshold) na górze. Gdy min i max w tej samej strefie
    /// (np. cooldown 100-110 oba fatBurning) → gradient color→color = solid color.
    private func barGradient(for range: HRMinuteRange, maxHR: Int) -> LinearGradient {
        LinearGradient(
            colors: [
                zoneColor(for: range.minHR, maxHR: maxHR),
                zoneColor(for: range.maxHR, maxHR: maxHR)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    /// Mapuje pojedynczy BPM na kolor strefy. Helper dla `barGradient`.
    /// **Clamp do `[0, 1]`** — w prawdziwym treningu BPM może chwilowo przekroczyć
    /// theoretical `maxHR` (np. peakHR 198 przy maxHR 190 = 1.04). Bez clamp'a
    /// anaerobic strefa (0.9...1.0) by nie złapała i wpadalibyśmy w `.gray` fallback.
    private func zoneColor(for bpm: Int, maxHR: Int) -> Color {
        let percent = min(1.0, max(0.0, Double(bpm) / Double(maxHR)))
        return HeartRateZone.allCases.first {
            $0.percentageRange.contains(percent)
        }?.color ?? .gray
    }

    // MARK: - Combined charts row (.combined only, responsywny)

    /// Rząd dwóch donutów w trybie Combined. `.regular` (iPad / split view) →
    /// obok siebie po 50% szerokości; `.compact` (iPhone) → pod sobą z zachowaniem
    /// pionowego spacingu sekcji (32). View pozostaje "głupie" — jedyna gałąź to
    /// czysty layout sterowany read-only size class.
    @ViewBuilder
    private var combinedChartsRow: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: .top, spacing: 16) {
                caloriesPieSection
                    .frame(maxHeight: .infinity)
                zoneTimeClassPieSection
                    .frame(maxHeight: .infinity)
            }
            .fixedSize(horizontal: false, vertical: true)
        } else {
            VStack(spacing: 32) {
                caloriesPieSection
                zoneTimeClassPieSection
            }
        }
    }

    // MARK: - Calories donut pie chart (.combined only)

    /// Donut pie chart z proporcjami kcal per athlete. Tap na slice → center label
    /// pokazuje nick + kcal tego athlete'a. Tap poza chart → wraca do `Total class + suma`.
    /// Tytuł sekcji jest jednocześnie labelem `GroupBox` — system typografia section header.
    /// `maxWidth: .infinity` → równy podział 50/50 obok donuta stref w `HStack`.
    private var caloriesPieSection: some View {
        GroupBox {
            if isClassTooShort {
                insufficientDataView(systemImage: "flame.fill")
            } else {
                VStack(spacing: 16) {
                    caloriesPieChart
                    caloriesLegend
                    Spacer(minLength: 0)
                }
            }
        } label: {
            Text(caloriesSectionTitle)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Time in zones donut (class aggregate, .combined only)

    /// Drugi donut obok kalorii — sumaryczny czas CAŁEJ klasy w 5 strefach HR.
    /// Lewy donut = kto ile spalił (per athlete), prawy = ile czasu klasa spędziła
    /// w której strefie. Te same kolory stref co stacked bar w `.perAthlete` —
    /// ta sama strefa = ten sam kolor w całym widoku. Bez selekcji (tylko legenda).
    private var zoneTimeClassPieSection: some View {
        GroupBox {
            if isClassTooShort {
                insufficientDataView(systemImage: "chart.pie.fill")
            } else {
                VStack(spacing: 16) {
                    zoneTimeClassPieChart
                    zonesLegend
                    Spacer(minLength: 0)
                }
            }
        } label: {
            Text(timeInZonesTitle)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }

    /// Tap na slice → center label pokazuje nazwę strefy + czas + % klasy.
    /// Tap poza chart → wraca do sumy ("All zones" + total active time).
    /// Kolor bezpośrednio z `zone.color` (custom legenda zastępuje domyślną Charts).
    private var zoneTimeClassPieChart: some View {
        Chart(classTimeInZones, id: \.zone) { entry in
            SectorMark(
                angle: .value("Seconds", entry.seconds),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .cornerRadius(8)
            .foregroundStyle(entry.zone.color)
            .opacity(opacityForZoneSlice(entry.zone))
        }
        .chartAngleSelection(value: $store.selectedZoneAngle.animation(.easeInOut))
        .chartLegend(.hidden)
        .chartBackground { proxy in
            zoneCenterLabel(in: proxy)
        }
        .frame(height: 280)
    }

    @ViewBuilder
    private func zoneCenterLabel(in proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            if let plotFrame = proxy.plotFrame {
                let frame = geo[plotFrame]
                VStack(spacing: 4) {
                    Text(zoneCenterTitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                    Text(zoneCenterValue)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(zoneCenterSubtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .position(x: frame.midX, y: frame.midY)
            }
        }
    }

    private var caloriesPieChart: some View {
        Chart(sortedByCalories) { athlete in
            SectorMark(
                angle: .value("kcal", athlete.analytics.totalCalories),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .cornerRadius(8)
            .foregroundStyle(AthleteColor.color(for: athlete.deviceID))
            .opacity(opacityForSlice(athlete))
        }
        .chartAngleSelection(value: $store.selectedKcalAngle.animation(.easeInOut))
        .chartLegend(.hidden)
        .chartBackground { proxy in
            kcalCenterLabel(in: proxy)
        }
        .frame(height: 280)
    }

    @ViewBuilder
    private func kcalCenterLabel(in proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            if let plotFrame = proxy.plotFrame {
                let frame = geo[plotFrame]
                VStack(spacing: 4) {
                    Text(kcalCenterTitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(kcalCenterValue)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(kcalUnitLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .position(x: frame.midX, y: frame.midY)
            }
        }
    }

    // MARK: - Pie chart selection helpers

    /// Mapuje cumulative angle z `chartAngleSelection` na konkretnego athletę.
    /// Iteruje sorted athletes (matching slice order), akumuluje kcal — pierwszy
    /// athlete którego prefix sum ≥ selected angle to wybrany slice.
    private var selectedAthleteFromAngle: AthleteSummary? {
        guard let selectedAngle = store.selectedKcalAngle else { return nil }
        var cumulative = 0.0
        for athlete in sortedByCalories {
            cumulative += athlete.analytics.totalCalories
            if selectedAngle <= cumulative { return athlete }
        }
        return nil
    }

    private func opacityForSlice(_ athlete: AthleteSummary) -> Double {
        guard let selected = selectedAthleteFromAngle else { return 1.0 }
        return athlete.id == selected.id ? 1.0 : 0.4
    }

    private var kcalCenterTitle: String {
        selectedAthleteFromAngle?.nick ?? String(localized: "Total class", bundle: .main)
    }

    private var kcalCenterValue: String {
        let kcal: Double
        if let selected = selectedAthleteFromAngle {
            kcal = selected.analytics.totalCalories
        } else {
            kcal = store.athletes.reduce(0) { $0 + $1.analytics.totalCalories }
        }
        return String(format: "%.0f", kcal)
    }

    private var kcalUnitLabel: String {
        String(localized: "kcal", bundle: .main)
    }

    // MARK: - Zone donut selection helpers

    /// Analog `selectedAthleteFromAngle` dla donuta stref. Iteruje `classTimeInZones`
    /// w TEJ SAMEJ kolejności co rysowane slice'y, akumuluje sekundy — pierwsza strefa
    /// której prefix sum ≥ selected angle to wybrany slice.
    private var selectedZoneFromAngle: (zone: HeartRateZone, seconds: TimeInterval)? {
        guard let selectedAngle = store.selectedZoneAngle else { return nil }
        var cumulative = 0.0
        for entry in classTimeInZones {
            cumulative += entry.seconds
            if selectedAngle <= cumulative { return entry }
        }
        return nil
    }

    private func opacityForZoneSlice(_ zone: HeartRateZone) -> Double {
        guard let selected = selectedZoneFromAngle else { return 1.0 }
        return zone == selected.zone ? 1.0 : 0.4
    }

    private var zoneCenterTitle: String {
        selectedZoneFromAngle?.zone.title ?? String(localized: "All zones", bundle: .main)
    }

    private var zoneCenterValue: String {
        let seconds = selectedZoneFromAngle?.seconds ?? totalZoneSeconds
        return formattedZoneDuration(seconds)
    }

    /// Pod wartością: dla wybranej strefy jej udział % w czasie klasy, dla sumy
    /// neutralny opis. Pusty gdy brak danych (uniknięcie dzielenia przez 0).
    private var zoneCenterSubtitle: String {
        guard totalZoneSeconds > 0 else { return "" }
        if let selected = selectedZoneFromAngle {
            let pct = Int((selected.seconds / totalZoneSeconds * 100).rounded())
            return String(localized: "\(pct)% of class", bundle: .main)
        }
        return String(localized: "active time", bundle: .main)
    }

    private var totalZoneSeconds: TimeInterval {
        classTimeInZones.reduce(0) { $0 + $1.seconds }
    }

    // MARK: - Custom donut legends (kropka + nazwa + wartość)

    /// Legenda donuta kalorii — wiersz per athlete (ranking malejący), wartość = kcal.
    /// Zastępuje domyślną legendę Charts: pokazuje liczby, nie tylko mapowanie kolorów.
    private var caloriesLegend: some View {
        VStack(spacing: 6) {
            ForEach(sortedByCalories) { athlete in
                legendRow(
                    color: AthleteColor.color(for: athlete.deviceID),
                    label: athlete.nick,
                    value: caloriesLegendValue(for: athlete)
                )
            }
        }
    }

    private func caloriesLegendValue(for athlete: AthleteSummary) -> String {
        let kcal = Int(athlete.analytics.totalCalories.rounded())
        return "\(kcal) \(kcalUnitLabel)"
    }

    /// Legenda donuta stref — wiersz per strefa (ranking malejący po czasie),
    /// wartość = sformatowany czas. Sort niezależny od kolejności slice'ów (kolor
    /// bierze się z `zone.color`, więc mapowanie pozostaje poprawne).
    private var zonesLegend: some View {
        VStack(spacing: 6) {
            ForEach(classTimeInZones.sorted { $0.seconds > $1.seconds }, id: \.zone) { entry in
                legendRow(
                    color: entry.zone.color,
                    label: entry.zone.title,
                    value: formattedZoneDuration(entry.seconds)
                )
            }
        }
    }

    private func legendRow(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
            Spacer(minLength: 12)
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    /// Kompaktowy format czasu strefy do donuta/legendy: "1h 5m" / "32m" / "45s".
    /// Pomija sekundy gdy są minuty — center label i legenda mają być czytelne,
    /// nie sekundowo-precyzyjne.
    private func formattedZoneDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(total)s"
    }

    // MARK: - Time in zones (stacked horizontal bar per athlete)

    /// Klasowy summary "kto ile czasu spędził w której strefie HR". Stacked bar
    /// per athlete, jedna oś czasu (sekundy), kolor per `HeartRateZone`. Widoczne
    /// w `.perAthlete` mode — class-comparison view dla deep-dive na uczestników.
    /// W `.combined` jego miejsce zajmuje pie chart kalorii.
    private var timeInZonesSection: some View {
        GroupBox {
            if isClassTooShort {
                insufficientDataView(systemImage: "chart.bar")
            } else {
                VStack(spacing: 16) {
                    timeInZonesChart
                    zonesRangeLegend
                }
            }
        } label: {
            Text(timeInZonesTitle)
                .font(.headline)
        }
    }

    /// Reference-guide legenda dla stacked bar — pokazuje **wszystkie 6 stref**
    /// z zakresem `% maxHR` (np. `Aerobic — 70-80%`). Bary same pokazują czas
    /// per athlete, więc legenda nie duplikuje tej info — służy jako mapa
    /// "ten kolor = ta strefa = ten % maxHR".
    private var zonesRangeLegend: some View {
        VStack(spacing: 6) {
            ForEach(HeartRateZone.allCases) { zone in
                legendRow(
                    color: zone.color,
                    label: zone.title,
                    value: zoneRangeText(for: zone)
                )
            }
        }
    }

    /// "70-80%" — zakres `% maxHR` z `HeartRateZone.percentageRange`.
    private func zoneRangeText(for zone: HeartRateZone) -> String {
        let low = Int(zone.percentageRange.lowerBound * 100)
        let high = Int(zone.percentageRange.upperBound * 100)
        return "\(low)-\(high)%"
    }

    private var timeInZonesChart: some View {
        Chart {
            ForEach(store.athletes) { athlete in
                ForEach(HeartRateZone.allCases) { zone in
                    let timeInZone = athlete.analytics.timeInZones[zone] ?? 0
                    if timeInZone > 0 {
                        BarMark(
                            x: .value("Time", timeInZone),
                            y: .value("Athlete", athlete.nick)
                        )
                        .foregroundStyle(by: .value("Zone", zoneLabel(zone)))
                    }
                }
            }
        }
        .chartForegroundStyleScale(
            domain: HeartRateZone.allCases.map { zoneLabel($0) },
            range: HeartRateZone.allCases.map(\.color)
        )
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let seconds = value.as(Double.self) {
                        Text(formatXAxisDuration(seconds))
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .frame(height: CGFloat(store.athletes.count * 40 + 60))
    }

    /// Format X-axis labels jako "Xm" (minuty). Time in zones zwykle = jedno-,
    /// dwucyfrowe minuty per strefa, sekundy byłyby nieczytelne.
    private func formatXAxisDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes)m"
    }

    /// Label strefy dla legendy — łączy `title` z zakresem `% maxHR`.
    /// Np. `"Aerobic 70-80%"`. Format kompaktowy bo legenda ma do 6 pozycji.
    /// Wartości procentowe pochodzą z `HeartRateZone.percentageRange`.
    private func zoneLabel(_ zone: HeartRateZone) -> String {
        let low = Int(zone.percentageRange.lowerBound * 100)
        let high = Int(zone.percentageRange.upperBound * 100)
        return "\(zone.title) \(low)-\(high)%"
    }

    private var timeInZonesTitle: String {
        String(localized: "Time in zones", bundle: .main)
    }

    // MARK: - Labels (lokalizacja)

    private var athletesLabel: String {
        String(localized: "Athletes", bundle: .main)
    }

    private var durationLabelTitle: String {
        String(localized: "Duration", bundle: .main)
    }

    private var caloriesLabel: String {
        String(localized: "Calories", bundle: .main)
    }

    private var avgHRLabel: String {
        String(localized: "Avg HR", bundle: .main)
    }

    private var hrSectionTitle: String {
        String(localized: "HR over time", bundle: .main)
    }

    private var caloriesSectionTitle: String {
        String(localized: "Calories burned", bundle: .main)
    }

    private var emptyChartTitle: String {
        String(localized: "No athletes data", bundle: .main)
    }

    private var emptyChartDescription: String {
        String(localized: "This class had no peers connected.", bundle: .main)
    }

    private var deleteLabel: String {
        String(localized: "Delete", bundle: .main)
    }

    /// Header text — `avg X · peak Y` z labelami w secondary, values w primary.
    /// `Text + Text` concatenation z różnymi `foregroundStyle` per token to natywny
    /// SwiftUI pattern (Apple Health używa go dla "300 BPM" type strings).
    private func athleteAvgPeakText(_ athlete: AthleteSummary) -> Text {
        Text(verbatim: "avg").foregroundStyle(.secondary)
            + Text(verbatim: " \(athlete.analytics.avgHR)").foregroundStyle(.primary)
            + Text(verbatim: " · ").foregroundStyle(.secondary)
            + Text(verbatim: "peak").foregroundStyle(.secondary)
            + Text(verbatim: " \(athlete.analytics.peakHR)").foregroundStyle(.primary)
    }

    /// Footer duration text (lewa strona) — same value, no label.
    /// Czas to "naturalna jednostka" (29m 55s) — nie wymaga prefix label.
    private func athleteDurationText(_ athlete: AthleteSummary) -> Text {
        let endRef = athlete.leftAt ?? store.endedAt ?? .now
        let durationSeconds = max(0, Int(endRef.timeIntervalSince(athlete.joinedAt)))
        return Text(verbatim: formattedDuration(durationSeconds))
            .foregroundStyle(.primary)
    }

    /// Footer kcal text (prawa strona) — value primary + " kcal" unit secondary
    /// (Apple Health pattern: number first, unit second).
    private func athleteKcalText(_ athlete: AthleteSummary) -> Text {
        let kcal = String(format: "%.1f", athlete.analytics.totalCalories)
        return Text(verbatim: kcal).foregroundStyle(.primary)
            + Text(verbatim: " kcal").foregroundStyle(.secondary)
    }

    private var athleteEmptyChartTitle: String {
        String(localized: "No samples", bundle: .main)
    }

    private var athleteEmptyChartDescription: String {
        String(localized: "This athlete didn't send any HR data.", bundle: .main)
    }

    // MARK: - Computed values

    private var durationValue: String {
        guard let endedAt = store.endedAt else {
            return String(localized: "Ongoing", bundle: .main)
        }
        let seconds = Int(endedAt.timeIntervalSince(store.startedAt))
        return formattedDuration(seconds)
    }

    private var caloriesValue: String {
        let total = store.athletes.reduce(0.0) { $0 + $1.analytics.totalCalories }
        return String(format: "%.1f", total)
    }

    private var avgHRValue: String {
        guard !store.athletes.isEmpty else { return "—" }
        let sum = store.athletes.reduce(0) { $0 + $1.analytics.avgHR }
        return "\(sum / store.athletes.count)"
    }

    private var sortedByCalories: [AthleteSummary] {
        store.athletes.sorted { $0.analytics.totalCalories > $1.analytics.totalCalories }
    }

    /// Sumaryczny czas klasy w każdej strefie HR (sum across athletes). Tylko strefy
    /// z czasem > 0, w naturalnej kolejności `HeartRateZone.allCases` (rosnące strefy).
    /// O(athletes × 5) — tani, liczony w body (analog `sortedByCalories`). Gdyby liczba
    /// uczestników rosła, naturalne miejsce na pre-agregację w `State` (jak `hrRangesByAthlete`).
    private var classTimeInZones: [(zone: HeartRateZone, seconds: TimeInterval)] {
        HeartRateZone.allCases.compactMap { zone in
            let total = store.athletes.reduce(0.0) { $0 + ($1.analytics.timeInZones[zone] ?? 0) }
            return total > 0 ? (zone, total) : nil
        }
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
