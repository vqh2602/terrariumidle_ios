import Combine
import CoreLocation
import Foundation
import FirebaseAuth
import UIKit
import WeatherKit

/// One-shot, opt-in phone weather adapter. No continuous/background location tracking.
@MainActor
final class WatchWeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WatchWeatherService()
    @Published private(set) var weather: WatchWeatherSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var message = "Bật thời tiết để sử dụng widget ngoài trời."
    private let locationManager = CLLocationManager()
    private var generation = 0
    private var lastAttempt: Date?
    private var timeout: Task<Void, Never>?
    private var waitingForLocation = false
    private var enabled: Bool {
        UserDefaults.standard.bool(forKey: "watch.weatherEnabled")
            && UserDefaults.standard.bool(forKey: "watch.enabled")
            && Auth.auth().currentUser != nil
    }

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func reset() {
        generation += 1
        timeout?.cancel()
        locationManager.stopUpdatingLocation()
        weather = nil
        isLoading = false
        waitingForLocation = false
        lastAttempt = nil
        message = "Bật thời tiết để sử dụng widget ngoài trời."
    }

    func setEnabled(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "watch.weatherEnabled")
        if value { refresh(force: true, promptForLocation: true) }
        else { reset() }
    }

    func refresh(force: Bool = false, promptForLocation: Bool = false) {
        guard enabled else { reset(); return }
        guard CLLocationManager.locationServicesEnabled() else {
            reset()
            message = "Bật quyền vị trí trong Cài đặt để xem thời tiết."
            return
        }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            if promptForLocation { locationManager.requestWhenInUseAuthorization() }
            message = "Cho phép vị trí khi dùng app để lấy thời tiết."
        case .authorizedAlways, .authorizedWhenInUse:
            guard !isLoading else { return }
            if !force, let lastAttempt {
                let elapsed = Date().timeIntervalSince(lastAttempt)
                if elapsed < 120 || (weather?.isFresh(at: .now) == true && elapsed < 20 * 60) { return }
            }
            generation += 1
            let token = generation
            isLoading = true
            waitingForLocation = true
            lastAttempt = .now
            message = "Đang cập nhật thời tiết…"
            locationManager.requestLocation()
            timeout?.cancel()
            timeout = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(20)) } catch { return }
                guard let self, self.generation == token, self.isLoading else { return }
                self.generation += 1
                self.isLoading = false
                self.waitingForLocation = false
                self.message = "Chưa lấy được thời tiết. Hãy kiểm tra mạng, quyền vị trí và cấu hình WeatherKit."
            }
        default:
            reset()
            message = "Bật quyền vị trí trong Cài đặt để xem thời tiết."
        }
    }

    private func load(for location: CLLocation, token: Int) async {
        do {
            async let attributionRequest = WeatherService.shared.attribution
            let (current, hourly) = try await WeatherService.shared.weather(for: location, including: .current, .hourly)
            let attribution = try await attributionRequest
            let now = Date()
            let hour = hourly.forecast.first {
                Calendar.current.isDate($0.date, equalTo: now, toGranularity: .hour)
            }
            // Cache the official Apple Weather mark in the small display snapshot.
            // WidgetKit cannot load an AsyncImage during a timeline render.
            var mark: Data?
            if let (data, response) = try? await URLSession.shared.data(from: attribution.combinedMarkLightURL),
               (response as? HTTPURLResponse)?.statusCode == 200,
               let image = UIImage(data: data), image.size.width > 0 {
                let width: CGFloat = 120
                let height = width * image.size.height / image.size.width
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                let thumbnail = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { _ in
                    image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
                }
                if let data = thumbnail.pngData(), data.count <= 5_000 { mark = data }
            }
            guard token == generation, enabled else { return }
            let next = WatchWeatherSnapshot(
                measuredAt: current.date, expiresAt: min(current.metadata.expirationDate, now.addingTimeInterval(3600)),
                temperatureCelsius: current.temperature.converted(to: .celsius).value,
                feelsLikeCelsius: current.apparentTemperature.converted(to: .celsius).value,
                uvIndex: current.uvIndex.value, humidity: current.humidity,
                windKilometersPerHour: current.wind.speed.converted(to: .kilometersPerHour).value,
                rainChance: hour?.precipitationChance, symbolName: current.symbolName,
                legalURL: attribution.legalPageURL, attributionMark: mark)
            guard next.isFresh(at: now) else { throw CocoaError(.coderInvalidValue) }
            weather = next
            message = "Thời tiết được cập nhật khi mở app iPhone; widget không cập nhật liên tục."
        } catch {
            guard token == generation else { return }
            // Keep a recent reading with its original expiry. Never extend stale data.
            if weather?.isFresh(at: .now) != true { weather = nil }
            message = "Chưa lấy được thời tiết. Hãy kiểm tra mạng, quyền vị trí và cấu hình WeatherKit."
        }
        guard token == generation else { return }
        timeout?.cancel()
        isLoading = false
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if self.enabled { self.refresh() }
        }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard self.enabled, self.isLoading, self.waitingForLocation, let location = locations.last,
                  location.horizontalAccuracy >= 0,
                  abs(location.timestamp.timeIntervalSinceNow) < 300 else { return }
            self.waitingForLocation = false
            await self.load(for: location, token: self.generation)
        }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            guard self.waitingForLocation else { return }
            self.waitingForLocation = false
            self.timeout?.cancel()
            self.isLoading = false
            self.message = "Bật quyền vị trí trong Cài đặt để xem thời tiết."
        }
    }
}
