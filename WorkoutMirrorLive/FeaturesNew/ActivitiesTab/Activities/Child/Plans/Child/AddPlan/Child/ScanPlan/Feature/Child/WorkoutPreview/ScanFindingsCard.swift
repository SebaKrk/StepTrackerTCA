//
//  ScanFindingsCard.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import SharedModels
import SwiftUI

/// "To check" card above a scanned plan: one row per finding, "OK" where a doubt can be closed by looking at the board.
struct ScanFindingsCard: View {

    let findings: [ScanFinding]
    let onConfirm: (ScanFinding.ID) -> Void

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(findings) { finding in
                    findingRow(finding)
                    if finding.id != findings.last?.id {
                        Divider()
                    }
                }
            }
            .padding(4)
        } label: {
            VStack {
                header
                Divider()
            }
        }
        .styledGroupBox()
    }

    // MARK: - Structure

    private var header: some View {
        HStack {
            Label("To check", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Spacer()
            Text("\(findings.filter(\.isOpen).count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
        }
    }

    private func findingRow(_ finding: ScanFinding) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(finding.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(finding.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            trailing(for: finding)
        }
    }

    @ViewBuilder
    private func trailing(for finding: ScanFinding) -> some View {
        switch finding.severity {
        case .needsConfirmation:
            if finding.isConfirmed {
                confirmedMark
            } else {
                confirmButton(finding.id)
            }
        case .needsFix:
            fixHint
        case .info:
            infoMark
        case .hard:
            EmptyView()
        }
    }

    // MARK: - Implementation

    private func confirmButton(_ id: ScanFinding.ID) -> some View {
        Button {
            onConfirm(id)
        } label: {
            Text("OK")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var confirmedMark: some View {
        Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
    }

    private var fixHint: some View {
        Text("fix in editor")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private var infoMark: some View {
        Image(systemName: "info.circle")
            .foregroundStyle(.secondary)
    }
}
