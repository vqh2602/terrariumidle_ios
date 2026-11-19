# Workspace Guidelines

## Mô hình Kiến trúc Lai SpriteKit (Visual `.sks` + Swift Code) - LẤY PLANT1 LÀM CHUẨN

Mọi loài cây mới (`Plant2`, `Plant3`, `Plant4`, ...) **BẮT BUỘC** phải có đầy đủ bộ 3 file cấu trúc tương tự `Plant1`:
1. **`PlantXScene.sks` (Thiết kế trực quan trong Xcode Scene Editor)**:
   - Bắt buộc phải có file `.sks` cho mỗi loài cây!
   - Kích thước canvas bằng đúng kích thước ảnh đại diện tham chiếu (ví dụ: Plant1: 428x862, Plant2: 484x641, Plant3: 796x538), `anchorPoint = (0.5, 0.0)`.
   - **TỰ FILL ASSET VÀO MỌI SPRITE**: Mọi `SKSpriteNode` (`seedSprite`, `sproutSprite`, `leaf_X`) trong `.sks` **BẮT BUỘC PHẢI CÓ TEXTURE THẬT** (`imageNamed: ...`) tương ứng trong `Assets.xcassets`. Tuyệt đối không để `_texture = nil / $null` hoặc `color: .clear` khiến Xcode Scene Editor hiển thị khung chữ nhật rỗng.
   - Cấu trúc cây phân cấp bắt buộc:
     - `seedNode` (SKNode, pos: (0, 0)) -> child `seedSprite` (SKSpriteNode, pos: (0, -18.5), anchor: (0.5, 0.05), zPos: 10, texture: `plant1_Asset-100@4.167x`).
     - `sproutNode` (SKNode, pos: (0, 0)) -> child `sproutSprite` (SKSpriteNode, pos: (0, -18.5), anchor: (0.5, 0.05), zPos: 10, texture: `plant1_Asset-200@4.167x`).
     - `matureNode` (SKNode, pos: (0, -10)) -> chứa đầy đủ các phiến lá `leaf_X` (SKSpriteNode), mỗi lá có toạ độ `position`, `anchorPoint` tại cuống, `size`, `zPosition` (lớp sau ra trước), và `texture`.
   - Dùng kéo thả bằng chuột trong Xcode Scene Editor để tinh chỉnh vị trí, góc xoay.

2. **`PlantXNode.swift` (Lập trình Logic & Animation)**:
   - Phải có hàm `loadSceneTemplate() -> SKScene?` nạp từ `PlantXScene.sks`:
     ```swift
     private func loadSceneTemplate() -> SKScene? {
         return SKScene(fileNamed: "PlantXScene")
     }
     ```
   - **ĂN THEO VỊ TRÍ SCENE Ở CẢ 3 TRẠNG THÁI**:
     - Cả `buildSeedState` (Level 1), `buildSproutState` (Level 2) và `buildMatureState` (Level 3+) **BẮT BUỘC** phải ưu tiên nạp trực tiếp node tương ứng (`seedNode`, `sproutNode`, `matureNode`) từ `PlantXScene.sks`.
     - Tuyệt đối **KHÔNG ĐƯỢC** hardcode toạ độ Y của hạt giống/cây con bằng công thức như `containerSize.height * 0.08` làm trôi lệch vị trí và khiến cây con bay lơ lửng trên không trung.
     - Luôn có kiểm tra fallback tự fill texture: `if sprite.texture == nil { sprite.texture = loadTexture(...) }`.
     - Khi chỉnh vị trí trong Xcode `.sks`, code Swift phải tự động sử dụng vị trí mới đó mà không cần sửa code.
   - Luôn có cơ chế Fallback Procedural chứa toạ độ chuẩn phòng trường hợp scene chưa tải được.

3. **`PlantXView.swift` (Xem trước độc lập)**:
   - Bọc `PlantView(plantId: "plantX", ...)` kèm SwiftUI `#Preview` với các nút chuyển trạng thái (Lv.1 Hạt giống, Lv.2 Cây con, Lv.3 Trưởng thành, Lv.10 Cực đại).

4. **Đăng ký vào hệ thống Scene chung**:
   - Thêm ID vào `PlantAvailability.supportedPlantIds` trong [SpriteKitPlantView.swift](file:///Users/vuongquanghuy/code/prj_ios/terrariumidle_ios/terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Views/SpriteKitPlantView.swift).
   - Đăng ký khởi tạo node và gán tap animation trong [SpriteKitPlantScene.swift](file:///Users/vuongquanghuy/code/prj_ios/terrariumidle_ios/terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Scenes/SpriteKitPlantScene.swift).

## Quy ước Asset Cây (Plant Asset Convention)

- **`Asset-1`** (hoặc ảnh đại diện `aloe-vera@4.167x`, `begonia-rex@4.167x`): Ảnh nền/ảnh đại diện của cây (ảnh tĩnh dùng làm thumbnail và đối chiếu toạ độ). **Tuyệt đối KHÔNG đưa vào scene làm hiệu ứng hay layer chuyển động**.
- **`Asset-2` -> `Asset-99`**: Các thành phần hoạt ảnh động (lá cây, cành, hoa uốn lượn). Toàn bộ cây trưởng thành được ghép và diễn hoạt từ các thành phần này.
- **`Asset-100`**: Trạng thái gieo hạt giống (Level 1).
- **`Asset-200`**: Trạng thái cây con (Level 2).
- **Toạ độ ghép lá**: Phải đối chiếu pixel chính xác với ảnh avatar để đảm bảo khi ghép lại, cây hoàn toàn khớp với ảnh gốc, không bị lệch tán hay khoảng trắng.
- **Toạ độ hạt giống & cây con**: Điểm neo `anchorPoint = (0.5, 0.05)`, vị trí trong scene đặt ngập nhẹ trong miệng chậu (`pos: (0, -18.5)`), không đặt `y > 0` gây bay lơ lửng.
