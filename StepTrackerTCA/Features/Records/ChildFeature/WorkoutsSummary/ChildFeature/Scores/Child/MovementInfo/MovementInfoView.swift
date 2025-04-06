//
//  MovementInfoView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/03/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: MovementInfoFeature.self)
struct MovementInfoView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<MovementInfoFeature>
    
    // MARK: - View
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 20)
            
            if let movement = store.currentMovement {
                Text(movement.title)
                    .font(.system(size: 22, weight: .regular, design: .monospaced))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.green)
                
                Text(movement.description)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
            } else {
                Text("Movement not found")
            }
            Spacer()
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
}
