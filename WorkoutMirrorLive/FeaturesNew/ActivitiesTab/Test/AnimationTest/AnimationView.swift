//
//  AnimationView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: AnimationFeature.self)
struct AnimationView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<AnimationFeature>
    
    @State var showAvatar: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            rootView
                .animation(.smooth(duration: 1.8), value: store.counter) // Dodane nowe makro
        }
    }
    
    var rootView: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Porównanie animacji")
                    .font(.title)
                    .fontWeight(.bold)
                
                if showAvatar {
                    Image(systemName: "star")
                        .transition(.scale)
                } else {
                    Image(systemName: "star.fill")
                }
                
                Button {
                    withAnimation {
                        showAvatar.toggle()
                    }
                } label: {
                    Text("zmien")
                }
                
                Text("Aktualna wartość: \(Int(store.counter))")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .contentTransition(.numericText(value: Double(store.counter))) // Konwersja Float na Double
                    .animation(.smooth(duration: 1.0), value: store.counter)
                
                // Różne typy animacji dla tej samej wartości
                VStack(spacing: 25) {
                    
                    AnimationRow(
                        title: "Bouncy",
                        counter: store.counter,
                        animation: .bouncy(duration: 1.0)
                    )
                    
                    AnimationRow(
                        title: "Spring",
                        counter: store.counter,
                        animation: .spring(response: 0.6, dampingFraction: 0.8)
                    )
                    
                    AnimationRow(
                        title: "Ease In Out",
                        counter: store.counter,
                        animation: .easeInOut(duration: 1.0)
                    )
                    
//                    AnimationRow(
//                        title: "Linear",
//                        counter: store.counter,
//                        animation: .linear(duration: 1.0)
//                    )
//
//                    // Odkomentowane animacje z nowymi makrami
//                    AnimationRow(
//                        title: "Smooth",
//                        counter: store.counter,
//                        animation: .smooth(duration: 1.0)
//                    )
//
//                    AnimationRow(
//                        title: "Snappy",
//                        counter: store.counter,
//                        animation: .snappy(duration: 0.8)
//                    )
//
//                    AnimationRow(
//                        title: "Interpolating Spring",
//                        counter: store.counter,
//                        animation: .interpolatingSpring(stiffness: 50, damping: 8)
//                    )
                    
                    // Bez animacji dla porównania
                    HStack {
                        Text("Bez animacji:")
                            .font(.headline)
                            .frame(width: 120, alignment: .leading)
                        
                        Text("\(Int(store.counter))")
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .contentTransition(.numericText(value: Double(store.counter))) // Konwersja Float na Double
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .transition(.push(from: .bottom)) // Dodane nowe makro
                }
                .animation(.smooth(duration: 1.8), value: store.counter) // Dodane nowe makro dla całego VStack
                
                // Przyciski kontrolne
                HStack(spacing: 15) {
                    Button("+ 10") {
                        send(.incrementButtonTapped)
                    }
                    .buttonStyle(.borderedProminent)
                    .transition(.push(from: .bottom)) // Dodane nowe makro
                    
                }
                .padding(.top)
                .animation(.smooth(duration: 1.0), value: store.counter) // Dodane nowe makro
            }
            .padding()
        }
        .transition(.push(from: .bottom)) // Dodane nowe makro dla całego ScrollView
    }
    
}
