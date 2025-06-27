//
//  DefaultImageAnalysisService.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import Foundation
import UIKit
@preconcurrency import Vision

final class DefaultImageAnalysisService: ImageAnalysisService {
   
   func performOCR(on image: UIImage) async throws -> String {
       guard let cgImage = image.cgImage else {
           throw OCRError.invalidImage
       }
       
       do {
           // Najpierw spróbuj wykryć prostokąty na obrazie
           let rectangles = try await detectRectangles(in: cgImage)
           
           // Znajdź największy biały prostokąt (prawdopodobnie tablica)
           if let whiteboardRegion = findLargestWhiteRectangle(rectangles, in: cgImage),
              let croppedImage = cropImage(cgImage, to: whiteboardRegion) {
               
               print("✅ Detected whiteboard region: \(whiteboardRegion)")
               return try await performStandardOCR(on: UIImage(cgImage: croppedImage))
           } else {
               print("⚠️ No whiteboard detected, processing full image")
               // Fallback - przetwórz cały obraz
               return try await performStandardOCR(on: image)
           }
       } catch {
           print("❌ Rectangle detection failed: \(error), processing full image")
           // Fallback - przetwórz cały obraz
           return try await performStandardOCR(on: image)
       }
   }
}

// MARK: - Private Methods
private extension DefaultImageAnalysisService {
   
   // MARK: - Rectangle Detection
   func detectRectangles(in cgImage: CGImage) async throws -> [VNRectangleObservation] {
       return try await withCheckedThrowingContinuation { continuation in
           let request = VNDetectRectanglesRequest { request, error in
               if let error = error {
                   continuation.resume(throwing: error)
                   return
               }
               
               let rectangles = request.results as? [VNRectangleObservation] ?? []
               continuation.resume(returning: rectangles)
           }
           
           request.minimumSize = 0.1 // Minimum 10% obrazu
           request.maximumObservations = 10
           request.minimumAspectRatio = 0.2 // Nie zbyt wąskie prostokąty
           request.maximumAspectRatio = 5.0 // Nie zbyt szerokie prostokąty
           
           let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
           
           DispatchQueue.global(qos: .userInitiated).async {
               do {
                   try handler.perform([request])
               } catch {
                   continuation.resume(throwing: error)
               }
           }
       }
   }
   
   // MARK: - Find Largest White Rectangle
   func findLargestWhiteRectangle(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> CGRect? {
       guard !rectangles.isEmpty else { return nil }
       
       let candidates = rectangles
           .map { observation in
               let rect = VNImageRectForNormalizedRect(observation.boundingBox, cgImage.width, cgImage.height)
               let whiteness = calculateWhiteness(in: rect, of: cgImage)
               let area = rect.width * rect.height
               return (rect: rect, whiteness: whiteness, area: area)
           }
           .filter { $0.whiteness > 0.6 } // Tylko obszary z >60% białych pikseli
           .sorted { $0.area > $1.area } // Sortuj po wielkości
       
       // Zwróć największy biały prostokąt
       return candidates.first?.rect
   }
   
   // MARK: - Calculate Whiteness
   func calculateWhiteness(in rect: CGRect, of cgImage: CGImage) -> Double {
       // Próbkuj punkty w prostokącie i sprawdź ile jest białych
       let sampleSize = 15
       var whiteCount = 0
       var totalCount = 0
       
       let stepX = rect.width / CGFloat(sampleSize)
       let stepY = rect.height / CGFloat(sampleSize)
       
       for i in 0..<sampleSize {
           for j in 0..<sampleSize {
               let x = rect.minX + CGFloat(i) * stepX + stepX/2
               let y = rect.minY + CGFloat(j) * stepY + stepY/2
               
               if let color = getPixelColor(at: CGPoint(x: x, y: y), in: cgImage) {
                   totalCount += 1
                   if isWhiteColor(color) {
                       whiteCount += 1
                   }
               }
           }
       }
       
       return totalCount > 0 ? Double(whiteCount) / Double(totalCount) : 0
   }
   
   // MARK: - Pixel Color Extraction
   func getPixelColor(at point: CGPoint, in cgImage: CGImage) -> (r: UInt8, g: UInt8, b: UInt8)? {
       let x = Int(point.x)
       let y = Int(point.y)
       
       guard x >= 0, y >= 0, x < cgImage.width, y < cgImage.height else { return nil }
       
       guard let dataProvider = cgImage.dataProvider,
             let data = dataProvider.data,
             let bytes = CFDataGetBytePtr(data) else { return nil }
       
       let bytesPerPixel = cgImage.bitsPerPixel / 8
       let bytesPerRow = cgImage.bytesPerRow
       let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
       
       guard pixelOffset + 2 < CFDataGetLength(data) else { return nil }
       
       let r = bytes[pixelOffset]
       let g = bytes[pixelOffset + 1]
       let b = bytes[pixelOffset + 2]
       
       return (r, g, b)
   }
   
   // MARK: - White Color Detection
   func isWhiteColor(_ color: (r: UInt8, g: UInt8, b: UInt8)) -> Bool {
       // Tolerancja dla białego koloru (może być lekko szary)
       let threshold: UInt8 = 180
       return color.r > threshold && color.g > threshold && color.b > threshold
   }
   
   // MARK: - Image Cropping
   func cropImage(_ cgImage: CGImage, to rect: CGRect) -> CGImage? {
       // Upewnij się, że prostokąt mieści się w obrazie
       let clampedRect = CGRect(
           x: max(0, rect.minX),
           y: max(0, rect.minY),
           width: min(rect.width, CGFloat(cgImage.width) - max(0, rect.minX)),
           height: min(rect.height, CGFloat(cgImage.height) - max(0, rect.minY))
       )
       
       return cgImage.cropping(to: clampedRect)
   }
   
   // MARK: - Simplified OCR for Best Quality
   func performStandardOCR(on image: UIImage) async throws -> String {
       guard let cgImage = image.cgImage else {
           throw OCRError.invalidImage
       }
       
       return try await withCheckedThrowingContinuation { continuation in
           let request = VNRecognizeTextRequest { request, error in
               if let error = error {
                   continuation.resume(throwing: error)
                   return
               }
               
               guard let observations = request.results as? [VNRecognizedTextObservation] else {
                   continuation.resume(returning: "")
                   return
               }
               
               // Proste sortowanie od góry do dołu
               let sortedObservations = observations.sorted { obs1, obs2 in
                   obs1.boundingBox.origin.y > obs2.boundingBox.origin.y
               }
               
               // Pobierz najlepszych kandydatów dla każdego tekstu
               let recognizedStrings = sortedObservations.compactMap { observation in
                   observation.topCandidates(1).first?.string
               }
               
               continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
           }
           
           // Najlepsza konfiguracja dla jakości OCR
           request.recognitionLevel = .accurate
           request.usesLanguageCorrection = true
           request.minimumTextHeight = 0.003 // Jeszcze mniejsze teksty
           request.recognitionLanguages = ["en", "pl"]
           request.automaticallyDetectsLanguage = true
           request.revision = VNRecognizeTextRequestRevision3
           
           let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
           
           DispatchQueue.global(qos: .userInitiated).async {
               do {
                   try handler.perform([request])
               } catch {
                   continuation.resume(throwing: error)
               }
           }
       }
   }
    
}
