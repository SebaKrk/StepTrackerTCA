//
//  SettingsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 22/08/2025.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@ViewAction(for: SettingsFeature.self)
struct SettingsView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<SettingsFeature>
    
    @State private var progress: CGFloat = 0
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            rootView
                .toolbar {
                    toolbarButton
                }
        }
    }
    
    var rootView: some View {
        List {
            Section("Preview") {
                ZStack {
                    ExpandableHorizontalGlassContainer(progress: progress) {
                        Image(systemName: "suit.heart.fill")
                        
                        Image(systemName: "square.and.arrow.up.fill")
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
                .padding(15)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .background {
                    backgroundGradient
                }
                .clipShape(.rect(cornerRadius: 22))
            }
            
            Section("Properties") {
                Slider(value: $progress)
                    .padding(.horizontal, 20)
                Button("Toggle Actions") {
                    withAnimation(.bouncy(duration: 1, extraBounce: 0.07)) {
                        progress = progress == 0 ? 1 : 0
                    }
                }
                .buttonStyle(.glassProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.xMarkButtonTapped)
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.black, .gray, .black]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
}

struct ExpandableHorizontalGlassContainer<Content: View, Label: View>: View, Animatable {
    
    var placeAtLeading: Bool = false
    var isInteractive: Bool = true
    var size: CGSize = .init(width: 55, height: 55)
    var progress: CGFloat
    @ViewBuilder var content: Content
    @ViewBuilder var label: Label

    @State private var labelPosition: CGRect = .zero
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            HStack(spacing: spacing) {
                if placeAtLeading {
                    LabelView()
                }
                ForEach(subviews: content) { subview in
                    subview
                        .blur(radius: 12 * scaleProgress)
                        .opacity(progress)
                        .frame(width: size.width, height: size.height)
                        .glassEffect(.regular.interactive(isInteractive), in: .capsule)
                        .allowsHitTesting(progress == 1)
                        .visualEffect { [labelPosition] content, proxy in
                            content
                                .offset(x: offsetX(proxy: proxy, labelPosition: labelPosition))
                        }
                        .fixedSize()
                        .frame(width: size.width * progress)
                }
                if !placeAtLeading {
                    LabelView()
                }
            }
        }
        .coordinateSpace(.named("CONTAINER"))
    }
    
    @ViewBuilder
    private func LabelView() -> some View {
        label
            .compositingGroup()
            .blur(radius: 12 * scaleProgress)
            .frame(width: size.width, height: size.height)
            .glassEffect(.regular.interactive(isInteractive), in: .capsule)
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .named("CONTAINER"))
            } action: { newValue in
                labelPosition = newValue
            }
    }
    
    nonisolated
    func offsetX(proxy: GeometryProxy, labelPosition: CGRect) -> CGFloat {
        let minX = labelPosition.minX - proxy.frame(in: .named("CONTAINER")).minX
        return minX - (minX * progress)
    }
    
    var scaleProgress: CGFloat {
        return progress > 0.5 ? (1 - progress) / 0.5 : (progress / 0.5)
    }
    
    var spacing: CGFloat {
        10.0  * progress
    }
}
