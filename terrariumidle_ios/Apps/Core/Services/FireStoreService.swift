//
//  FireStoreService.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 6/2/26.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

class FireStoreService: ObservableObject {
    /// Thông tin user hiện tại
    @Published var currentUser: User?
    private var dataGraden: [String: Any]?
    @Published var gradenModel: GardenModel?

    // MARK: - Dependencies

    private let auth: AuthService
    private let db = Firestore.firestore()

    // MARK: - Init

    init(auth: AuthService) {
        self.auth = auth
        currentUser = auth.currentUser
//        super.init()
        print("user hiện tại: \(currentUser?.email ?? "n/a")")
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
            gradenModel = try GardenModel(dict: dict)
            print("User:", gradenModel?.user.userName as Any, "Plants:", gradenModel?.user.userFloor as Any)
            return gradenModel
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
            print("✅ Tạo tài khoản thành công cho user: \(userName)")
        } catch {
            print("❌ Lỗi tạo tài khoản: \(error.localizedDescription)")
            // Đăng xuất nếu tạo tài khoản thất bại
            try? Auth.auth().signOut()
            throw error
        }
    }

    // MARK: - Update User Data

    /// Update dữ liệu user lên Firestore
    /// - Parameters:
    ///   - gardenModel: GardenModel cần update
    /// - Returns: GardenModel đã update hoặc nil nếu lỗi
    func updateDataUser(gardenModel: GardenModel?) async -> GardenModel? {
        guard let gardenModel = gardenModel else {
            print("❌ Lỗi: Không tìm thấy thông tin tài khoản")
            return nil
        }

        let userId = gardenModel.user.userID

        do {
            // Check xem document có tồn tại không
            let docRef = db.collection("users").document(userId)
            let snapshot = try await docRef.getDocument()

            guard snapshot.exists else {
                print("❌ Lỗi: Document không tồn tại cho userID: \(userId)")
                return nil
            }

            // Convert GardenModel sang Dictionary để update
            let updateData = gardenModel.toDictionary()

            // Update document
            try await docRef.updateData(updateData)
            print("✅ Update thành công cho user: \(gardenModel.user.userName)")

            // Update published property
            gradenModel = gardenModel

            return gardenModel
        } catch {
            print("❌ Lỗi khi update user: \(error.localizedDescription)")
            return nil
        }
    }
}
