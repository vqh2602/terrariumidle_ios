# Firebase Authentication với Apple Sign-In

## Tổng quan

AuthService đã được cập nhật để hỗ trợ đăng nhập bằng Firebase Authentication với Apple Sign-In. Service này cung cấp các tính năng:

1. ✅ Đăng nhập bằng Apple ID
2. ✅ Authentication với Firebase
3. ✅ Quản lý session người dùng
4. ✅ Lấy Firebase ID token
5. ✅ Đăng xuất

## Yêu cầu

### 1. Cấu hình Firebase

#### a. Đã hoàn thành:
- ✅ Firebase đã được cài đặt
- ✅ `GoogleService-Info.plist` đã được thêm
- ✅ Firebase được khởi tạo trong `AppDelegate`

#### b. Cần làm thêm:
1. **Bật Apple Sign-In trong Firebase Console:**
   - Truy cập [Firebase Console](https://console.firebase.google.com/)
   - Chọn project của bạn
   - Vào **Authentication** > **Sign-in method**
   - Bật **Apple** provider
   - Không cần Service ID cho iOS app

### 2. Cấu hình Xcode Project

#### a. Thêm Capability:
1. Mở project trong Xcode
2. Chọn target `terrariumidle_ios`
3. Vào tab **Signing & Capabilities**
4. Click **+ Capability**
5. Thêm **Sign in with Apple**

#### b. Kiểm tra Bundle Identifier:
- Đảm bảo Bundle Identifier khớp với Apple Developer Portal
- Ví dụ: `com.yourcompany.terrariumidle`

### 3. Cấu hình Apple Developer Portal

1. Truy cập [Apple Developer Portal](https://developer.apple.com/)
2. Vào **Certificates, Identifiers & Profiles**
3. Chọn App ID của bạn
4. Bật **Sign in with Apple** capability
5. Nếu cần, tạo mới App ID và bật capability này

### 4. Cài đặt Dependencies

#### Firebase Auth đã được thêm, kiểm tra Package Dependencies:
1. Mở Xcode
2. File > Add Package Dependencies (nếu chưa có)
3. Thêm: `https://github.com/firebase/firebase-ios-sdk`
4. Chọn các packages:
   - `FirebaseAuth`
   - `FirebaseCore`

## Cách sử dụng

### 1. Đăng nhập với Apple

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        SignInWithAppleButton()
    }
}
```

Hoặc tùy chỉnh:

```swift
import SwiftUI

