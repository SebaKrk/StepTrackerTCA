//
//  SplashView.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 18/05/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SplashFeature.self)
struct SplashView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<SplashFeature>
    
    // MARK: - View
    
    var body: some View {
        if store.isActive {
            ContentView()
        } else {
            VStack {
                Text("My Fitness Journal")
                    .font(.title2)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.pink)
                
                Text("Let’s get moving!")
                    .font(.caption)
            }
            .onAppear {
                send(.viewDidAppear)
            }
        }
    }
    
}


//    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//        withAnimation {
//            send(.showMainApp)
//        }
//    }
