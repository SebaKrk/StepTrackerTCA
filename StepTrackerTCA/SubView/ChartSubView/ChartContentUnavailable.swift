//
//  ChartContentUnavailable.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 20/01/2025.
//

import SwiftUI

struct ChartNoDataView: View {
    
    var body: some View {
        ContentUnavailableView("No Data",
                               systemImage: "chart.bar.doc.horizontal",
                               description: Text("No data found. Add new data to see results."))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.secondary)
        .padding()
    }
    
}
