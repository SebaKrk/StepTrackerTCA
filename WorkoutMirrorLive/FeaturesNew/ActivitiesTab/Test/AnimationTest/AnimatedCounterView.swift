//
//  AnimatedCounterView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import SwiftUI

@Animatable
struct AnimatedCounterView: View {
    var number: Float
    
    var body: some View {
        Text("\(number, specifier: "%.1f")")  // Pokazujemy 1 miejsce po przecinku
            .font(.system(size: 20, weight: .bold, design: .monospaced))
            .foregroundColor(.primary)
            .contentTransition(.numericText(value: Double(number))) // Konwersja Float na Double
    }
}

struct AnimationRow: View {
    let title: String
    let counter: Float
    let animation: Animation
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.headline)
                .frame(width: 120, alignment: .leading)
            
            AnimatedCounterView(number: counter)
                .animation(animation, value: counter)
                .frame(maxWidth: .infinity)
                .transition(.push(from: .bottom)) // Element przychodzi z góry, wypychając poprzedni w dół
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}
