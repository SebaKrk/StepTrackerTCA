//
//  ActivityPickerView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 24/08/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

@ViewAction(for: ActivityPickerFeature.self)
struct ActivityPickerView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<ActivityPickerFeature>
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(store.workouts, id: \.self) { option in
                Button {
                    send(.buttonTapped(option))
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: option.iconName)
                            .frame(width: 55, height: 55)
                            .glassEffect(.regular.interactive(true), in: .capsule)
                            .animation(.snappy, value: store.selected == option)
                            .foregroundStyle(store.selected == option ? .pink : .secondary)
                        
                        Text(option.title)
                            .font(.footnote)
                            .foregroundStyle(store.selected == option ? .pink : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(store.selected == option ? .isSelected : [])
            }
        }
    }
    
}