struct MyLoginView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            Button("Đăng nhập với Apple") {
                signIn()
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
    }
    
    func signIn() {
        isLoading = true
        AuthService.shared.startSignInWithAppleFlow { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let user):
                    print("Đăng nhập thành công: \(user.uid)")
                    // Xử lý đăng nhập thành công
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
```

### 2. Lấy Firebase Token

```swift
Task {
    do {
        let token = try await AuthService.shared.getCurrentUserToken()
        // Sử dụng token để gọi API backend
        print("Token: \(token)")
    } catch {
        print("Lỗi: \(error)")
    }
}
```

### 3. Kiểm tra trạng thái đăng nhập

```swift
if let user = AuthService.shared.currentUser {
    print("Đã đăng nhập với UID: \(user.uid)")
    print("Email: \(user.email ?? "N/A")")
    print("Display Name: \(user.displayName ?? "N/A")")
} else {
    print("Chưa đăng nhập")
}
```

### 4. Đăng xuất

```swift
do {
    try AuthService.shared.logout()
    print("Đã đăng xuất")
} catch {
    print("Lỗi đăng xuất: \(error)")
}
```

## API Reference

### AuthService

#### Properties:
- `static let shared`: Singleton instance
- `var currentUser: User?`: Người dùng hiện tại

#### Methods:

##### `startSignInWithAppleFlow(completion:)`
Bắt đầu flow đăng nhập với Apple

```swift
func startSignInWithAppleFlow(completion: @escaping (Result<User, Error>) -> Void)
```

**Parameters:**
- `completion`: Callback trả về kết quả đăng nhập

**Example:**
```swift
AuthService.shared.startSignInWithAppleFlow { result in
    switch result {
    case .success(let user):
        print("Success: \(user.uid)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

##### `login(username:password:)`
Đăng nhập bằng email/password (traditional)

```swift
func login(username: String, password: String) async throws -> (token: String, user: User?)
```

**Example:**
```swift
Task {
    do {
        let (token, user) = try await AuthService.shared.login(
            username: "user@example.com",
            password: "password123"
        )
        print("Token: \(token)")
    } catch {
        print("Error: \(error)")
    }
}
```

##### `logout()`
Đăng xuất

```swift
func logout() throws
```

**Example:**
```swift
do {
    try AuthService.shared.logout()
} catch {
    print("Error: \(error)")
}
```

##### `getCurrentUserToken()`
Lấy Firebase ID token của user hiện tại

```swift
func getCurrentUserToken() async throws -> String
```

**Example:**
```swift
Task {
    do {
        let token = try await AuthService.shared.getCurrentUserToken()
        // Sử dụng token
    } catch {
        print("Error: \(error)")
    }
}
```

## Error Handling

### AuthError Types:

- `.invalidCredential`: Thông tin đăng nhập không hợp lệ
- `.appleSignInFailed`: Apple Sign-In thất bại
- `.firebaseAuthFailed(String)`: Firebase authentication thất bại
- `.missingNonce`: Thiếu nonce
- `.missingAppleIDToken`: Thiếu Apple ID token

### Example:

```swift
AuthService.shared.startSignInWithAppleFlow { result in
    switch result {
    case .success(let user):
        print("✅ Success: \(user.uid)")
        
    case .failure(let error):
        if let authError = error as? AuthError {
            switch authError {
            case .appleSignInFailed:
                print("❌ Apple Sign-In cancelled or failed")
            case .firebaseAuthFailed(let message):
                print("❌ Firebase error: \(message)")
            default:
                print("❌ Error: \(authError.localizedDescription)")
            }
        }
    }
}
```

## Testing trong Simulator

⚠️ **Lưu ý quan trọng:** Apple Sign-In **không hoạt động** trên Simulator!

Bạn phải test trên **thiết bị thật** với:
- iOS 13.0 trở lên
- Đã đăng nhập Apple ID trong Settings

## Troubleshooting

### 1. Lỗi "Sign in with Apple capability is not enabled"
**Giải pháp:**
- Kiểm tra Xcode Signing & Capabilities
- Đảm bảo đã thêm "Sign in with Apple" capability
- Sync lại với Apple Developer Portal

### 2. Lỗi "Nonce is missing"
**Giải pháp:**
- Đây là lỗi internal, có thể do timing issue
- Thử lại sign-in

### 3. Lỗi Firebase Authentication
**Giải pháp:**
- Kiểm tra Apple provider đã được bật trong Firebase Console
- Kiểm tra `GoogleService-Info.plist` đã được thêm đúng
- Kiểm tra Firebase.configure() được gọi trong AppDelegate

### 4. Token hết hạn
**Giải pháp:**
```swift
// Firebase tự động refresh token
// Nhưng nếu cần force refresh:
Task {
    do {
        let token = try await AuthService.shared.currentUser?.getIDToken(forcingRefresh: true)
    } catch {
        print("Error refreshing token: \(error)")
    }
}
```

## Best Practices

### 1. Sử dụng Singleton
```swift
// ✅ Đúng
AuthService.shared.startSignInWithAppleFlow { ... }

// ❌ Sai - không tạo instance mới
let authService = AuthService() // Sẽ lỗi vì init() là private
```

### 2. Handle authentication state
```swift
import FirebaseAuth

class AuthStateHandler: ObservableObject {
    @Published var isSignedIn = false
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isSignedIn = (user != nil)
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
```

### 3. Secure token handling
```swift
// Không log token ra production
#if DEBUG
print("Token: \(token)")
#endif

// Sử dụng token với secure backend API
let headers = ["Authorization": "Bearer \(token)"]
```

## Integration với Backend

### 1. Gửi token đến backend

```swift
func callAPI(endpoint: String) async throws {
    let token = try await AuthService.shared.getCurrentUserToken()
    
    var request = URLRequest(url: URL(string: endpoint)!)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    // Process response
}
```

### 2. Verify token trên backend (Node.js example)

```javascript
const admin = require('firebase-admin');

async function verifyToken(req, res, next) {
    const token = req.headers.authorization?.split('Bearer ')[1];
    
    try {
        const decodedToken = await admin.auth().verifyIdToken(token);
        req.user = decodedToken;
        next();
    } catch (error) {
        res.status(401).send('Unauthorized');
    }
}
```

## Tài liệu tham khảo

- [Firebase Auth iOS Documentation](https://firebase.google.com/docs/auth/ios/start)
- [Firebase Apple Sign-In](https://firebase.google.com/docs/auth/ios/apple)
- [Apple Sign In Documentation](https://developer.apple.com/documentation/sign_in_with_apple)
