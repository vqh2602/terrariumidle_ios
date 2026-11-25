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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        AudioSessionController.activate()

        // Kích hoạt nhận sự kiện điều khiển từ xa (Lock Screen, Notification Center, Control Center)
        application.beginReceivingRemoteControlEvents()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return Auth.auth().canHandle(url)
    }
}

@main
struct terrariumidle_iosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .environmentObject(localization)
                .environment(\.locale, localization.currentLanguage.locale)
                .task(id: scenePhase) {
                    if scenePhase == .active {
                        _ = await GardenReminderScheduler.shared.update(.saved())
                        await SleepHealthStore.shared.sync()
                    }
                }
                .onAppear {
                    // Tự động phát BGM thư giãn ngay khi mở app
                    if !BackgroundAudioManager.shared.isPlaying {
                        BackgroundAudioManager.shared.startDefaultBGM()
                    }
                }
                .onOpenURL { url in
                    _ = Auth.auth().canHandle(url)
                }
        }
    }
}
