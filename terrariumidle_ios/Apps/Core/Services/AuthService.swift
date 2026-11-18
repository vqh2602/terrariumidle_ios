//
//  AuthService.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 29/1/26.
//
//  Service xử lý authentication với Firebase và Apple Sign-In
//  Hỗ trợ đăng nhập bằng Apple ID, Email/Password và quản lý session

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Foundation

/// Enum định nghĩa các loại lỗi authentication có thể xảy ra
enum AuthError: Error {
  case invalidCredential // Thông tin đăng nhập không hợp lệ
  case appleSignInFailed // Đăng nhập Apple thất bại (user cancel hoặc lỗi)
  case firebaseAuthFailed(String) // Firebase authentication thất bại với message cụ thể
  case missingNonce // Thiếu nonce bảo mật cho Apple Sign-In
  case missingAppleIDToken // Thiếu Apple ID token

  /// Mô tả lỗi dạng human-readable
  var localizedDescription: String {
    switch self {
    case .invalidCredential:
      return "Invalid credentials provided"
    case .appleSignInFailed:
      return "Apple Sign-In failed"
    case let .firebaseAuthFailed(message):
      return "Firebase authentication failed: \(message)"
    case .missingNonce:
      return "Missing nonce for Apple Sign-In"
    case .missingAppleIDToken:
      return "Missing Apple ID token"
    }
  }
}

/// Service chính để quản lý authentication
/// Sử dụng Singleton pattern để đảm bảo chỉ có 1 instance duy nhất
//@MainActor
class AuthService: NSObject {
  // MARK: - Singleton

  /// Instance duy nhất của AuthService
  static let shared = AuthService()

  // MARK: - Private Properties

  /// Nonce chưa hash, dùng để verify Apple Sign-In response
  private var currentNonce: String?

  /// Callback function được gọi khi quá trình đăng nhập hoàn tất (thành công hoặc thất bại)
  private var signInCompletion: ((Result<User, Error>) -> Void)?

  /// Private init để ngăn tạo instance mới từ bên ngoài (enforcing Singleton)
  override private init() {
    super.init()
  }

  // MARK: - Traditional Login (Email/Password)

  /// Đăng nhập bằng email và password
  /// - Parameters:
  ///   - username: Email của user
  ///   - password: Password của user
  /// - Returns: Tuple chứa (Firebase token, Firebase User object)
  /// - Throws: AuthError.firebaseAuthFailed nếu đăng nhập thất bại
  ///
  /// Sử dụng:
  /// ```swift
  /// let (token, user) = try await AuthService.shared.login(
  ///     username: "user@example.com",
  ///     password: "password123"
  /// )
  /// ```
  func login(username: String, password: String) async throws -> (token: String, user: User?) {
    do {
      // Gọi Firebase Auth để đăng nhập
      let authResult = try await Auth.auth().signIn(withEmail: username, password: password)
      // Lấy Firebase ID token để sử dụng với backend
      let token = try await authResult.user.getIDToken()
      return (token: token, user: authResult.user)
    } catch {
      throw AuthError.firebaseAuthFailed(error.localizedDescription)
    }
  }

  /// Đăng ký tài khoản mới bằng email và password
  /// - Parameters:
  ///   - email: Email của user
  ///   - password: Password của user
  /// - Returns: Tuple chứa (Firebase token, Firebase User object)
  func register(email: String, password: String) async throws -> (token: String, user: User?) {
    do {
      let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
      let token = try await authResult.user.getIDToken()
      return (token: token, user: authResult.user)
    } catch {
      throw AuthError.firebaseAuthFailed(error.localizedDescription)
    }
  }

  // MARK: - Google Sign-In

  /// Đăng nhập bằng Google qua Firebase OAuthProvider
  /// Tự động hiển thị web sheet bảo mật ASWebAuthenticationSession của iOS
  @MainActor
  func signInWithGoogle() async throws -> User {
    let provider = OAuthProvider(providerID: "google.com")
    provider.scopes = ["profile", "email"]
    let authResult = try await Auth.auth().signIn(with: provider, uiDelegate: nil)
    return authResult.user
  }

