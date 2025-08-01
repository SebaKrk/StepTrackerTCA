//
//  GlassImage.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 01/08/2025.
//

import SwiftUI

/// A glass-styled image used inside the GlassButton.
/// - Parameter name: The SF Symbol name for the image.
struct GlassImage: View {
    
    // MARK: - Properties
    
    /// The SF Symbol name used as the image icon.
    let name: String
    
    // MARK: - Lifecycle
    
    init(_ name: String) {
        self.name = name
    }
    
    // MARK: - Body
    
    var body: some View {
        Image(systemName: name)
            .padding()
            .glassEffect()
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.primary)
    }
}
