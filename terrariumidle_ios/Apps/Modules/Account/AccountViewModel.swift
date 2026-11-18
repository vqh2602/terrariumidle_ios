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

    func openRateApp() {
        guard let url = URL(string: "https://apps.apple.com/app/id1234567890") else { return }
        UIApplication.shared.open(url)
    }

    func openWiki() {
        // TODO: Replace with actual wiki URL
        guard let url = URL(string: "https://wiki.terrarium.com") else { return }
        UIApplication.shared.open(url)
    }

    func contactSupport() {
        // TODO: Replace with actual support email
        let email = "support@terrarium.com"
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }

    func openPrivacyPolicy() {
        // TODO: Replace with actual privacy policy URL
        guard let url = URL(string: "https://terrarium.com/privacy") else { return }
        UIApplication.shared.open(url)
    }

    func openTermsOfUse() {
        // TODO: Replace with actual terms URL
        guard let url = URL(string: "https://terrarium.com/terms") else { return }
        UIApplication.shared.open(url)
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
