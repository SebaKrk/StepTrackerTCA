//
//  ImagePreviewSheet.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 29/06/2025.
//

import SwiftUI
import Vision

struct ImagePreviewSheet: View {
    
    let image: UIImage
    let observations: [RecognizedTextObservation]
    let onDismiss: () -> Void
    
    @State private var selectedIndex: Int? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Duży obraz - zajmuje większość ekranu
                imageView
                
                // Mała lista tekstu na dole
                textListView
            }
            .navigationTitle("Podgląd OCR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zamknij") { onDismiss() }
                }
            }
        }
    }
    
    private var imageView: some View {
        GeometryReader { geometry in
//            ScrollView([.horizontal, .vertical]) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
//                    .frame(
//                        minWidth: geometry.size.width,
//                        minHeight: geometry.size.height * 0.8
//                    )
                    .overlay {
                        boundingBoxesOverlay
                    }
//            }
            .background(Color.black)
            .padding(.horizontal, 4)
        }
    }
    
    private var boundingBoxesOverlay: some View {
        ForEach(Array(observations.enumerated()), id: \.offset) { index, observation in
            let isSelected = selectedIndex == index
            
            Box(observation: observation)
                .stroke(isSelected ? .yellow : .red, lineWidth: isSelected ? 3 : 2)
                .overlay(
                    Text("\(index + 1)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(isSelected ? Color.yellow : Color.red)
                        .clipShape(Circle())
                        .offset(x: -8, y: -8),
                    alignment: .topLeading
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedIndex = selectedIndex == index ? nil : index
                    }
                }
        }
    }
    
    private var textListView: some View {
        VStack {
            headerSection
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(observations.enumerated()), id: \.offset) { index, observation in
                        textRow(index: index, observation: observation)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(maxHeight: 150) // Ograniczona wysokość
        .background(Color(.systemGray6))
    }
    
    private var headerSection: some View {
        HStack {
            Text("Tekst (\(observations.count)):")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if selectedIndex != nil {
                Button("Odznacz") {
                    withAnimation {
                        selectedIndex = nil
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func textRow(index: Int, observation: RecognizedTextObservation) -> some View {
        let isSelected = selectedIndex == index
        let text = observation.topCandidates(1).first?.string ?? ""
        let confidence = observation.topCandidates(1).first?.confidence ?? 0
        
        return HStack(alignment: .center, spacing: 8) {
            // Numerek
            Text("\(index + 1)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(4)
                .background(isSelected ? Color.yellow : Color.red)
                .clipShape(Circle())
                .frame(minWidth: 18)
            
            // Tekst
            Text(text)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            // Confidence
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Color.yellow.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = selectedIndex == index ? nil : index
            }
        }
    }
}