  // MARK: - Logout

  /// Đăng xuất user hiện tại khỏi Firebase
  /// - Throws: AuthError.firebaseAuthFailed nếu logout thất bại
  ///
  /// Sử dụng:
  /// ```swift
  /// try AuthService.shared.logout()
  /// ```
  func logout() throws {
    do {
      try Auth.auth().signOut()
    } catch {
      throw AuthError.firebaseAuthFailed(error.localizedDescription)
    }
  }

  // MARK: - Apple Sign-In

  /// Bắt đầu flow đăng nhập bằng Apple ID
  /// Flow: Generate nonce → Gọi Apple Auth → Nhận credential → Đăng nhập Firebase
  ///
  /// - Parameter completion: Callback được gọi khi hoàn tất với Result<User, Error>
  ///   - Success: Trả về Firebase User object
  ///   - Failure: Trả về AuthError tương ứng
  ///
  /// Sử dụng:
  /// ```swift
  /// AuthService.shared.startSignInWithAppleFlow { result in
  ///     switch result {
  ///     case .success(let user):
  ///         print("Logged in: \(user.uid)")
  ///     case .failure(let error):
  ///         print("Error: \(error)")
  ///     }
  /// }
  /// ```
  ///
  /// ⚠️ Chỉ hoạt động trên thiết bị thật, không hoạt động trên Simulator
  @available(iOS 13, *)
  func startSignInWithAppleFlow(completion: @escaping (Result<User, Error>) -> Void) {
    // 1. Tạo nonce ngẫu nhiên để bảo mật
    let nonce = randomNonceString()
    currentNonce = nonce
    signInCompletion = completion

    // 2. Tạo request đăng nhập Apple
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email] // Yêu cầu quyền truy cập tên và email
    request.nonce = sha256(nonce) // Gửi nonce đã hash để bảo mật

    // 3. Khởi tạo và thực hiện authorization
    let authorizationController = ASAuthorizationController(authorizationRequests: [request])
    // “Khi Apple login xong, hãy gọi callback vào object này, self = instance của AuthService”
    authorizationController.delegate = self
    authorizationController.performRequests()
  }

  // MARK: - Helper Methods

  /// Tạo chuỗi nonce ngẫu nhiên an toàn bằng cryptographic random
  /// - Parameter length: Độ dài nonce (mặc định 32 ký tự)
  /// - Returns: Chuỗi nonce ngẫu nhiên
  ///
  /// Nonce này dùng để:
  /// 1. Ngăn replay attacks
  /// 2. Đảm bảo Apple Sign-In response khớp với request
  private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    // Sử dụng SecRandomCopyBytes để tạo random bytes an toàn
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
      fatalError(
        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
      )
    }

    // Charset cho phép trong nonce
    let charset: [Character] =
      Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

    // Map mỗi random byte thành 1 ký tự từ charset
    let nonce = randomBytes.map { byte in
      charset[Int(byte) % charset.count]
    }

    return String(nonce)
  }

  /// Hash chuỗi input bằng SHA256
  /// - Parameter input: Chuỗi cần hash (nonce)
  /// - Returns: Chuỗi hex của SHA256 hash
  ///
  /// Sử dụng SHA256 để:
  /// - Bảo vệ nonce gốc không bị lộ
  /// - Apple chỉ nhận được hash, không phải nonce thật
  @available(iOS 13, *)
  private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    // Convert hash thành hex string
    let hashString = hashedData.compactMap {
      String(format: "%02x", $0)
    }.joined()

    return hashString
  }

  // MARK: - User Management

  /// Lấy user hiện tại đang đăng nhập (nếu có)
  /// - Returns: Firebase User object hoặc nil nếu chưa đăng nhập
  ///
  /// Sử dụng:
  /// ```swift
  /// if let user = AuthService.shared.currentUser {
  ///     print("UID: \(user.uid)")
  ///     print("Email: \(user.email ?? "N/A")")
  /// }
  /// ```
  var currentUser: User? {
    return Auth.auth().currentUser
  }

  /// Lấy Firebase ID token của user hiện tại
  /// Token này dùng để authenticate với backend API
  ///
  /// - Returns: Firebase ID token string
  /// - Throws: AuthError.invalidCredential nếu chưa đăng nhập
  ///
  /// Sử dụng:
  /// ```swift
  /// let token = try await AuthService.shared.getCurrentUserToken()
  /// // Sử dụng token với backend API
  /// headers["Authorization"] = "Bearer \(token)"
  /// ```
  func getCurrentUserToken() async throws -> String {
    guard let user = Auth.auth().currentUser else {
      throw AuthError.invalidCredential
    }
    return try await user.getIDToken()
  }
}

