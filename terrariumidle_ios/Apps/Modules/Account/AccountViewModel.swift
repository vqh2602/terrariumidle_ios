//
//  AccountViewModel.swift
//  terrariumidle_ios
//
//  Created by AI on 11/2/26.
//

import Combine
import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
final class AccountViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var highPerformanceMode: Bool = false
    @Published var roomSceneMode: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var showSignOutConfirmation: Bool = false
    @Published var isUploadingAvatar: Bool = false
    @Published var avatarErrorMessage: String?
    @Published var showAvatarError: Bool = false
    @Published var activeHTMLDocument: AccountHTMLDocument?
    @Published var showSupportSheet: Bool = false

    // MARK: - Dependencies

    private let fireStore: FireStoreService = FireStoreService.shared
    private let auth: AuthService = AuthService.shared

    // MARK: - Init

    init() {
        // Load saved preferences
        loadPreferences()
    }

    // MARK: - Settings Actions

    func toggleHighPerformance() {
        highPerformanceMode.toggle()
        UserDefaults.standard.set(highPerformanceMode, forKey: "highPerformanceMode")
        print("High Performance Mode: \(highPerformanceMode ? "Enabled" : "Disabled")")
    }

    func toggleRoomScene() {
        roomSceneMode.toggle()
        UserDefaults.standard.set(roomSceneMode, forKey: "roomSceneMode")
        print("Room Scene Mode: \(roomSceneMode ? "Enabled" : "Disabled")")
    }

    // MARK: - Service Actions

    func syncData() {
        print("Syncing data...")
        Task {
            guard let userId = auth.currentUser?.uid else { return }
            _ = await fireStore.getDataById(userId: userId)
            print("Data synced successfully")
        }
    }

    func uploadAvatar(imageData: Data) {
        guard !isUploadingAvatar else { return }
        guard let rawImage = UIImage(data: imageData) else {
            avatarErrorMessage = SensitiveImageError.invalidImage.localizedDescription
            showAvatarError = true
            return
        }

        isUploadingAvatar = true
        avatarErrorMessage = nil

        Task {
            defer { isUploadingAvatar = false }
            do {
                let preparedImage = ImageUploadService.shared.prepareAvatarImage(rawImage) ?? rawImage
                try await SensitiveImageFilter.shared.validate(preparedImage)
                let uploadedURL = try await ImageUploadService.shared.uploadAvatar(preparedImage)
                try await fireStore.updateUserAvatar(uploadedURL)
            } catch {
                avatarErrorMessage = error.localizedDescription
                showAvatarError = true
            }
        }
    }

    func openRateApp() {
        guard let url = URL(string: "https://apps.apple.com/app/id1234567890") else { return }
        UIApplication.shared.open(url)
    }

    func openWiki() {
        activeHTMLDocument = .wiki
    }

    func contactSupport() {
        showSupportSheet = true
    }

    func openPrivacyPolicy() {
        activeHTMLDocument = .privacy
    }

    func openTermsOfUse() {
        activeHTMLDocument = .terms
    }

    func sendSupportRequest(email: String, message: String) async throws {
        guard let webhookURL = URL(string: "https://discord.com/api/webhooks/1574253065899614420/cBYFx-8ZrbnVuJBkkv_IXPB6vUggzWSuYAT0Mp_IwF1VqO2E9rLZHM3cxKjVeIlP_Ha3?wait=true") else {
            throw URLError(.badURL)
        }

        let user = fireStore.gradenModel?.user
        let userID = user?.userID ?? auth.currentUser?.uid ?? "guest"
        let userName = user?.userName ?? "Unknown"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"

        let payload: [String: Any] = [
            "allowed_mentions": ["parse": [String]()],
            "embeds": [
                [
                    "title": "📩 Yêu cầu hỗ trợ · Terrarium Idle",
                    "color": 5_205_826,
                    "fields": [
                        ["name": "Email", "value": email, "inline": true],
                        ["name": "Người dùng", "value": "\(userName) (`\(userID)`)", "inline": true],
                        ["name": "Phiên bản", "value": "v\(appVersion) (\(buildNumber))", "inline": true],
                        ["name": "Nội dung hỗ trợ", "value": message, "inline": false]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: webhookURL, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func requestDeleteAccount() {
        showDeleteConfirmation = true
    }

    func deleteAccount() {
        print("Deleting account...")
        // TODO: Implement actual account deletion
        Task {
            // Delete user data from Firestore
            // Delete Firebase Auth account
            // Navigate to login screen
        }
    }

    func requestSignOut() {
        showSignOutConfirmation = true
    }

    func signOut() {
        print("Signing out...")
        do {
            try auth.logout()
            SubscriptionManager.shared.clearVIPCache()
            FireStoreService.shared.resetSession()
            GardenAtmosphereManager.shared.reset()
        } catch {
         
        }
      
        // Navigation will be handled by the view
    }

    // MARK: - Private Methods

    private func loadPreferences() {
        highPerformanceMode = UserDefaults.standard.bool(forKey: "highPerformanceMode")
        roomSceneMode = UserDefaults.standard.bool(forKey: "roomSceneMode")
    }
}
