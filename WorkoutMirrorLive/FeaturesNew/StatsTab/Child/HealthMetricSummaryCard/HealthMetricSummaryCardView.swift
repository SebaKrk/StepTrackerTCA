//
//  HealthMetricSummaryCardView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 11/10/2025.
//

//import ComposableArchitecture
//import SwiftUI
//
//@ViewAction(for: HealthMetricSummaryCardFeature.self)
//struct HealthMetricSummaryCardView: View {
//    
//    // MARK: - Properties
//    @Bindable var store: StoreOf<HealthMetricSummaryCardFeature>
//    
//    // MARK: - Body
//    
//    var body: some View {
//        Text("HealthMetricSummaryCardFeature")
//    }
//    
//    // MARK: - Subview
//    
//    @ViewBuilder
//    private func stepsWalkGroupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
//        GroupBox {
//            content()
//        } label: {
//            headerTitle
//        }
//        .padding([.leading, .trailing], 8)
//        .foregroundStyle(.secondary)
//    }
//    
//}

import SwiftUI

struct HealthMetricCardsView: View {
    
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(HealthMetricType.allCases) { metricType in
                metricGroupBox(for: metricType) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Icon
                        Image(systemName: metricType.icon)
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        // Title (skrót)
                        Text(metricType.title)
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        // Full name
                        Text(metricType.fullName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                            .frame(height: 80) // placeholder
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - ViewBuilder Helper
    
    @ViewBuilder
    private func metricGroupBox<Content: View>(
        for metric: HealthMetricType,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GroupBox {
            content()
        }
        .groupBoxStyle(HealthMetricGroupBoxStyle())
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        HealthMetricCardsView()
    }
}

// MARK: - Custom GroupBox Style

struct HealthMetricGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            configuration.content
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

import SwiftUI

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

