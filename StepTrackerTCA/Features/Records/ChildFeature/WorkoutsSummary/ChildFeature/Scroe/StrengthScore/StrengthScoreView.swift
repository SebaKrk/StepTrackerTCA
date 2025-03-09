//
//  StrengthScoreView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 09/03/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: StrengthScoreFeature.self)
struct StrengthScoreView: View {
    // MARK: - Properties
    
    @Bindable var store: StoreOf<StrengthScoreFeature>
    
    // MARK: - View
    
    var body: some View {
        ScrollView {
            createScoresContainers()
        }
        .navigationTitle("StrengthScore Score")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarButton
        }
    }
    
    // MARK: - SubView
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    private func createScoresContainers() -> some View {
        ForEach(store.data) { score in
            groupBoxContainer(data: score)
        }
    }
    
    private func groupBoxContainer(data: WorkoutStrength) -> some View {
        GroupBox {
            VStack {
                // tu musze mieć juz przesiana tablice tak zeby nie powtazaly
                buildScoreStack(lastScore: data, goalTarget: nil, bestScore: nil)
                Spacer()
                infoButton
            }
            .frame(minHeight: 150)
        } label: {
            containerHeaderView(data.movement.rawValue)
        }
    }
    
    private func containerHeaderView(_ title: String) -> some View {
        VStack {
            HStack {
                Group {
                    groupBoxHeaderTitle(title)
                    Spacer()
                    containerNavigationButton
                }
                .foregroundStyle(.green)
            }
        }
    }
    private func groupBoxHeaderTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
    }
    
    private var containerNavigationButton: some View {
        Button {
            print("Przejscie do wykresu")
        } label: {
            Image(systemName: "chevron.right")
        }
    }
    
    private var infoButton: some View {
        HStack {
            Spacer()
            Button {
                
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.green)
            }
        }
        .padding(.top,4)
    }
    
    @ViewBuilder
    // TODO: - dostarczy odpowiednie elementy zamiast WorkoutStrength
    private func buildScoreStack(lastScore: WorkoutStrength?, goalTarget: WorkoutStrength?, bestScore: WorkoutStrength?) -> some View {
        VStack {
            createCellScoreView("calendar", "Last", lastScore?.value, lastScore?.date)
            createCellScoreView("target", "Target", goalTarget?.value, goalTarget?.date)
            createCellScoreView("trophy", "Best", bestScore?.value, bestScore?.date)
        }
    }
    
    private func createCellScoreView(_ image: String, _ title: String, _ value: String?, _ date: Date?) -> some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    HStack {
                        Image(systemName: image)
                            .foregroundStyle(.green)
                        Text(title)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                    }
                    .frame(width: geometry.size.width * 0.3, alignment: .leading)
                    
                    Group {
                        if let value = value {
                            Text("\(value) kg")
                                .foregroundStyle(.green)
                        } else {
                            Text("brak")
                                .foregroundStyle(.white)
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .frame(width: geometry.size.width * 0.4, alignment: .center)
                    
                    Group {
                        if let date = date {
                            Text(date, format: .dateTime.day().month().year())
                        } else {
                            Text("-")
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .frame(width: geometry.size.width * 0.28, alignment: .trailing)
                }
                Divider()
            }
        }
    }
    
}

//Text("StrengthScoreFeature - \(store.data.first?.movement.rawValue ?? "kaplica")")
