//
//  ExerciseInfoView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/02/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ExerciseInfoFeature.self)
struct ExerciseInfoView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ExerciseInfoFeature>
    
    // MARK: - View
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 20)
            Text("Clean & Jerk")
                .font(.system(size: 22, weight: .regular, design: .monospaced))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundStyle(.green)
            
            Text("""
            A fundamental Olympic weightlifting movement consisting of two explosive phases: **the clean**, where the barbell is lifted to the shoulders, and **the jerk**, where it is pushed overhead. 
            
            This exercise builds **strength, speed, and coordination**, making it essential for power development and athletic performance.
            """)
            .font(.system(size: 16, weight: .semibold, design: .monospaced))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
}
