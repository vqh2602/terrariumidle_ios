//
//  terrariumidle_iosApp.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 29/1/26.
//

import AVFoundation
import FirebaseAuth
import FirebaseCore
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        EncryptedResourceLoader.installImageHooksIfNeeded()
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self

        AudioSessionController.activate()

        // Kích hoạt nhận sự kiện điều khiển từ xa (Lock Screen, Notification Center, Control Center)
        application.beginReceivingRemoteControlEvents()

        Task { @MainActor in
            SubscriptionManager.shared.start()
            GemStoreManager.shared.start()
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return Auth.auth().canHandle(url)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        if response.notification.request.content.userInfo["destination"] as? String == "healthHub" {
            await MainActor.run {
                HealthRewardStatusStore.shared.shouldOpenHealthHub = true
            }
        }
    }
}

@main
struct terrariumidle_iosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var atmosphere = GardenAtmosphereManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modifier(WatchCompanionLifecycle())
                .modifier(AchievementLifecycle())
                .preferredColorScheme(.light)
                .environmentObject(localization)
                .environment(\.locale, localization.currentLanguage.locale)
                .appUpdateAlert()
                .task(id: scenePhase) {
                    if scenePhase == .active {
                        _ = await GardenReminderScheduler.shared.update(.saved())
                        await HealthRewardStatusStore.shared.syncAndRefresh()
                        await SubscriptionManager.shared.refreshEntitlements()
                        await AppUpdateChecker.shared.checkForUpdateIfNeeded()
                    }
                }
                .task(id: "\(scenePhase == .active)-\(atmosphere.hasInitialized)-\(atmosphere.timerGeneration)") {
                    guard scenePhase == .active, atmosphere.hasInitialized else { return }
                    do {
                        try await Task.sleep(for: .seconds(GardenAtmosphereManager.landscapeRotationInterval))
                        try Task.checkCancellation()
                        atmosphere.randomizeLandscape(gardenModel: FireStoreService.shared.gradenModel)
                    } catch {
                        // Cancelled when leaving active phase or reset when landscape changes.
                    }
                }
                .onOpenURL { url in
                    _ = Auth.auth().canHandle(url)
                }
        }
    }
}