// MARK: - ASAuthorizationControllerDelegate

/// Extension implement delegate methods của Apple Sign-In
@available(iOS 13.0, *)
extension AuthService: ASAuthorizationControllerDelegate {
  /// Callback khi Apple Sign-In thành công
  /// Flow: Nhận credential từ Apple → Tạo Firebase credential → Đăng nhập Firebase
  func authorizationController(controller _: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    print("🍎 [AuthService] authorizationController called - Apple authorization completed")

    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      print("❌ [AuthService] Invalid credential type")
      signInCompletion?(.failure(AuthError.invalidCredential))
      return
    }

    guard let nonce = currentNonce else {
      print("❌ [AuthService] Missing nonce")
      signInCompletion?(.failure(AuthError.missingNonce))
      return
    }

    guard let appleIDToken = appleIDCredential.identityToken else {
      print("❌ [AuthService] Unable to fetch identity token")
      signInCompletion?(.failure(AuthError.missingAppleIDToken))
      return
    }

    guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
      print("❌ [AuthService] Unable to serialize token string")
      signInCompletion?(.failure(AuthError.invalidCredential))
      return
    }

    print("✅ [AuthService] Creating Firebase credential with Apple token")
    // Initialize a Firebase credential, including the user's full name.
    let credential = OAuthProvider.appleCredential(
      withIDToken: idTokenString,
      rawNonce: nonce,
      fullName: appleIDCredential.fullName
    )

    print("🔥 [AuthService] Signing in with Firebase...")
    // Sign in with Firebase.
    Auth.auth().signIn(with: credential) { [weak self] authResult, error in
      if let error = error {
        // Error. If error.code == .MissingOrInvalidNonce, make sure
        // you're sending the SHA256-hashed nonce as a hex string with
        // your request to Apple.
        print("❌ [AuthService] Firebase sign-in failed: \(error.localizedDescription)")
        self?.signInCompletion?(.failure(AuthError.firebaseAuthFailed(error.localizedDescription)))
        return
      }

      guard let user = authResult?.user else {
        print("❌ [AuthService] Auth result missing user")
        self?.signInCompletion?(.failure(AuthError.invalidCredential))
        return
      }

      // ✅ User is signed in to Firebase with Apple.
      print("✅ [AuthService] Firebase sign-in SUCCESS!")
      print("   UID: \(user.uid)")
      print("   Email: \(user.email ?? "N/A")")
      print("   Display Name: \(user.displayName ?? "N/A")")

      // ✅ QUAN TRỌNG: Gọi callback để thông báo cho caller (LoginViewModel)
      self?.signInCompletion?(.success(user))
    }
  }

  /// Callback khi Apple Sign-In thất bại hoặc user cancel
  ///
  /// - Parameters:
  ///   - controller: Authorization controller
  ///   - error: Error object mô tả lỗi
  func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: Error) {
    // Log lỗi để debug
    print("Apple Sign-In failed: \(error.localizedDescription)")
    // Trả về lỗi cho caller
    signInCompletion?(.failure(AuthError.appleSignInFailed))
  }
}

@available(iOS 13, *)
extension AuthService {
  @MainActor
  func startSignInWithAppleFlowAsync() async throws -> User {
    try await withCheckedThrowingContinuation { continuation in
      self.startSignInWithAppleFlow { result in
        switch result {
        case .success(let user):
          continuation.resume(returning: user)
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
