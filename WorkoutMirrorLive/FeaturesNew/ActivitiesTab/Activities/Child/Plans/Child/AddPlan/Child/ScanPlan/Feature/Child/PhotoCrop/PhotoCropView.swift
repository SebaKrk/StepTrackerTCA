//
//  PhotoCropView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: PhotoCropFeature.self)
struct PhotoCropView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<PhotoCropFeature>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                cropCanvas
                hint
                useFullPhotoButton
            }
            .padding()
            .navigationTitle("Crop to the board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { cancelButton }
                ToolbarItem(placement: .confirmationAction) { confirmButton }
            }
        }
    }

    // MARK: - Structure

    private var cropCanvas: some View {
        GeometryReader { geometry in
            if let image = UIImage(data: store.imageData) {
                let frame = fittedFrame(for: image.size, in: geometry.size)
                ZStack(alignment: .topLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: frame.width, height: frame.height)
                        .offset(x: frame.minX, y: frame.minY)
                    dimOutsideCrop(frame: frame)
                    cropBorder(frame: frame)
                    ForEach(corners, id: \.self) { corner in
                        handle(corner, frame: frame)
                    }
                }
                .coordinateSpace(name: canvasSpace)
            }
        }
    }

    private var hint: some View {
        Text("Keep the board, cut out names and faces — only the crop is sent.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Implementation

    private let canvasSpace = "cropCanvas"
    private let corners: [PhotoCropFeature.Corner] = [.topLeft, .topRight, .bottomLeft, .bottomRight]

    private func dimOutsideCrop(frame: CGRect) -> some View {
        Path { path in
            path.addRect(frame)
            path.addRect(cropRect(in: frame))
        }
        .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
        .allowsHitTesting(false)
    }

    private func cropBorder(frame: CGRect) -> some View {
        Rectangle()
            .stroke(Color.white, lineWidth: 2)
            .frame(width: cropRect(in: frame).width, height: cropRect(in: frame).height)
            .offset(x: cropRect(in: frame).minX, y: cropRect(in: frame).minY)
            .allowsHitTesting(false)
    }

    private func handle(_ corner: PhotoCropFeature.Corner, frame: CGRect) -> some View {
        let point = cornerPoint(corner, in: frame)
        return Circle()
            .fill(Color.white)
            .frame(width: 28, height: 28)
            .shadow(radius: 2)
            .position(point)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(canvasSpace))
                    .onChanged { value in
                        send(.cornerMoved(corner, unitPoint(value.location, in: frame)))
                    }
            )
    }

    private var useFullPhotoButton: some View {
        Button {
            send(.useFullPhotoTapped)
        } label: {
            Text("Use the whole photo")
        }
        .buttonStyle(.bordered)
    }

    private var cancelButton: some View {
        Button {
            send(.cancelTapped)
        } label: {
            Text("Cancel")
        }
    }

    private var confirmButton: some View {
        Button {
            send(.confirmTapped)
        } label: {
            if store.isCropping {
                ProgressView()
            } else {
                Text("Use")
                    .fontWeight(.semibold)
            }
        }
        .disabled(store.isCropping)
    }

    // MARK: - Geometry

    /// Where the aspect-fit image lands inside the canvas.
    private func fittedFrame(for imageSize: CGSize, in canvas: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(canvas.width / imageSize.width, canvas.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: (canvas.width - size.width) / 2,
            y: (canvas.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    private func cropRect(in frame: CGRect) -> CGRect {
        let crop = store.crop
        return CGRect(
            x: frame.minX + crop.minX * frame.width,
            y: frame.minY + crop.minY * frame.height,
            width: crop.width * frame.width,
            height: crop.height * frame.height
        )
    }

    private func cornerPoint(_ corner: PhotoCropFeature.Corner, in frame: CGRect) -> CGPoint {
        let rect = cropRect(in: frame)
        switch corner {
        case .topLeft: return CGPoint(x: rect.minX, y: rect.minY)
        case .topRight: return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft: return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }

    private func unitPoint(_ location: CGPoint, in frame: CGRect) -> CGPoint {
        guard frame.width > 0, frame.height > 0 else { return .zero }
        return CGPoint(
            x: (location.x - frame.minX) / frame.width,
            y: (location.y - frame.minY) / frame.height
        )
    }
}
