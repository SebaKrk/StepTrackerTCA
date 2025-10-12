//
//  HealthMetricSummaryCardView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 11/10/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: HealthMetricSummaryCardFeature.self)
struct HealthMetricSummaryCardView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HealthMetricSummaryCardFeature>
    
    // MARK: - Body
    
    var body: some View {
        rootView
            .skeleton(isLoading: store.contentState == .loading)
            .padding([.leading, .trailing], 8)
            .overlay { overlayContent }
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
    private var rootView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ],
            spacing: 4
        ) {
            ForEach(HealthMetricType.allCases) { metricType in
                metricGroupBox(for: metricType, data: getMetricData(for: metricType))
            }
        }
    }
    
    private func getMetricData(for type: HealthMetricType) -> TrainingComponentScore? {
        guard let components = store.components else { return nil }
        
        switch type {
        case .rhr:
            return components.restingHeartRate
        case .hrv:
            return components.heartRateVariability
        case .sleep:
            return components.sleepQuality
        case .activity:
            return components.previousDayLoad
        }
    }
    
    private var shouldBlur: Bool {
         switch store.contentState {
         case .ready:
            return !store.hasAccess
         case .unauthorized, .noData:
             return true
         case .loading:
             return false
         }
     }
    
    // MARK: - SubViews
    
    @ViewBuilder
    func metricGroupBox(
        for metric: HealthMetricType,
        data: TrainingComponentScore?
    ) -> some View {
        GroupBox {
            if let data = data {
                metricContent(for: metric, data: data)
            } else {
                noDataContent()
            }
        } label: {
            containerTitle(metric)
        }
        .frame(height: 160)
        .blur(radius: shouldBlur ? 3 : 0)
    }
    
    @ViewBuilder
    func metricContent(for metric: HealthMetricType, data: TrainingComponentScore) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                // Wartość
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", data.currentValue))
                    Text(data.unit)
                }
                
                // Status
                HStack(spacing: 4) {
                    Text("\(data.score)")
                }
                Spacer()
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    func containerTitle(_ metricType: HealthMetricType) -> some View {
        VStack {
            HStack {
                Group {
                    Image(systemName: metricType.icon)
                    Text(metricType.title)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.gray)
                .font(.caption)
            }
            Divider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    func noDataContent() -> some View {
        VStack {
            Spacer()
            Text("Brak danych")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        switch store.contentState {
        case .ready:
            if !store.hasAccess {
                ChartOverlayView.locked {
                    // send(.unlockButtonTapped)
                }
            }
        
        case .unauthorized:
            ChartOverlayView.unauthorized {
                //send(.requestHealthAccessTapped)
            }
            
        default:
            EmptyView()
        }
    }
    
}

//#Preview {
//    ZStack {
//        Color(.systemGroupedBackground)
//            .ignoresSafeArea()
//
//        HealthMetricCardsView(
//            components: TrainingReadinessComponents(
//                restingHeartRate: TrainingComponentScore(
//                    score: 10,
//                    currentValue: 58.1,
//                    baselineValue: 55.0,
//                    unit: "bpm"
//                ),
//                heartRateVariability: TrainingComponentScore(
//                    score: 8,
//                    currentValue: 61.4,
//                    baselineValue: 58.0,
//                    unit: "ms"
//                ),
//                sleepQuality: TrainingComponentScore(
//                    score: 5,
//                    currentValue: 7.5,
//                    baselineValue: 7.8,
//                    unit: "hours"
//                ),
//                previousDayLoad: TrainingComponentScore(
//                    score: -5,
//                    currentValue: 450.0,
//                    baselineValue: 320.0,
//                    unit: "kcal"
//                )
//            )
//        )
//        .padding()
//    }
//}


import SwiftUI
import SharedModels

enum HealthMetricType: String, CaseIterable, Identifiable {
    case rhr
    case hrv
    case sleep
    case activity
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .rhr: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .sleep: return "bed.double.fill"
        case .activity: return "flame.fill"
        }
    }
    
    var title: String {
        switch self {
        case .rhr: return "RHR"
        case .hrv: return "HRV"
        case .sleep: return "Sleep"
        case .activity: return "Activity"
        }
    }
    
    var fullName: String {
        switch self {
        case .rhr: return "Resting Heart Rate"
        case .hrv: return "Heart Rate Variability"
        case .sleep: return "Sleep Quality"
        case .activity: return "Activity Level"
        }
    }
}


//        LazyVGrid(
//            columns: [
//                GridItem(.flexible(), spacing: 12),
//                GridItem(.flexible(), spacing: 12)
//            ],
//            spacing: 12
//        ) {
//            ForEach(HealthMetricType.allCases) { metricType in
//                metricGroupBox(for: metricType) {
//                    Text("AAA")
//                    VStack(alignment: .leading, spacing: 8) {
//                        // Icon
//                        Image(systemName: metricType.icon)
//                            .font(.title2)
//                            .foregroundColor(.gray)
//
//                        // Title (skrót)
//                        Text(metricType.title)
//                            .font(.title)
//                            .fontWeight(.medium)
//                            .foregroundColor(.gray)
//
//                        // Full name
//                        Text(metricType.fullName)
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//
//                        Spacer()
//                            .frame(height: 80) // placeholder
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                }
//            }
//        }
//        .padding(.horizontal, 16)


//                    VStack {
//                        HStack {
//                            Group {
//                                Image(systemName: metricType.icon)
//                                Text(metricType.title)
//                                Spacer()
//                                Image(systemName: "chevron.right")
//                            }
//                            .foregroundColor(.gray)
//                            .font(.caption)
//                        }
//                        Divider()
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .foregroundStyle(.secondary)

//    @ViewBuilder
//    private func metricGroupBox<Content: View>(for metric: HealthMetricType, @ViewBuilder content: () -> Content ) -> some View {
//        GroupBox {
//            content()
//        } label: {
//            Text("title")
//        }
//        .groupBoxStyle(HealthMetricGroupBoxStyle())
//.padding([.leading, .trailing], 8)
//.foregroundStyle(.secondary)
//    }

//}


//// MARK: - Custom GroupBox Style
//
//struct HealthMetricGroupBoxStyle: GroupBoxStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        VStack(alignment: .leading, spacing: 0) {
//            configuration.content
//        }
//        .padding(16)
//        .background(Color.white)
//        .cornerRadius(16)
//        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
//    }
//}
