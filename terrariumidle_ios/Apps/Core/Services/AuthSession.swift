////
////  AuthSession.swift
////  terrariumidle_ios
////
////  Created by vương quang huy on 29/1/26.
////
//
//import Foundation
//import CryptoKit
//import FirebaseAuth
//import Foundation
//import Combine
//
//@MainActor
//final class AuthSession: ObservableObject {
// 
//    
//    @Published private(set) var user: User? = nil
//    @Published private(set) var token: String? = nil
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String?
//
//    private let service: AuthService
//
//    init(service: AuthService? = nil) {
//        self.service = service ?? AuthService.shared
//    }
//
//    var isLoggedIn: Bool { user != nil && token != nil }
//
//    func login(username: String, password: String) async {
//        errorMessage = nil
//        isLoading = true
//        defer { isLoading = false }
//
//        do {
//            let result = try await service.login(username: username, password: password)
//            token = result.token
//            user = result.user
//            // TODO: lưu token xuống Keychain/UserDefaults nếu muốn persistent
//        } catch {
//            errorMessage = "Đăng nhập thất bại"
//        }
//    }
//
//    func logout() async {
//        await service.logout(token: token)
//        token = nil
//        user = nil
//    }
//}
//
