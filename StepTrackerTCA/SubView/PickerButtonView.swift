//
//  PickerButtonView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/05/2025.
//

import SwiftUI

struct PickerButtonView<Option: ButtonActionOption>: View {
    
    @Binding var selectedOption: Option
    
    var tint: Color = .pink
    
    var action: (Option) -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                action(selectedOption)
            } label: {
                Label(selectedOption.name, systemImage: selectedOption.icon)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(tint)
            }
            Spacer()
            Menu {
                ForEach(Option.allCases, id: \.self) { option in
                    Button {
                        selectedOption = option
                    } label: {
                        Text(option.actionDescription)
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(tint)
                    .padding(.horizontal, 8)
            }
            Spacer()
        }
        .padding()
        .background(tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint, lineWidth: 0.5)
        )
        .buttonStyle(PlainButtonStyle())
    }
    
}
