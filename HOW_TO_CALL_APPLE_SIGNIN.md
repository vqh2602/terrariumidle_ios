# Cách gọi hàm Apple Sign-In trong LoginViewModel

## ❌ CÁCH SAI (Code cũ của bạn)

```swift
func login() async {
    // ❌ SAI: startSignInWithAppleFlow KHÔNG phải là async/await
    // ❌ SAI: Syntax không đúng với completion handler
    try? await auth.startSignInWithAppleFlow(completion: <#T##(Result<User, any Error>) -> Void#>)()
}
```

**Lý do sai:**
1. `startSignInWithAppleFlow` dùng **completion handler**, không phải `async/await`
2. Không cần `await` vì function không trả về ngay
3. Syntax `completion: <#placeholder#>()` là placeholder của Xcode, chưa hoàn chỉnh

---

## ✅ CÁCH ĐÚNG

### Option 1: Trong LoginViewModel (Recommended)

```swift
func loginWithApple() {
    // Reset error state
    hasError = false
    errorMessage = nil
    isLoading = true
    
    // Gọi AuthService với completion handler
    auth.startSignInWithAppleFlow { [weak self] result in
        // Callback được gọi trên background thread
        // Cần chuyển về main thread vì update UI
        Task { @MainActor in
            self?.isLoading = false
            
            switch result {
            case .success(let user):
                // ✅ Đăng nhập thành công
                print("✅ Logged in: \(user.uid)")
                self?.currentUser = user
                self?.isAuthenticated = true
                
            case .failure(let error):
                // ❌ Đăng nhập thất bại
                print("❌ Error: \(error.localizedDescription)")
                self?.hasError = true
                self?.errorMessage = error.localizedDescription
            }
        }
    }
}
```

### Option 2: Gọi trực tiếp trong SwiftUI View

```swift
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        Button("Đăng nhập với Apple") {
            // ✅ Gọi method từ viewModel
            viewModel.loginWithApple()
        }
    }
}
```

---

## 📖 So sánh async/await vs Completion Handler

### Async/Await (như email login)
```swift
// Function definition trong AuthService
func login(username: String, password: String) async throws -> (token: String, user: User?) {
    // ...
}

// Cách gọi
func loginWithEmail(email: String, password: String) async {
    do {
        let (token, user) = try await auth.login(username: email, password: password)
        // Xử lý kết quả
    } catch {
        // Xử lý lỗi
    }
}
```

### Completion Handler (như Apple Sign-In)
```swift
// Function definition trong AuthService
func startSignInWithAppleFlow(completion: @escaping (Result<User, Error>) -> Void) {
    // ...
}

// Cách gọi
func loginWithApple() {
    auth.startSignInWithAppleFlow { result in
        Task { @MainActor in
            switch result {
            case .success(let user):
                // Xử lý thành công
            case .failure(let error):
                // Xử lý lỗi
            }
        }
    }
}
```

---

## 🎯 Tại sao Apple Sign-In dùng Completion Handler?

Apple Sign-In **không thể dùng async/await** vì:

1. **Delegate Pattern:** Apple Authorization sử dụng `ASAuthorizationControllerDelegate`
2. **UI Interaction:** Cần hiển thị Apple Sign-In dialog (modal)
3. **Async Nature:** User có thể cancel bất cứ lúc nào
4. **Callback từ System:** iOS system callback khi user hoàn tất

---

## 📋 Full Example trong LoginViewModel

```swift
import Foundation
import Combine
import FirebaseAuth

@MainActor
final class LoginViewModel: ObservableObject {
    // State
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let auth: AuthService

    init(auth: AuthService = AuthService.shared) {
        self.auth = auth
    }

    // ✅ Apple Sign-In (Completion Handler)
    func loginWithApple() {
        isLoading = true
        
        auth.startSignInWithAppleFlow { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    
                case .failure(let error):
                    self?.hasError = true
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // ✅ Email/Password Login (Async/Await)
    func login(email: String, password: String) async {
        isLoading = true
        
        do {
            let (_, user) = try await auth.login(username: email, password: password)
            currentUser = user
            isAuthenticated = true
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
            isLoading = false
        }
    }
}
```

---

## 🔧 Sử dụng trong SwiftUI View

```swift
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        VStack {
            // Apple Sign-In Button
            Button(action: {
                viewModel.loginWithApple()  // ✅ Đúng
            }) {
                HStack {
                    Image(systemName: "applelogo")
                    Text("Đăng nhập với Apple")
                }
            }
            .disabled(viewModel.isLoading)
            
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Lỗi", isPresented: $viewModel.hasError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}
```

---

## ⚡ Quick Reference

| Action | Code |
|--------|------|
| **Gọi Apple Sign-In** | `viewModel.loginWithApple()` |
| **Gọi Email Login** | `await viewModel.login(email: "...", password: "...")` |
| **Logout** | `viewModel.logout()` |
| **Kiểm tra đăng nhập** | `if viewModel.isAuthenticated { ... }` |
| **Hiển thị loading** | `if viewModel.isLoading { ProgressView() }` |
| **Hiển thị error** | `$viewModel.hasError` trong `.alert()` |

---

## 🆘 Common Mistakes

### ❌ Mistake 1: Dùng await với completion handler
```swift
// ❌ SAI
try? await auth.startSignInWithAppleFlow { ... }
```

### ❌ Mistake 2: Không chuyển về main thread
```swift
// ❌ SAI - Crash vì update UI từ background thread
auth.startSignInWithAppleFlow { [weak self] result in
    self?.isLoading = false  // Crash!
}

// ✅ ĐÚNG
auth.startSignInWithAppleFlow { [weak self] result in
    Task { @MainActor in
        self?.isLoading = false  // Safe
    }
}
```

### ❌ Mistake 3: Quên [weak self]
```swift
// ❌ Có thể gây retain cycle
auth.startSignInWithAppleFlow { result in
    self.isLoading = false
}

// ✅ ĐÚNG
auth.startSignInWithAppleFlow { [weak self] result in
    Task { @MainActor in
        self?.isLoading = false
    }
}
```

---

## ✅ Checklist

Khi implement Apple Sign-In trong ViewModel:

- [ ] Function tên `loginWithApple()` (không cần `async`)
- [ ] Gọi `auth.startSignInWithAppleFlow` với closure `{ result in ... }`
- [ ] Dùng `[weak self]` trong closure
- [ ] Wrap trong `Task { @MainActor in ... }` để update UI
- [ ] Handle cả `.success` và `.failure` cases
- [ ] Update `isLoading`, `isAuthenticated`, và error states

---

## 📞 Need Help?

Xem thêm:
- `AuthService.swift` - Implementation của Apple Sign-In
- `LoginView.swift` - Example view sử dụng LoginViewModel
- `FIREBASE_AUTH_README.md` - Full documentation
