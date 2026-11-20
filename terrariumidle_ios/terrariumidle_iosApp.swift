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

        // Cấu hình AudioSession với category .playback ngay khi app khởi động
        // để kích hoạt bảng điều khiển nhạc Now Playing trên thanh thông báo / màn hình khóa iOS
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            // Đánh dấu để BackgroundAudioManager không gọi lại setActive
            BackgroundAudioManager.markSessionConfigured()
            print("✅ AppDelegate: Đã kích hoạt AVAudioSession .playback thành công")
        } catch {
            print("⚠️ AppDelegate: Lỗi thiết lập AVAudioSession:", error)
        }

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

    var body: some Scene {
        WindowGroup {
            ContentView()
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
