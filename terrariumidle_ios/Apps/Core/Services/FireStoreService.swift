//
//  FireStoreService.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 6/2/26.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

class FireStoreService: ObservableObject {
    static let shared = FireStoreService()
    /// Thông tin user hiện tại
    private var currentUser: User?
    private var dataGraden: [String: Any]?
    
    @Published var gradenModel: GardenModel?

    // MARK: - Debounce & Background Persistence Properties
    private var debounceTask: Task<Void, Never>?
    private var pendingGardenModel: GardenModel?

    // MARK: - Dependencies

    private let auth: AuthService = AuthService.shared
    private let db = Firestore.firestore()

    // MARK: - Init

    /// Private init để ngăn tạo instance mới từ bên ngoài (enforcing Singleton)
    private init() {
        // Lắng nghe khi app chuẩn bị vào background hoặc ngưng hoạt động để lưu ngay lập tức các thay đổi đang chờ
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.flushPendingUpdates()
        }
        #endif
    }
    
    var currentGradenModel: GardenModel? {
      return gradenModel
    }
    
    func realtimeChangeDataGraden(userId: String?) {
        guard let userId else { return }
        db.collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                // Nếu snapshot này sinh ra do local write của chính thiết bị (hasPendingWrites),
                // hoặc đang có thay đổi local đang chờ debounce, bỏ qua để tránh re-render giật lag
                if document.metadata.hasPendingWrites || self.pendingGardenModel != nil {
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                self.dataGraden = data
                do {
                    let model = try GardenModel(dict: data)
                    let sanitized = self.sanitizeGardenModel(model)
                    DispatchQueue.main.async {
                        self.gradenModel = sanitized
                        print("User realtime:", sanitized.user.userName, "Plants:", sanitized.user.userFloor)
                    }
                } catch {
                    print("Failed to parse GardenModel: \(error)")
                }
            }
    }
    /// lấy dữ liệu khu vườn theo id user
    /// pb03Q3R93naRsjiAuyTGz0BPHI92 -> app flutter
    /// 0pMij25JsAV4lMkshYzAFLisdpz2 -> app ios
    func getDataById(userId: String) async -> GardenModel? {
        let docRef = db.collection("users").document(userId)
        print("userIdLoad: \(userId)")
        do {
            let snapshot = try await docRef.getDocument()
            let dict = snapshot.data() ?? [:]
            dataGraden = dict
            // Parse GardenModel from the dictionary if possible
            let model = try GardenModel(dict: dict)
            let sanitized = sanitizeGardenModel(model)
            await MainActor.run {
                self.gradenModel = sanitized
            }
            print("User:", sanitized.user.userName, "Plants:", sanitized.user.userFloor)
            return sanitized
        } catch {
            print("Error loading garden: \(error)")
            return nil
        }
    }

    // MARK: - Create User Data

    /// Tạo dữ liệu mặc định cho tài khoản mới
    /// - Parameters:
    ///   - email: Email của user
    ///   - name: Tên của user (optional, sẽ tạo random nếu nil)
    ///   - id: User ID từ Firebase Auth
    func createDataUser(email: String?, name: String?, id: String) async throws {
        // Tạo username mặc định nếu không có tên
        let userName = name ?? "user\(Int.random(in: 0 ... 999_999_999))"

        // Tạo dữ liệu user mặc định
        let userData: [String: Any] = [
            "isBan": false,
            "isServerUpdate": false,
            "user": [
                "userAvatar": "https://i.imgur.com/pWzNAg8.jpeg",
                "userName": userName,
                "bag": [],
                "identifier": NSNull(),
                "latestPurchaseDate": NSNull(),
                "userEmail": email ?? "",
                "userID": id,
                "userTotalLike": 0,
                "userFloor": 2,
                "userLevel": 1,
                "userLevelEXP": 0,
                "userImageBackground": NSNull(),
            ],
            "cart": [
                "cartPlants": [],
                "cartPots": [],
                "cartStickers": [],
            ],
            "item": [
                "fertilizer": 40,
                "shovel": 5,
            ],
            "money": [
                "oxygen": 10000,
                "gemstone": 20,
                "ticket": 0,
            ],
            "plants": [],
        ]

        do {
            try await db.collection("users").document(id).setData(userData)
           _ = await getDataById(userId: id)
            print("✅ Tạo tài khoản thành công cho user: \(userName)")
        } catch {
            print("❌ Lỗi tạo tài khoản: \(error.localizedDescription)")
            // Đăng xuất nếu tạo tài khoản thất bại
            try? Auth.auth().signOut()
            throw error
        }
    }

    // MARK: - Garden Model Sanitization

    /// Khử trùng lặp cây cùng vị trí và đảm bảo tính nhất quán của dữ liệu
    public func sanitizeGardenModel(_ model: GardenModel) -> GardenModel {
        var uniquePlants: [String: GardenModel.Plant] = [:]
        for plant in model.plants {
            let key = plant.position
            if let existing = uniquePlants[key] {
                // Ưu tiên bản ghi có ID không rỗng và có plantLevel cao nhất
                if existing.idPlant.isEmpty && !plant.idPlant.isEmpty {
                    uniquePlants[key] = plant
                } else if !plant.idPlant.isEmpty && plant.plantLevel >= existing.plantLevel {
                    uniquePlants[key] = plant
                }
            } else {
                uniquePlants[key] = plant
            }
        }
        var cleaned = model
        cleaned.plants = Array(uniquePlants.values)
        return cleaned
    }

    // MARK: - Update User Data

    /// Cập nhật dữ liệu khu vườn:
    /// - Cập nhật ngay lập tức `gradenModel` trên MainActor để UI hiển thị mượt mà 60/120 FPS không độ trễ.
    /// - `debounce == true`: Dành cho thao tác lặp lại nhiều lần liên tục (như tap nhặt oxy).
    ///   Tự động gom toàn bộ các lần tap trong khoảng 1.2s thành 1 lần ghi Firestore duy nhất chạy ngầm ở background.
    /// - `debounce == false`: Ghi ngay lập tức lên Firestore ở background thread (không block Main UI).
    @MainActor
    func saveGarden(gardenModel: GardenModel, debounce: Bool = false) {
        let sanitized = sanitizeGardenModel(gardenModel)
        // Cập nhật ngay local model để UI phản hồi ngay lập tức
        self.gradenModel = sanitized
        self.pendingGardenModel = sanitized

        if debounce {
            debounceTask?.cancel()
            debounceTask = Task { [weak self] in
                do {
                    try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 giây sau lần tương tác cuối cùng
                    guard !Task.isCancelled else { return }
                    guard let self = self, let latestModel = self.pendingGardenModel else { return }
                    self.pendingGardenModel = nil
                    Task.detached(priority: .background) {
                        await self.performFirestoreUpdate(gardenModel: latestModel)
                    }
                } catch {
                    // Task bị huỷ khi người dùng tiếp tục tap - hoạt động bình thường
                }
            }
        } else {
            debounceTask?.cancel()
            debounceTask = nil
            pendingGardenModel = nil
            let modelToSave = sanitized
            Task.detached(priority: .background) { [weak self] in
                await self?.performFirestoreUpdate(gardenModel: modelToSave)
            }
        }
    }

    /// Event pages wait for persistence before acknowledging the JS callback.
    @MainActor
    func saveEventReward(gardenModel: GardenModel) async -> Bool {
        debounceTask?.cancel()
        debounceTask = nil
        let previousPending = pendingGardenModel
        pendingGardenModel = gardenModel // Ignore realtime snapshots during this write.
        let saved = await performFirestoreUpdate(gardenModel: gardenModel) != nil
        pendingGardenModel = previousPending
        if saved {
            pendingGardenModel = nil
            gradenModel = gardenModel
        } else if previousPending != nil {
            flushPendingUpdates()
        }
        return saved
    }

    /// Lưu ngay lập tức các thay đổi đang chờ debounce (khi app chuẩn bị vào background hoặc thoát)
    func flushPendingUpdates() {
        debounceTask?.cancel()
        debounceTask = nil
        guard let model = pendingGardenModel else { return }
        pendingGardenModel = nil
        Task.detached(priority: .background) { [weak self] in
            await self?.performFirestoreUpdate(gardenModel: model)
        }
    }

    /// Ghi dữ liệu lên Firestore ở background thread hoàn toàn bất đồng bộ, không block UI
    @discardableResult
    func performFirestoreUpdate(gardenModel: GardenModel) async -> GardenModel? {
        let userId = gardenModel.user.userID
        guard !userId.isEmpty else {
            print("❌ Lỗi: UserID rỗng")
            return nil
        }

        // Chuyển đổi model sang Dictionary trên background thread để tránh chiếm dụng Main Thread
        var updateData = await Task.detached(priority: .utility) {
            return gardenModel.toDictionary()
        }.value
        // Likes are changed independently by visitors. An older owner snapshot
        // must never overwrite them while saving plants, inventory or currency.
        if var profile = updateData["user"] as? [String: Any] {
            profile.removeValue(forKey: "userTotalLike")
            updateData["user"] = profile
        }

        do {
            let docRef = db.collection("users").document(userId)
            // Ghi trực tiếp bằng setData merge: true bất đồng bộ, không cần getDocument() trước
            try await docRef.setData(updateData, merge: true)
            print("✅ Update Firestore thành công cho user: \(gardenModel.user.userName)")
            return gardenModel
        } catch {
            print("❌ Lỗi khi update Firestore: \(error.localizedDescription)")
            return nil
        }
    }

    /// Update dữ liệu user lên Firestore (hỗ trợ async gọi từ các ViewModel / caller cũ)
    @discardableResult
    func updateDataUser(gardenModel: GardenModel?) async -> GardenModel? {
        guard let gardenModel = gardenModel else {
            print("❌ Lỗi: Không tìm thấy thông tin tài khoản")
            return nil
        }

        await MainActor.run {
            self.debounceTask?.cancel()
            self.debounceTask = nil
            self.pendingGardenModel = nil
            self.gradenModel = gardenModel
        }

        return await performFirestoreUpdate(gardenModel: gardenModel)
    }
}

