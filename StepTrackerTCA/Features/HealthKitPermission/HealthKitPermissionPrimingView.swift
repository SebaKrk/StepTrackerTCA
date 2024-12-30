//
//  HealthKitPermissionPrimingView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import ComposableArchitecture
import HealthKitUI
import SwiftUI
import Factory

@ViewAction(for: HealthKitPermissionFeature.self)
struct HealthKitPermissionPrimingView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HealthKitPermissionFeature>
    
    var description = """
    This app displays your step and weight data in interactive charts.
    
    You can also add new step or weight data to Apple Health from this app. Your data is private and secured.
    """
    
    // MARK: - Lifecycle
    
    init(store: StoreOf<HealthKitPermissionFeature>) {
        self.store = store
    }
    
    // MARK: - View
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                appleHealthImage
                title
                descriptionSubtitle
                Spacer().frame(height: 100)
            }
            appleHealthButton
        }
        .padding(30)
        .interactiveDismissDisabled()
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Subview
    
    @ViewBuilder
    private var appleHealthImage: some View {
        Image(.appleHealth)
            .resizable()
            .frame(width: 90, height: 90)
            .shadow(color: .gray.opacity(0.3), radius: 16)
            .padding(.bottom, 12)
    }
    
    @ViewBuilder
    private var title: some View {
        Text("Apple Health Integration")
            .font(.title2).bold()
    }
    
    @ViewBuilder
    private var descriptionSubtitle: some View {
        Text(description)
            .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private var appleHealthButton: some View {
        Button {
            send(.appleHealthButtonPressed)
        } label: {
            Text("Connect Apple Health")
        }
        .buttonStyle(.borderedProminent)
        .tint(.pink)
    }
    
}

//#Preview {
//    HealthKitPermissionPrimingView(store: Store(initialState: HealthKitPermissionFeature.State(), reducer: {
//        HealthKitPermissionFeature()
//    }))
//}
