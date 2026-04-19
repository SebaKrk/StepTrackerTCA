//
//  ChartContentUnavailable.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/04/2026.
//

import SwiftUI

struct ChartContentUnavailable: View {

    let systemImage: String
    let description: String

    init(
        systemImage: String = "chart.bar.doc.horizontal",
        description: String = String(localized: "No data found. Add new data to see results.", bundle: .main)
    ) {
        self.systemImage = systemImage
        self.description = description
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(description)
                .foregroundStyle(.secondary)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
