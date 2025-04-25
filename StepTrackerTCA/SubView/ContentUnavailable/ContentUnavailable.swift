//
//  ContentUnavailable.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import SwiftUI

struct ContentUnavailable: View {
    
    let showActions: Bool
    let onAction: (() -> Void)?
    
    init(showActions: Bool = false, onAction: (() -> Void)? = nil) {
        self.showActions = showActions
        self.onAction = onAction
    }

    var body: some View {
        ContentUnavailableView {
            Label("No data", systemImage: "chart.bar.doc.horizontal")
        } description: {
            Text("No data found. Add new data to see results.")
        } actions: {
            if showActions, let onAction {
                Button {
                    onAction()
                } label: {
                    Image(systemName: "plus")
                        .bold()
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.secondary)
        .padding()
    }
    
}
