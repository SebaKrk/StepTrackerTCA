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
import VisionKit

@ViewAction(for: ScanPlanFeature.self)
struct ScanPlanView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ScanPlanFeature>

    /// Keyboard focus for the extracted-text editor (same pattern as SummaryView).
    @FocusState private var isTextEditorFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            switch store.viewState {
            case .idle:
                idleSection

            case .loadingPhoto:
                loadingPhotoSection

            case .processingOCR:
                // Show image only during OCR, not during parsing
                if store.extractedText.isEmpty {
                    imagePreviewSection
                }
                processingSection

            case .textReady:
                textReadyView

            case let .failed(error):
                failedSection(error: error)
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
        .toolbar {
            apiKeyToolbarItem
        }
        .sheet(item: $store.scope(state: \.apiKeyEntry, action: \.apiKeyEntry)) { store in
            NavigationStack {
                APIKeyEntryView(store: store)
            }
        }
        .photosPicker(isPresented: $store.isPickerPresented,
                      selection: $store.selectedItem)
        .fullScreenCover(isPresented: $store.isCameraPresented) {
            DocumentCameraView { result in
                switch result {
                case let .scanned(data):
                    send(.documentScanned(data))
                case .cancelled:
                    send(.documentScanned(nil))
                case .failed:
                    send(.documentScanFailed)
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: store.selectedItem) { _, newItem in
            send(.selectedPhotoChanged(newItem))
        }
        .navigationDestination(
            item: $store.scope(state: \.workoutPreview, action: \.workoutPreview)
        ) { previewStore in
            WorkoutPreviewView(store: previewStore)
        }
    }

    // MARK: - Idle

    private var idleSection: some View {
        VStack(spacing: 24) {
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
            actionButtonsSection
                .padding(.horizontal)
                .padding(.bottom)
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
            if VNDocumentCameraViewController.isSupported {
                takePhotoButton
            }
            selectPhotoButton
        }
    }

    private var takePhotoButton: some View {
        Button {
            send(.takePhotoTapped)
        } label: {
            Label("Take Photo", systemImage: "doc.viewfinder")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(store.color)
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
    }

    private var selectPhotoButton: some View {
        Button {
            send(.selectPhotoTapped)
        } label: {
            Label("Select Photo", systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(store.color)
        .controlSize(.large)
    }

    // MARK: - Loading Photo

    private var loadingPhotoSection: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .controlSize(.large)

            Text("Loading photo...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            cancelLoadingButton
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cancelLoadingButton: some View {
        Button {
            send(.clearImageTapped)
        } label: {
            Text("Cancel")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Processing

    private var processingSection: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .controlSize(.large)

            // Show different text based on whether we're doing OCR or parsing
            Text(store.extractedText.isEmpty ? "Extracting text..." : "Parsing workout...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Text Ready View

    private var textReadyView: some View {
        ScrollView {
            VStack(spacing: 24) {
                smallImagePreviewSection
                textEditorSection
                continueButtonSection
                startOverButton
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            isTextEditorFocused = false
        }
    }

    // MARK: - Text Editor

    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extracted Text")
                .font(.headline)

            TextEditor(text: $store.extractedText)
                .focused($isTextEditorFocused)
                .frame(minHeight: 200)
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Continue Button

    private var continueButtonSection: some View {
        Button {
            send(.continueButtonTapped)
        } label: {
            Label("Continue", systemImage: "arrow.right.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(store.color)
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
    }

    // MARK: - Start Over Button

    private var startOverButton: some View {
        Button {
            send(.clearImageTapped)
        } label: {
            Label("Start Over", systemImage: "arrow.counterclockwise")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Failed

    private func failedSection(error: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                send(.retryTapped)
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(store.color)
            .controlSize(.large)

            if store.failedStage == .parsing && !store.extractedText.isEmpty {
                editTextButton
            }

            startOverButton
        }
        .padding(.top, 40)
    }

    private var editTextButton: some View {
        Button {
            send(.editTextTapped)
        } label: {
            Label("Edit Text", systemImage: "pencil")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(store.color)
        .controlSize(.large)
    }

    // MARK: - API Key Toolbar

    private var shouldShowApiKeyButton: Bool {
        switch store.viewState {
        case .idle, .failed:
            return true
        default:
            return false
        }
    }

    @ToolbarContentBuilder
    private var apiKeyToolbarItem: some ToolbarContent {
        if shouldShowApiKeyButton {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    send(.apiKeySettingsTapped)
                } label: {
                    Image(systemName: "key")
                }
            }
        }
    }

}
