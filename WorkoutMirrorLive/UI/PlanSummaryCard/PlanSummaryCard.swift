//
//  PlanSummaryCard.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import SharedModels
import SwiftUI

/// Plan card of the Plans list — also used wherever the user picks one of their plans.
struct PlanSummaryCard: View {

    // MARK: - Properties

    let session: TrainingSession
    let onTap: () -> Void

    // MARK: - Body (structure)

    var body: some View {
        GroupBox {
            PlanSummaryDetails(session: session)
        } label: {
            cardLabel
        }
        .styledGroupBox()
        .padding(4)
    }

    private var cardLabel: some View {
        VStack {
            headerButton
            Divider()
        }
    }

    private var headerButton: some View {
        Button {
            onTap()
        } label: {
            header
        }
    }

    private var header: some View {
        HStack {
            activityIcon
            headerTitles
            Spacer()
            chevron
        }
    }

    private var headerTitles: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleText
            dateText
        }
    }

    // MARK: - Implementation

    private var activityIcon: some View {
        Image(systemName: session.activity.iconName.replacingOccurrences(of: ".circle.fill", with: ""))
            .resizable()
            .scaledToFit()
            .foregroundColor(.primary)
            .frame(width: 40, height: 40)
    }

    private var titleText: some View {
        Text(session.title)
            .foregroundColor(.primary)
            .font(.title2)
            .bold()
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateText: some View {
        Text(session.date, style: .date)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
    }
}
