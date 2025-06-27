//
//  ImageAnalysisService.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import UIKit

protocol ImageAnalysisService {
    func performOCR(on image: UIImage) async throws -> String
}
