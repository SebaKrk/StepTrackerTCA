//
//  ScanPlanView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI
import SharedModels

@ViewAction(for: ScanPlanFeature.self)
struct ScanPlanView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ScanPlanFeature>

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
                VStack(spacing: 24) {
                    switch store.viewState {
                    case .idle:
                        idleSection

                    case .imageSelected:
                        imagePreviewSection

                    case .processingOCR:
                        imagePreviewSection
                        processingSection

                    case .textReady:
                        smallImagePreviewSection
                        textEditorSection
                        previewButtonSection

                    case let .unavailable(message):
                        unavailableSection(message: message)

                    case let .failed(error):
                        failedSection(error: error)
                    }
                }
                .padding()
            }

            switch store.viewState {
            case .idle, .imageSelected:
                actionButtonsSection
                    .padding(.horizontal)
                    .padding(.bottom)
            default:
                EmptyView()
            }
        }
        .background(
            LinearGradient(
                colors: [store.color.opacity(0.25), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("Scan Plan")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $store.isPickerPresented,
                      selection: $store.selectedItem)
        .onChange(of: store.selectedItem) { _, newItem in
            send(.selectedPhotoChanged(newItem))
        }
        .navigationDestination(
            item: $store.scope(state: \.workoutPreview, action: \.destination.workoutPreview)
        ) { previewStore in
            WorkoutPreviewView(store: previewStore)
        }
    }

    // MARK: - Idle

    private var idleSection: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(store.color)

            Text("Select a photo of your workout plan")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Image Preview

    private var imagePreviewSection: some View {
        Group {
            if let data = store.selectedImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            }
        }
    }

    private var smallImagePreviewSection: some View {
        Group {
            if let data = store.selectedImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if store.viewState == .idle {
                Button {
                    send(.selectPhotoTapped)
                } label: {
                    Label("Select Photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(store.color)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            } else if store.viewState == .imageSelected {
                Button {
                    send(.extractTextTapped)
                } label: {
                    Label("Extract Text", systemImage: "text.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(store.color)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

                Button {
                    send(.clearImageTapped)
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Processing

    private var processingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)

            Text("Extracting text...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    // MARK: - Text Editor

    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extracted Text")
                .font(.headline)

            TextEditor(text: $store.extractedText)
                .frame(minHeight: 200)
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Preview Button

    private var previewButtonSection: some View {
        Button {
            send(.previewWorkoutTapped)
        } label: {
            Label("Preview Workout", systemImage: "eye")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(store.color)
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
    }

    // MARK: - Unavailable

    private func unavailableSection(message: String) -> some View {
        ContentUnavailableView {
            Label("Feature Unavailable", systemImage: "exclamationmark.applewatch")
        } description: {
            Text(message)
        } actions: {
            Button {
                send(.retryTapped)
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .tint(store.color)
            .controlSize(.large)
        }
    }

    // MARK: - Failed

    private func failedSection(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                send(.retryTapped)
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(store.color)
            .controlSize(.large)
        }
        .padding(.top, 40)
    }
}
