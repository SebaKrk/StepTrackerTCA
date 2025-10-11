//
//  ChartOverlayView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 01/10/2025.
//

import SwiftUI

struct ChartOverlayView: View {
    
    let icon: String
    let iconColor: Color
    let title: String
    let buttonIcon: String
    let buttonText: String
    let buttonColor: Color
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: buttonIcon)
                    Text(buttonText)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(buttonBackground)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        if case .yellow = buttonColor {
            LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            buttonColor
        }
    }
}

extension ChartOverlayView {
    static func locked(action: @escaping () -> Void) -> ChartOverlayView {
        ChartOverlayView(
            icon: "lock.fill",
            iconColor: .yellow,
            title: "Premium Feature",
            buttonIcon: "crown.fill",
            buttonText: "Unlock Premium",
            buttonColor: .yellow,
            action: action
        )
    }
    
    static func unauthorized(action: @escaping () -> Void) -> ChartOverlayView {
        ChartOverlayView(
            icon: "heart.text.square.fill",
            iconColor: .red,
            title: "Health Access Required",
            buttonIcon: "heart.fill",
            buttonText: "Grant Access",
            buttonColor: .red,
            action: action
        )
    }
    
    static func error(action: @escaping () -> Void) -> ChartOverlayView {
         ChartOverlayView(
             icon: "exclamationmark.triangle.fill",
             iconColor: .red,
             title: "Unable to load data",
             buttonIcon: "arrow.clockwise",
             buttonText: "Try Again",
             buttonColor: .red,
             action: action
         )
     }
    
    static func noData(action: @escaping () -> Void) -> ChartOverlayView {
        ChartOverlayView(
            icon: "chart.bar.xaxis",
            iconColor: .gray,
            title: "No Data Available",
            buttonIcon: "arrow.clockwise",
            buttonText: "Refresh",
            buttonColor: .gray,
            action: action
        )
    }
}
