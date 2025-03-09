//
//  StrengthScoreView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 09/03/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: StrengthScoreFeature.self)
struct StrengthScoreView: View {
    // MARK: - Properties
    
    @Bindable var store: StoreOf<StrengthScoreFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("StrengthScoreFeature - \(store.data.first?.movement.rawValue ?? "kaplica")")
    }
    
}
