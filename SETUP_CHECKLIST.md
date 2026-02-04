# Firebase Authentication với Apple Sign-In - Checklist Setup

## ✅ Đã hoàn thành

- [x] AuthService đã được implement với Firebase Auth
- [x] Firebase đã được cài đặt và cấu hình
- [x] GoogleService-Info.plist đã có
- [x] Sample UI (SignInWithAppleButton.swift) đã được tạo

## 📋 Cần làm để hoàn thiện

### 1. Firebase Console Setup (5 phút)
- [ ] Truy cập https://console.firebase.google.com/
- [ ] Chọn project của bạn
- [ ] Vào **Authentication** > **Sign-in method**
- [ ] Click **Apple** và bật nó lên
- [ ] Lưu lại

### 2. Xcode Project Setup (5 phút)
- [ ] Mở project trong Xcode
- [ ] Chọn target `terrariumidle_ios`
- [ ] Vào tab **Signing & Capabilities**
- [ ] Click **+ Capability**
- [ ] Tìm và thêm **Sign in with Apple**
- [ ] Save project

### 3. Apple Developer Portal (10 phút)
- [ ] Truy cập https://developer.apple.com/
- [ ] Vào **Certificates, Identifiers & Profiles**
- [ ] Chọn **Identifiers** > chọn App ID của bạn
- [ ] Tìm **Sign in with Apple** trong danh sách capabilities
- [ ] Bật nó lên và Save
- [ ] Nếu chưa có App ID, tạo mới và bật capability này

### 4. Kiểm tra Dependencies
- [ ] Mở Xcode
- [ ] Vào **File** > **Add Package Dependencies**
- [ ] Kiểm tra đã có Firebase iOS SDK (https://github.com/firebase/firebase-ios-sdk)
- [ ] Đảm bảo đã add: `FirebaseAuth` và `FirebaseCore`

### 5. Test (chỉ trên thiết bị thật)
- [ ] Kết nối iPhone/iPad (iOS 13+)
- [ ] Đảm bảo đã đăng nhập Apple ID trong Settings
- [ ] Build và run app trên thiết bị
- [ ] Test đăng nhập với Apple
- [ ] Kiểm tra console log để xem user info

## 🔧 Cách sử dụng cơ bản

### Thêm vào ContentView.swift:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        SignInWithAppleButton()
    }
}
```

Hoặc tự làm UI riêng:

```swift
Button("Đăng nhập với Apple") {
    AuthService.shared.startSignInWithAppleFlow { result in
        switch result {
        case .success(let user):
            print("✅ Logged in: \(user.uid)")
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
}
```

## ⚠️ Lưu ý quan trọng

1. **Không test trên Simulator** - Apple Sign-In chỉ hoạt động trên thiết bị thật
2. **Cần Apple ID** - Thiết bị test phải đăng nhập Apple ID
3. **iOS 13+** - Minimum deployment target phải là iOS 13.0+
4. **Bundle ID** - Phải khớp với Apple Developer Portal

## 🆘 Gặp vấn đề?

Kiểm tra file `FIREBASE_AUTH_README.md` để xem:
- API Reference chi tiết
- Error handling
- Troubleshooting guide
- Best practices
- Backend integration examples

## 📞 Quick Reference

### Đăng nhập:
```swift
AuthService.shared.startSignInWithAppleFlow { result in ... }
```

### Đăng xuất:
```swift
try AuthService.shared.logout()
```

### Lấy token:
```swift
let token = try await AuthService.shared.getCurrentUserToken()
```

### Kiểm tra user:
```swift
if let user = AuthService.shared.currentUser {
    print(user.uid)
}
```

## 🎯 Next Steps

Sau khi setup xong, bạn có thể:
1. Tùy chỉnh UI đăng nhập
2. Thêm observer cho auth state changes
3. Integrate với backend API của bạn
4. Thêm các auth providers khác (Google, Facebook, etc.)

Xem chi tiết trong `FIREBASE_AUTH_README.md`!
