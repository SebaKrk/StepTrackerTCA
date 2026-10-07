//
//  OverlayView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 01/10/2025.
//

import SwiftUI

struct OverlayView: View {
    
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

extension OverlayView {
    static func lockedBasic(action: @escaping () -> Void) -> OverlayView {
        OverlayView(
            icon: "lock.fill",
            iconColor: .yellow,
            title: String(localized: "Premium Feature", bundle: .main),
            buttonIcon: "crown.fill",
            buttonText: String(localized: "Unlock Pro", bundle: .main),
            buttonColor: .yellow,
            action: action
        )
    }

    static func lockedPro(action: @escaping () -> Void) -> OverlayView {
        OverlayView(
            icon: "lock.fill",
            iconColor: .orange,
            title: String(localized: "Elite Feature", bundle: .main),
            buttonIcon: "flame.fill",
            buttonText: String(localized: "Go Elite", bundle: .main),
            buttonColor: .orange,
            action: action
        )
    }
    
    static func unauthorized(action: @escaping () -> Void) -> OverlayView {
        OverlayView(
            icon: "heart.text.square.fill",
            iconColor: .red,
            title: String(localized: "Health Access Required", bundle: .main),
            buttonIcon: "heart.fill",
            buttonText: String(localized: "Grant Access", bundle: .main),
            buttonColor: .red,
            action: action
        )
    }
    
    static func error(action: @escaping () -> Void) -> OverlayView {
        OverlayView(
             icon: "exclamationmark.triangle.fill",
             iconColor: .red,
             title: String(localized: "Unable to load data", bundle: .main),
             buttonIcon: "arrow.clockwise",
             buttonText: String(localized: "Try Again", bundle: .main),
             buttonColor: .red,
             action: action
         )
     }
    
    static func noData(action: @escaping () -> Void) -> OverlayView {
        OverlayView(
            icon: "chart.bar.xaxis",
            iconColor: .gray,
            title: String(localized: "No Data Available", bundle: .main),
            buttonIcon: "arrow.clockwise",
            buttonText: String(localized: "Refresh", bundle: .main),
            buttonColor: .gray,
            action: action
        )
    }
}
