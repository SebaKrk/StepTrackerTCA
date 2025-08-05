//
//  CountDownView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 05/08/2025.
//

import ComposableArchitecture
import SwiftUI

struct CountDownView: View {
    
    let store: StoreOf<CountDownFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                Circle()
                    .stroke(.gray, style: .init(lineWidth: 20))
                
                Circle()
                    .trim(from: 0, to: store.trimValue)
                    .stroke(.pink, style: .init(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(store.isSettingTrim ? nil : .linear(duration: 1), value: store.timeRemaining)
                    .overlay {
                        Text("\(Int(store.timeRemaining))")
                            .font(.system(size: 60))
                            .foregroundColor(.pink)
                            .fontWeight(.bold)
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.easeInOut, value: store.timeRemaining)
                    }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            store.send(.onAppear)
        }
    }
    
}
