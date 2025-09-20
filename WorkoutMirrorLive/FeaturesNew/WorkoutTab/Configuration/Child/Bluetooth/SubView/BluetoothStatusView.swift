//
//  BluetoothStatusView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/09/2025.
//

import SwiftUI
import HealthHub

struct BluetoothStatusView: View {
    
    var bluetoothStatus: BluetoothStatus
    
    let showActions: Bool
    
    let onAction: (() -> Void)?
    
    
    // MARK: - Lifecycle
    
    init(bluetoothStatus: BluetoothStatus,
         showActions: Bool = false,
         onAction: (() -> Void)? = nil) {
        self.bluetoothStatus = bluetoothStatus
        self.showActions = showActions
        self.onAction = onAction
    }
    
    // MARK: - Body
    
    var body: some View {
        ContentUnavailableView {
            VStack {
                Image(bluetoothStatus.image)
                    .renderingMode(.template)
                    .foregroundStyle(.primary)
                Text(bluetoothStatus.title)
            }
            
        } description: {
            Text(bluetoothStatus.description)
        } actions: {
            if showActions, let onAction {
                Button {
                    onAction()
                } label: {
                    VStack {
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 25))
                            .padding(.bottom, 1)
                        Text(bluetoothStatus.labelText)
                            .font(.footnote)
                    }
                    .foregroundStyle(.blue)
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.secondary)
        .padding()
    }

}

#Preview {
    BluetoothStatusView(bluetoothStatus: .disabled, showActions: true) {}
}


