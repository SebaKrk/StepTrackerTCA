//
//  MetricBadge.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/01/2026.
//

import SwiftUI

struct MetricBadge: View {
    
    let value: String
    let color: Color
    let style: BadgeStyle
    let suffix: String?
    
    init(value: String, color: Color, style: BadgeStyle, suffix: String? = nil) {
        self.value = value
        self.color = color
        self.style = style
        self.suffix = suffix
    }
    
    enum BadgeStyle {
        case percentage    // 75% w kółku
        case heartRate     // ❤️ + 123 BPM
        case energy        // 🔥 + 456 kcal
        case plainValue    // 123 BPM (bez ikony)
        
        var icon: String? {
            switch self {
            case .percentage: nil
            case .heartRate: "heart.fill"
            case .energy: "flame.fill"
            case .plainValue: nil
            }
        }
        
        var iconColor: Color? {
            switch self {
            case .heartRate: .red
            case .energy: .pink
            default: nil
            }
        }
        
        var circleSize: CGFloat {
            switch self {
            case .percentage: 18
            default: 0
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .percentage: 8
            case .heartRate: 11
            case .energy: 10
            case .plainValue: 11
            }
        }
    }
    
    var body: some View {
        Group {
            switch style {
            case .percentage:
                percentageView
            case .heartRate, .energy:
                iconValueView
            case .plainValue:
                plainValueView
            }
        }
        .fixedSize()
    }
    
    private var percentageView: some View {
        ZStack {
            Circle()
                .strokeBorder(color, lineWidth: 2)
                .frame(width: style.circleSize, height: style.circleSize)
            
            Text(value)
                .font(.system(size: style.fontSize, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(2)
    }
    
    private var iconValueView: some View {
        HStack(spacing: 3) {
            if let icon = style.icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(style.iconColor ?? color)
            }
            
            Text(value)
                .font(.system(size: style.fontSize, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            if let suffix = suffix {
                Text(suffix)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(color.opacity(0.6))
            }
        }
    }
    
    private var plainValueView: some View {
        HStack(spacing: 2) {
            Text(value)
                .font(.system(size: style.fontSize, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            if let suffix = suffix {
                Text(suffix)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(color.opacity(0.6))
            }
        }
    }
    
}
