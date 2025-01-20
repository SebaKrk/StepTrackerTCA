//
//  ChartContentUnavailable.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 20/01/2025.
//

import SwiftUI

struct ChartContentUnavailable: View {
    
    var body: some View {
        ContentUnavailableView("Brak danych",
                               systemImage: "exclamationmark.triangle",
                               description: Text("Nie znaleziono żadnych danych. Dodaj nowe dane, aby je zobaczyć."))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.secondary)
        .padding()
    }
    
}
