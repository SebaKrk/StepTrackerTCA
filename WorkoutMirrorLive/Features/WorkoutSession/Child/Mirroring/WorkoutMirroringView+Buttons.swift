//
//  WorkoutMirroringView+Buttons.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/08/2025.
//

import ComposableArchitecture
import SwiftUI

extension WorkoutMirroringView {
    
    // MARK: - ToolBar
    
    var activeCameraButtonLabel: some View {
        Button {
            send(.bottomToolBarStateTapped(.camera))
        } label: {
            Label("Camera", systemImage: "camera")
        }
    }

    var activeMusicButtonLabel: some View {
        Button {
            send(.bottomToolBarStateTapped(.music))
        } label: {
            Label("Music", systemImage: "music.note")
        }
    }
    
    var activeVoiceButtonLabel: some View {
        Button {
            send(.bottomToolBarStateTapped(.voice))
        } label: {
            Label("Note", systemImage: "microphone")
        }
    }

    var hideBottomButtons: some View {
        Button {
            send(.bottomToolBarStateTapped(.none))
        } label: {
            Label("Hide bottom bar buttons", systemImage: "chevron.down")
        }
    }
    
    var heartRateZoneButton: some View {
        Button {
            send(.heartRateZoneButtonTapped)
        } label: {
            Image(systemName: "heart.text.clipboard")
        }
    }
    
    var hideAllToolBarButtons: some View {
        Button {
            send(.hideToolBarButtonTapped)
        } label: {
            HStack {
                Spacer().frame(width: 24)
                VStack {
                    Group {
                        Text("7 sierpnia")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white)
                        Text("19:32")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer().frame(width: 24)
            }
            .padding([.top, .bottom], 12)
            
        }
        .glassEffect()
    }

    // MARK: - Camera
    
    var activeCameraButton: some View {
        Button {
            send(.cameraButtonTapped)
        } label: {
            Image(systemName: "camera")
        }
    }
    
    var disableCameraButton: some View {
        Button {
            send(.cameraButtonTapped)
        } label: {
            Image("custom.camera.slash")
        }
    }
    
    var recordCameraButton: some View {
        Button {
            send(.recordButtonTapped)
        } label: {
            if store.recordIsActive {
                Image(systemName: "stop.circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, .primary)
            } else {
                Image(systemName: "record.circle")
            }
        }
    }
    
    // MARK: - Music
    
    var openMusicLibraryButton: some View {
        Button {
            // Akcja
        } label: {
            Image(systemName: "music.note")
        }
    }
    
    var playMusicButton: some View {
        Button {
            send(.playPauseMusicButtonTapped)
        } label: {
            Image(systemName: "play")
        }
    }
    
    var pauseMusicButton: some View {
        Button {
            send(.playPauseMusicButtonTapped)
        } label: {
            Image(systemName: "pause")
        }
    }
    
    var backMusicButton: some View {
        Button {
            send(.backwardMusicButtonTapped)
        } label: {
            Image(systemName: "backward")
        }
    }
    
    var forwardMusicButton: some View {
        Button {
            send(.forwardMusicButtonTapped)
        } label: {
            Image(systemName: "forward")
        }
    }
    
    // MARK: - Voice
    
    var voiceButton: some View {
        Button {
            
        } label: {
            Image(systemName: "microphone")
        }
    }
    
    
}
