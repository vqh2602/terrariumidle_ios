//
//  SensitiveImageFilter.swift
//  terrariumidle_ios
//
//  On-device sensitive/NSFW image moderation using Apple's
//  SensitiveContentAnalysis framework with a Vision classification fallback.
//

import Foundation
import SensitiveContentAnalysis
import UIKit
import Vision

enum SensitiveImageError: LocalizedError {
    case invalidImage
    case sensitiveContentDetected

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Không thể đọc ảnh đã chọn. Vui lòng thử ảnh khác.".tr
        case .sensitiveContentDetected:
            return "Ảnh chứa nội dung nhạy cảm và không thể sử dụng làm ảnh đại diện.".tr
        }
    }
}

final class SensitiveImageFilter {
    static let shared = SensitiveImageFilter()

    private init() {}

    /// High-confidence Vision classification labels used as a supplementary check
    /// when the system-wide SensitiveContentAnalysis policy is disabled.
    private static let blockedVisionIdentifiers: Set<String> = [
        "bikini",
        "brassiere",
        "lingerie",
        "maillot",
        "swimsuit"
    ]

    private static let visionConfidenceThreshold: VNConfidence = 0.55

    /// Validates that an image does not contain sensitive content before upload.
    /// Throws `SensitiveImageError` if the image is invalid or flagged as sensitive.
    func validate(_ image: UIImage) async throws {
        guard let cgImage = image.cgImage else {
            throw SensitiveImageError.invalidImage
        }

        // 1. Primary check: Apple's SensitiveContentAnalysis (iOS 17+)
        if #available(iOS 17.0, *) {
            let analyzer = SCSensitivityAnalyzer()
            if analyzer.analysisPolicy != .disabled {
                do {
                    let result = try await analyzer.analyzeImage(cgImage)
                    if result.isSensitive {
                        throw SensitiveImageError.sensitiveContentDetected
                    }
                } catch let error as SensitiveImageError {
                    throw error
                } catch {
                    // If the system analyzer fails (e.g. missing entitlement in simulator),
                    // continue to the Vision heuristic fallback below.
                    print("⚠️ SensitiveContentAnalysis unavailable: \(error.localizedDescription)")
                }
            }
        }

        // 2. Supplementary on-device Vision classification check
        try await runVisionClassificationCheck(on: cgImage)
    }

    private func runVisionClassificationCheck(on cgImage: CGImage) async throws {
        try await Task.detached(priority: .userInitiated) {
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            guard let observations = request.results else { return }
            let isFlagged = observations.contains { observation in
                observation.confidence >= Self.visionConfidenceThreshold &&
                Self.blockedVisionIdentifiers.contains(observation.identifier.lowercased())
            }

            if isFlagged {
                throw SensitiveImageError.sensitiveContentDetected
            }
        }.value
    }
}
