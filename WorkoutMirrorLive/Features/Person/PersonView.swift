//
//  PersonView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 10/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: PersonFeature.self)
struct PersonView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<PersonFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            if let status = store.authorizationStatus {
                if status == true {
                    VStack {
                        Text("Authorization status: \(String(describing: status))")
                        Button {
                            send(.debugAuthorizationStatuses)
                        } label: {
                            Text("debug authorizationStatuses")
                        }
                    }
                } else {
                    VStack {
                        Text("Authorization status: \(String(describing: status))")
                        Button {
                            send(.requestAuthorizationButtonTapped)
                        } label: {
                            Text("Request Authorization")
                        }
                    }
                }
            } else {
                Text("Bład brak danych")
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
}

//            if let status = store.authorizationStatus {
//                if status == false {
//                    VStack {
//                        Text("Authorization status: \(status)")
//                        Button {
//                            send(.requestAuthorizationButtonTapped)
//                        } label: {
//                            Text("Request Authorization")
//                        }
//                    }
//                } else {
//                    Text("Authorization status: \(status)")
//                        .onAppear {
//                            send(.viewDidAppear)
//                        }
//                }
//            } else {
//                Text("PersonFeature")
//            }
//        }
