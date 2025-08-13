//
//  LoadingView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 05/08/2025.
//

import SwiftUI

struct LoadingView: View {
    
    let message: String
    let onAppear: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.body)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear(perform: onAppear)
    }
}
