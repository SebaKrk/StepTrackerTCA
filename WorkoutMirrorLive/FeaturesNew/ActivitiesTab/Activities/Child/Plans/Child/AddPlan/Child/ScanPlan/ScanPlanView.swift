//
//  ScanPlanView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import ComposableArchitecture
import HealthHub
import PhotosUI
import SwiftUI
import SharedModels

@ViewAction(for: ScanPlanFeature.self)
struct ScanPlanView: View {

    // MARK: - Properties

    /// Scan flow: photo, crop, reading by the AI and the preview.
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

            case .analyzing:
                // Show image only during OCR, not during parsing
                if store.extractedText.isEmpty {
                    imagePreviewSection
                }
                processingSection

            case .textReady:
                textReadyView

            case let .failed(failure):
                failedSection(failure)
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
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $store.scope(state: \.photoCrop, action: \.photoCrop)) { cropStore in
            PhotoCropView(store: cropStore)
        }
        .photosPicker(isPresented: $store.isPickerPresented,
                      selection: $store.selectedItem)
        .fullScreenCover(isPresented: $store.isCameraPresented, onDismiss: { send(.cameraDismissed) }) {
            BoardCameraView { result in
                switch result {
                case let .captured(data):
                    send(.cameraPhotoTaken(data))
                case .cancelled:
                    send(.cameraPhotoTaken(nil))
                case .failed:
                    send(.cameraFailed)
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
            #if DEBUG
            debugPickersSection
                .padding(.horizontal)
            #endif
        }
        .padding(.bottom)
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
            if store.isCameraAvailable {
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

            Text(processingLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var processingLabel: LocalizedStringKey {
        if !store.parsingBackend.showsTextStep { return "Analyzing photo..." }
        return store.extractedText.isEmpty ? "Extracting text..." : "Parsing workout..."
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

    // MARK: - Parsing Backend and Model (DEBUG)

    #if DEBUG
    /// Backend on the left, model on the right — two menus sharing one row.
    private var debugPickersSection: some View {
        HStack {
            parsingBackendPicker
            Spacer()
            scanModelPicker
        }
    }

    private var parsingBackendPicker: some View {
        Picker(selection: parsingBackendBinding) {
            ForEach(WorkoutParsingBackend.allCases, id: \.self) { backend in
                Text(backend.rawValue)
            }
        } label: {
            Text("Parsing backend")
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }

    private var parsingBackendBinding: Binding<WorkoutParsingBackend> {
        Binding(
            get: { store.parsingBackend },
            set: { send(.parsingBackendChanged($0)) }
        )
    }

    /// Only the development deployment honours this; elsewhere the server decides.
    private var scanModelPicker: some View {
        Picker(selection: scanModelBinding) {
            ForEach(ScanModelChoice.allCases, id: \.self) { model in
                Text(model.displayName)
            }
        } label: {
            Text("Scan model")
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }

    private var scanModelBinding: Binding<ScanModelChoice> {
        Binding(
            get: { store.scanModel },
            set: { send(.scanModelChanged($0)) }
        )
    }
    #endif

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

    private func failedSection(_ failure: ScanFailure) -> some View {
        ContentUnavailableView {
            Label(failure.title, systemImage: failedSymbol)
        } description: {
            Text(failure.message)
                .font(.subheadline)
        } actions: {
            failedActions(failure)
        }
    }

    /// One way forward plus a reset — retrying where it can work, manual entry where it cannot.
    @ViewBuilder
    private func failedActions(_ failure: ScanFailure) -> some View {
        if failure.canRetry {
            retryButton
        } else {
            addManuallyButton
        }

        if showsEditTextButton {
            editTextButton
        }

        startOverButton
    }

    private var retryButton: some View {
        Button {
            send(.retryTapped)
        } label: {
            Label(retryTitle, systemImage: "arrow.clockwise")
        }
        .buttonStyle(.borderedProminent)
        .tint(store.color)
    }

    private var addManuallyButton: some View {
        Button {
            send(.addManuallyTapped)
        } label: {
            Label(addManuallyTitle, systemImage: "square.and.pencil")
        }
        .buttonStyle(.borderedProminent)
        .tint(store.color)
    }

    /// A parsing failure keeps the OCR text, so editing it is a real second chance.
    private var showsEditTextButton: Bool {
        store.failedStage == .parsing
            && store.parsingBackend.showsTextStep
            && !store.extractedText.isEmpty
    }

    private var editTextButton: some View {
        Button {
            send(.editTextTapped)
        } label: {
            Label(editTextTitle, systemImage: "pencil")
        }
        .buttonStyle(.bordered)
        .tint(store.color)
    }

    // MARK: - Copy

    private let failedSymbol = "exclamationmark.triangle"
    private let retryTitle = String(localized: "Retry")
    private let addManuallyTitle = String(localized: "Add plan manually")
    private let editTextTitle = String(localized: "Edit Text")
}

// MARK: - Previews

/// Renders the failure screen for one error, so every variant is reviewable.
private func failurePreview(
    _ error: ScanProxyError,
    stage: ScanPlanFeature.FailedStage = .parsing,
    extractedText: String = ""
) -> some View {
    var state = ScanPlanFeature.State()
    state.viewState = .failed(error.scanFailure)
    state.failedStage = stage
    state.extractedText = extractedText
    // Only the text backend keeps an editable transcript worth offering back.
    state.$parsingBackend.withLock { $0 = extractedText.isEmpty ? .claudeVision : .claudeText }

    return NavigationStack {
        ScanPlanView(store: Store(initialState: state) { ScanPlanFeature() })
    }
}

/// Tomorrow at midnight — fixed so the preview copy does not drift by the hour.
private let previewReset = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)

#Preview("limit wyczerpany") {
    failurePreview(.dailyLimitReached(resetsAt: previewReset))
}

#Preview("limit bez godziny") {
    failurePreview(.dailyLimitReached(resetsAt: nil))
}

#Preview("brak połączenia") {
    failurePreview(.network)
}

#Preview("usługa niedostępna") {
    failurePreview(.serviceUnavailable)
}

#Preview("zbyt wiele żądań") {
    failurePreview(.rateLimited)
}

#Preview("plan za długi") {
    failurePreview(.truncated)
}

#Preview("złe zdjęcie") {
    failurePreview(.invalidImage, stage: .photoLoad)
}

#Preview("brak logowania") {
    failurePreview(.notSignedIn, stage: .photoLoad)
}

#Preview("nieoczekiwana odpowiedź") {
    failurePreview(.invalidResponse)
}

#Preview("błąd po naszej stronie") {
    failurePreview(.invalidRequest)
}

#Preview("model odmówił") {
    failurePreview(.refused)
}

#Preview("z edycją tekstu") {
    failurePreview(.serviceUnavailable, extractedText: "FRAN\n21-15-9\nThrusters 43 kg\nPull-ups")
}
