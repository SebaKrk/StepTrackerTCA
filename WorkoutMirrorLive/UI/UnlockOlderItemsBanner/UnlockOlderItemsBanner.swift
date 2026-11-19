//
//  UnlockOlderItemsBanner.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import SwiftUI

/// The one row that says why the items below it are blurred, and opens the offer of Pro.
struct UnlockOlderItemsBanner: View {

    // MARK: - Properties

    /// Line naming what is locked.
    let title: String

    /// How many items are locked.
    let lockedCount: Int

    /// Called when the banner is tapped.
    let onUnlock: () -> Void

    // MARK: - Body (structure)

    var body: some View {
        Button {
            onUnlock()
        } label: {
            content
        }
        .buttonStyle(.plain)
        .padding(4)
    }

    private var content: some View {
        HStack(spacing: 12) {
            crownBadge
            titles
            Spacer()
            unlockLabel
        }
        .padding(12)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            border
        }
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 2) {
            titleText
            lockedCountText
        }
    }

    // MARK: - Implementation

    private var crownBadge: some View {
        Image(systemName: "crown.fill")
            .font(.subheadline)
            .foregroundStyle(.yellow)
            .frame(width: 36, height: 36)
            .background(.yellow.opacity(0.15), in: Circle())
    }

    private var titleText: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    private var lockedCountText: some View {
        Text("Locked: \(lockedCount)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var unlockLabel: some View {
        Text("Unlock")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(gold, in: Capsule())
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(gold, lineWidth: 2)
    }

    // Gold on purpose, the same as every other lock: it must not follow the readiness colour.
    private var gold: LinearGradient {
        LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
    }
}
