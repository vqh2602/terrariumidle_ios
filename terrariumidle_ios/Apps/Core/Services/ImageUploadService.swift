//
//  ImageUploadService.swift
//  terrariumidle_ios
//
//  Uploads avatar images to freeimage.host after normalizing and compressing.
//

import Foundation
import UIKit

enum ImageUploadError: LocalizedError {
    case encodingFailed
    case invalidResponse
    case serverError(String)
    case missingImageURL

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Không thể xử lý ảnh để tải lên.".tr
        case .invalidResponse:
            return "Phản hồi từ máy chủ ảnh không hợp lệ.".tr
        case .serverError(let message):
            return message
        case .missingImageURL:
            return "Không nhận được đường dẫn ảnh sau khi tải lên.".tr
        }
    }
}

final class ImageUploadService {
    static let shared = ImageUploadService()

    private let endpoint = URL(string: "https://freeimage.host/api/1/upload")!
    private let apiKey = "6d207e02198a847aa98d0a2a901485a5"
    private let maxAvatarDimension: CGFloat = 512

    private init() {}

    /// Normalizes orientation and resizes the image to fit within `maxAvatarDimension`.
    func prepareAvatarImage(_ image: UIImage) -> UIImage? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }

        let scale = min(1.0, maxAvatarDimension / max(size.width, size.height))
        let targetSize = CGSize(
            width: (size.width * scale).rounded(),
            height: (size.height * scale).rounded()
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Uploads a `UIImage` as JPEG to `freeimage.host` and returns the hosted image URL string.
    func uploadAvatar(_ image: UIImage) async throws -> String {
        let normalized = prepareAvatarImage(image) ?? image
        guard let imageData = normalized.jpegData(compressionQuality: 0.85) else {
            throw ImageUploadError.encodingFailed
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipartBody(imageData: imageData, boundary: boundary)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploadError.invalidResponse
        }

        let decoded = try? JSONDecoder().decode(FreeImageResponse.self, from: data)

        guard (200 ..< 300).contains(httpResponse.statusCode),
              decoded?.statusCode == 200
        else {
            let message = decoded?.error?.message ?? "Tải ảnh lên thất bại (mã %d).".tr(httpResponse.statusCode)
            throw ImageUploadError.serverError(message)
        }

        guard let urlString = decoded?.image?.displayUrl ?? decoded?.image?.url,
              !urlString.isEmpty
        else {
            throw ImageUploadError.missingImageURL
        }

        if let url = URL(string: urlString) {
            ImageCache.shared.set(normalized, for: url as NSURL)
        }

        return urlString
    }

    private func buildMultipartBody(imageData: Data, boundary: String) -> Data {
        var body = Data()

        let fields: [(String, String)] = [
            ("key", apiKey),
            ("action", "upload"),
            ("format", "json")
        ]

        for (name, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"source\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        return body
    }
}

private struct FreeImageResponse: Decodable {
    struct ImagePayload: Decodable {
        let url: String?
        let displayUrl: String?

        enum CodingKeys: String, CodingKey {
            case url
            case displayUrl = "display_url"
        }
    }

    struct ErrorPayload: Decodable {
        let message: String?
    }

    let statusCode: Int?
    let image: ImagePayload?
    let error: ErrorPayload?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case image
        case error
    }
}
