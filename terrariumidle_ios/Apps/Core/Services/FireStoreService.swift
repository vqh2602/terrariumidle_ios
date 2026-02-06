//
//  FireStoreService.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 6/2/26.
//

import FirebaseFirestore
import FirebaseAuth
import Combine
class FireStoreService : ObservableObject{
    /// Thông tin user hiện tại
    @Published var currentUser: User?
    private var dataGraden: [String:Any]?
    @Published var gradenModel: GardenModel?

    // MARK: - Dependencies

    private let auth: AuthService
    private let db = Firestore.firestore()
    
    // MARK: - Init

    init(auth: AuthService) {
        self.auth = auth
        self.currentUser = auth.currentUser
//        super.init()
        print("user hiện tại: \(currentUser?.email ?? "n/a")")
    }
    
    func getDataById(userId: String) async {
        let docRef = db.collection("users").document("pb03Q3R93naRsjiAuyTGz0BPHI92")
        print("userIdLoad: \(userId)")
        do {
            let snapshot = try await docRef.getDocument()
            let dict = snapshot.data() ?? [:]
            self.dataGraden = dict
            // Parse GardenModel from the dictionary if possible
            gradenModel = try GardenModel(dict: dict)
            print("User:", gradenModel?.user.userName, "Plants:", gradenModel?.user.userFloor)
        } catch {
            print("Error loading garden: \(error)")
        }

    }
}

