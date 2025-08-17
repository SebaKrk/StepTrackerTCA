//
//  WorkoutMirroringView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/07/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutMirroringFeature.self)
struct WorkoutMirroringView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<WorkoutMirroringFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    activeWorkoutView
                    GlassFolderContainer(corner: 32) {
                        Text("aaaa")
                    }
                    
                    GlassEffectContainer {
                        Text("aaaa")
                            .padding(20)
                            .glassEffect(.regular, in: .rect(cornerRadius: 12))
                    }
                    
                }
                controlsView
            }
            //.background(backgroundGradient)
            .navigationTitle("Workout Mirroring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarButton
            }
            .toolbar {
                if !store.isToolbarHidden {
                    bottomToolbarButton
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .toolbarVisibility(store.isToolbarHidden ? .hidden : .visible, for: .automatic)
            .onTapGesture {
                if store.isToolbarHidden {
                    send(.hideToolBarButtonTapped)
                }
            }
            //.toolbar(removing: .title)
            .sheet(item: $store.scope(
                state: \.destination?.heartRateZoneInfo,
                action: \.destination.heartRateZoneInfo)) { store in
                    HeartRateZoneInfoView(store: store)
                        .presentationDetents([.large, .medium])
                }
        }
    }
    
    // MARK: - SubView
    
    @ToolbarContentBuilder
    var bottomToolbarButton: some ToolbarContent {
        
        switch store.mirroringToolBarState {
        case .none: noneToolBar
        case .camera: cameraOptionToolBar
        case .music: musicOptionToolBar
        case .voice: voiceOptionToolBar
        }
    }
    
    @ToolbarContentBuilder
    private var cameraOptionToolBar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            if store.isActiveCamera {
                activeCameraButton
                Spacer()
                recordCameraButton
            } else {
                disableCameraButton
                Spacer()
            }
        }
    }
    
    @ToolbarContentBuilder
    private var musicOptionToolBar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            backMusicButton
            playMusicButton
            forwardMusicButton
            Spacer()
            openMusicLibraryButton
        }
    }
    
    @ToolbarContentBuilder
    private var voiceOptionToolBar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            voiceButton
            Spacer()
        }
    }
    
    @ToolbarContentBuilder
    private var noneToolBar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {}
    }
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                activeCameraButtonLabel
                activeMusicButtonLabel
                activeVoiceButtonLabel
                if store.mirroringToolBarState != .none {
                    hideBottomButtons
                }
            } label: {
                Image(systemName: "gearshape")
            }
        }
        
        ToolbarItem(placement: .title) {
            hideAllToolBarButtons
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            if store.workoutSessionState == .paused {
                Button {
                    send(.endWorkoutButtonTapped)
                } label: {
                    Image(systemName: "xmark")
                }
                .foregroundColor(.red)
                
            } else {
                heartRateZoneButton
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
    
    private var activeWorkoutView: some View {
        GlassEffectContainer {
            VStack {
                heartRateView
                Spacer().frame(height: 10)
                currentHeartRatePercentageView
                activeEnergyBurnedView
                Spacer().frame(height: 10)
                currentHeartRateZoneView
            }
            .frame(minHeight: 220)
            .padding([.leading, .trailing], 8)
        }
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 12))
        .padding()
    }
    
    private var controlsView: some View {
        GlassEffectContainer {
            VStack {
                HStack {
                    activityIcon
                    Spacer()
                    timeLineView
                    Spacer()
                    ActivityRingsView(move: 22, exercise: 32, stand: 56)
                }
                Spacer().frame(height: 20)
                workoutActionButtonsView
            }
            .padding()
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        //        .glassEffect(.clear.interactive(),in: .rect(cornerRadius: 12))
        //        .padding()
    }
    
    private var heartRateView: some View {
        HStack {
            Group {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(174)")//formatted(.number.precision(.fractionLength(0))))
                Text("BPM")
            }
            .font(.system(.title3, design: .rounded).monospacedDigit())
            .foregroundColor(.primary)
            Spacer()
            
            Text("Anaerobic")
                .font(.title3.weight(.semibold))
                .foregroundColor(.red)//store.currentHeartRateZone.color)
        }
    }
    
    private var currentHeartRatePercentageView: some View {
        VStack(spacing: 5) {
            Text("\(91)%")
                .font(.system(size: 60))
            //                .id(store.currentHeartRatePercentage)
            //                .transition(.push(from: .bottom))
                .animation(.snappy(duration: 0.3), value: 70)
        }
    }
    
    private var activeEnergyBurnedView: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundColor(.pink)
                .font(.system(.title2, design: .rounded))
            Text("\(321)")
            //            Text(Measurement(value: store.workoutMetrics.activeEnergy, unit: .kilocalories).formatted(MetricFormatter.workoutEnergy))
                .font(.system(.title3, design: .rounded).monospacedDigit())
                .foregroundColor(.primary)
            Text("Active\nEnergy")
                .font(.system(.caption, design: .rounded).smallCaps())
        }
    }
    
    private var currentHeartRateZoneView: some View {
        HStack {
            Spacer()
            Text("Anaerobic")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var timeLineView: some View {
        TimelineView(PeriodicTimelineSchedule(from: .now, by: 1.0 / 30.0)) { context in
            makeElapsedTimeView(context)
        }
    }
    
    private func makeElapsedTimeView(_ context: TimelineViewDefaultContext) -> some View {
        ElapsedTimeView(
            elapsedTime: store.elapsedTime,
            showSubseconds: true
        )
        //context.cadence == .live
        //        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.yellow)
        .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
        .onAppear {
            send(.updateElapsedTime(context.date))
        }
        .onChange(of: context.date) { _, newDate in
            send(.updateElapsedTime(newDate))
        }
    }
    
    private var activityIcon: some View {
        Image(systemName: "figure.cross.training.circle.fill")
            .resizable()
            .foregroundStyle(.primary)
            .frame(width: 30, height: 30, alignment: .center)
    }
    
    @ViewBuilder
    private var workoutActionButtonsView: some View {
        switch store.workoutSessionState {
        case .running:
            workoutPauseButton
        case .paused:
            resumeWorkoutButton
        }
    }
    
    private var workoutPauseButton: some View {
        HStack {
            Spacer()
            Button {
                send(.pauseWorkoutButtonTaped(true))
            } label: {
                Image(systemName: "pause")
                    .font(.system(size: 30, weight: .medium))
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                        //.fill(.ultraThinMaterial)
                        //.shadow(radius: 5)
                    )
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
    
    private var resumeWorkoutButton: some View {
        HStack {
            Spacer()
            Button {
                send(.resumeWorkoutButtonTapped(false))
            } label: {
                Image(systemName: "play")
                    .font(.system(size: 30, weight: .medium))
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                    )
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
    
}


//Spacer()
//            Button {
//                // Akcja
//            } label: {
//                Image(systemName: "play")
//                //pause
//            }
//            Button {
//                send(.xMarkButtonTapped)
//            } label: {
//                Image(systemName: "xmark")
//            }
//            Spacer()
//            Button {
//                // Akcja
//            } label: {
//                Image(systemName: "music.note")
//            }

//        GroupBox {
//            VStack {
//                heartRateView
//                Spacer().frame(height: 25)
//                currentHeartRatePercentageView
//                Spacer().frame(height: 25)
//                activeEnergyBurnedView
//            }
//            Spacer().frame(height: 25)
//            currentHeartRateZoneView
//        }
//        .padding()

//        GlassEffectContainer(spacing: 30.0) {
//            HStack {
//                Image(systemName: "sun.max.fill")
//                    .padding()
//
//                Image(systemName: "moon.stars.fill")
//                    .padding()
//
//                Image(systemName: "cloud.rain.fill")
//                    .padding()
//            }
//        }
//        .glassEffect()

//
//@ToolbarContentBuilder
//var toolbarButton2: some ToolbarContent {
//    ToolbarSpacer(.flexible)
//    ToolbarItem(placement: .topBarLeading) {
//        Button {
//
//        } label: {
//            Image(systemName: "square.and.arrow.up")
//        }
//    }
//    ToolbarSpacer(.fixed)
//
//    ToolbarItemGroup {
//        Button {
//
//        } label: {
//            Image(systemName: "heart")
//        }
//        Button {
//
//        } label: {
//            Image(systemName: "snowflake")
//        }
//    }
//    ToolbarSpacer(.fixed)
//    ToolbarItem {
//        Button {
//
//        } label: {
//            Text("Add")
//        }
//    }
//}

struct ActivityRingsView: View {
    var move: Double // 0.0 - 1.0
    var exercise: Double
    var stand: Double
    
    var body: some View {
        ZStack {
            RingView(progress: 1.0, color: .gray, lineWidth: 20)
            RingView(progress: stand, color: .blue, lineWidth: 20)
            RingView(progress: exercise, color: .green, lineWidth: 14)
            RingView(progress: move, color: .red, lineWidth: 8)
        }
        .frame(width: 25, height: 25)
    }
}

struct RingView: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat
    
    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
    }
}

struct GlassFolderContainer<Content: View>: View {
    let corner: CGFloat
    @ViewBuilder var content: () -> Content
    
    init(corner: CGFloat = 36, @ViewBuilder content: @escaping () -> Content) {
        self.corner = corner
        self.content = content
    }
    
    private var shape: some InsettableShape {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
    }
    
    var body: some View {
        // Kontener zbiera i optymalizuje efekty szkła wewnątrz
        GlassEffectContainer {
            content()
                .padding(20)
            // 3D szkło „za” widokiem (grubość, specular, blur, cienie)
            
            //.glassBackgroundEffect(in: shape)                 // iOS 26
            // Efekty „przed” widokiem (highlighty, refrakcja itp.)
                .glassEffect(.regular, in: shape)                 // iOS 26
            // Opcjonalny delikatny „rim”, jak w iOS
                .overlay {
                    shape
                        .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                        .blendMode(.overlay)
                }
            // Lekki cień dla „uniesienia”
                .shadow(color: .black.opacity(0.18), radius: 28, y: 14)
        }
        .clipShape(shape) // poprawny hit-test i antyaliasing krawędzi
    }
}
