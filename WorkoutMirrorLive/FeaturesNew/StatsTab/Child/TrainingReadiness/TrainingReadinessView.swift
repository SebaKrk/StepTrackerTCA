//
//  TrainingReadinessView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: TrainingReadinessFeature.self)
struct TrainingReadinessView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TrainingReadinessFeature>
    
    // MARK: - View
    
    var body: some View {
        GroupBox {
            charts
        } label: {
            HStack {
                Text("Training Readiness")
                Spacer()
                Text(store.readinessLabel)
                    .foregroundStyle(store.readinessLevel.color)
            }
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
        .frame(height: 150) // Zwiększone z 100
    }
    
    private var charts: some View {
        Chart {
            // Stałe kolorowe tło dla całej skali
            RectangleMark(
                xStart: .value("Start", 0),
                xEnd: .value("End", 40),
                yStart: .value("Y", 0),
                yEnd: .value("Y", 1)
            )
            .foregroundStyle(.red.opacity(0.3))
            
            RectangleMark(
                xStart: .value("Start", 40),
                xEnd: .value("End", 55),
                yStart: .value("Y", 0),
                yEnd: .value("Y", 1)
            )
            .foregroundStyle(.orange.opacity(0.3))
            
            RectangleMark(
                xStart: .value("Start", 55),
                xEnd: .value("End", 70),
                yStart: .value("Y", 0),
                yEnd: .value("Y", 1)
            )
            .foregroundStyle(.yellow.opacity(0.3))
            
            RectangleMark(
                xStart: .value("Start", 70),
                xEnd: .value("End", 85),
                yStart: .value("Y", 0),
                yEnd: .value("Y", 1)
            )
            .foregroundStyle(.mint.opacity(0.3))
            
            RectangleMark(
                xStart: .value("Start", 85),
                xEnd: .value("End", 100),
                yStart: .value("Y", 0),
                yEnd: .value("Y", 1)
            )
            .foregroundStyle(.green.opacity(0.3))
            
            RuleMark(
                x: .value("Current", store.readinessValue)
            )
//            .foregroundStyle(.primary)
//            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
            
            .annotation(
                position: .overlay,
                alignment: .center,
                spacing: 2
            ) {
                Text("\(store.readinessValue)")
                    .font(.footnote)
//                Text("\(store.readinessValue)")
//                    .font(.caption2)
//                    .fontWeight(.medium)
//                    .padding(.horizontal, 6)
//                    .padding(.vertical, 1)
//                    .background(store.readinessLevel.color.opacity(0.9))
//                    .foregroundStyle(.white)
//                    .clipShape(Capsule())
            }
        }
        .chartXScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: [0, 25, 50, 75, 90, 100]) { _ in
                AxisValueLabel()
                    .font(.footnote)
                    .foregroundStyle(.primary)
            }
        }
        .chartYScale(domain: 0...1)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea
                .frame(height: 10)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .frame(height: 100)
    }
}

//            VStack(spacing: 0) {
//                // Etykieta z wartością nad wykresem
//                HStack {
//                    Spacer()
//                        .frame(width: CGFloat(store.readinessValue) / 100 * 300) // Dostosuj 300 do szerokości wykresu
//
//                    Text("\(store.readinessValue)")
//                        .font(.system(size: 14, weight: .bold))
//                        .padding(.horizontal, 10)
//                        .padding(.vertical, 2)
//                        .background(store.readinessLevel.color)
//                        .foregroundStyle(.white)
//                        .clipShape(RoundedRectangle(cornerRadius: 4))
//
//                    Spacer()
//                }
//                .frame(height: 20)
//                

//import ComposableArchitecture
//import SwiftUI
//
//@ViewAction(for: TrainingReadinessFeature.self)
//struct TrainingReadinessView: View {
//
//    // MARK: - Properties
//
//    @Bindable var store: StoreOf<TrainingReadinessFeature>
//
//    var value: Int = 55
//
//    // MARK: - View
//
//    var body: some View {
//        GroupBox {
//            progressBar
//        } label: {
//            HStack {
//                Text("Training Readiness")
//                Spacer()
//                Text(readinessLabel)
//            }
//        }
//        .padding([.leading, .trailing], 8)
//        .foregroundStyle(.secondary)
//        .frame(height: 100)
//    }
//
//    private var readinessLabel: String {
//        switch value {
//        case 85...100: return "Excellent"
//        case 70..<85: return "Good"
//        case 55..<70: return "Fair"
//        case 40..<55: return "Poor"
//        default: return "Very Poor"
//        }
//    }
//
//    private var progressBar: some View {
//        VStack(spacing: 8) {
//            GeometryReader { geometry in
//                let width = geometry.size.width
//
//                ZStack(alignment: .leading) {
//                    // Tło - szare dla całej skali
//                    RoundedRectangle(cornerRadius: 5)
//                        .fill(Color.gray.opacity(0.2))
//                        .frame(height: 10)
//
//                    // Kolorowe segmenty do wartości
//                    HStack(spacing: 0) {
//                        // Segment 0-39 (czerwony)
//                        if value > 0 {
//                            Rectangle()
//                                .fill(Color.red)
//                                .frame(width: width * CGFloat(min(value, 39)) / 100, height: 10)
//                        }
//
//                        // Segment 40-54 (pomarańczowy)
//                        if value > 39 {
//                            Rectangle()
//                                .fill(Color.orange)
//                                .frame(width: width * CGFloat(min(value - 39, 15)) / 100, height: 10)
//                        }
//
//                        // Segment 55-69 (żółty)
//                        if value > 54 {
//                            Rectangle()
//                                .fill(Color.yellow)
//                                .frame(width: width * CGFloat(min(value - 54, 15)) / 100, height: 10)
//                        }
//
//                        // Segment 70-84 (miętowy)
//                        if value > 69 {
//                            Rectangle()
//                                .fill(Color.mint)
//                                .frame(width: width * CGFloat(min(value - 69, 15)) / 100, height: 10)
//                        }
//
//                        // Segment 85-100 (zielony)
//                        if value > 84 {
//                            Rectangle()
//                                .fill(Color.green)
//                                .frame(width: width * CGFloat(min(value - 84, 16)) / 100, height: 10)
//                        }
//                    }
//                    .clipShape(RoundedRectangle(cornerRadius: 5))
//                }
//            }
//            .frame(height: 10)
//
//            // Skala
//            HStack {
//                Text("0")
//                Spacer()
//                Text("25")
//                    .frame(maxWidth: .infinity)
//                Text("50")
//                    .frame(maxWidth: .infinity)
//                Text("75")
//                    .frame(maxWidth: .infinity)
//                Spacer()
//                Text("100")
//            }
//            .font(.footnote)
//            .foregroundStyle(.primary)
//        }
//        .padding(.top, 8)
//    }
//}
