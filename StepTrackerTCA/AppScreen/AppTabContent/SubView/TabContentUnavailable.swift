//
//  TabContentUnavailable.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import SwiftUI

struct TabContentUnavailable: View {
    
    var body: some View {
        ContentUnavailableView(
            "Select a Tab",
            systemImage: "list.bullet.rectangle",
            description: Text("Please choose an option from the tab bar list.")
        )
    }
}
