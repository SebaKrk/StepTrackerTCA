//
//  GlassButton.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 01/08/2025.
//

import SwiftUI

/// A reusable button with a glass effect and SF Symbol icon.
/// - Parameters:
///   - name: The SF Symbol name for the button icon.
///   - action: The closure to execute when the button is tapped.
struct GlassButton: View {
    
    // MARK: - Properties
    
    /// The SF Symbol name used as the button's icon.
    let name: String
    
    /// The closure executed when the button is tapped.
    let action: () -> Void
    
    // MARK: - Lifecycle
    
    init(_ name: String, action: @escaping () -> Void) {
        self.name = name
        self.action = action
    }

    // MARK: - Body
    var body: some View {
        Button(action: action) {
            GlassImage(name)
        }
        //.tint(.primary)
    }
}
