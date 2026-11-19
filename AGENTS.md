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
   - **QUY CHUẨN HIỆU ỨNG BỌT KHÍ OXY (Oxygen Bubbles Convention - LẤY PLANT1 LÀM CHUẨN)**:
     - Bọt khí **BẮT BUỘC** phải add trực tiếp vào chính Node cây (`addChild(bubble)`), **TUYỆT ĐỐI KHÔNG** add vào `plantRootNode` vì `plantRootNode` bị `setScale(baseScale)` (thường thu nhỏ chỉ còn 0.2 ~ 0.25) khiến bọt khí bị teo nhỏ như hạt bụi và giới hạn không gian bay.
     - Bọt khí phải có node con `highlight` (điểm sáng phản chiếu trắng $30\%$ radius, alpha 0.8) tạo hiệu ứng 3D căng bóng.
     - Kích thước bọt chuẩn theo `containerSize`: Hạt (radius $1.8 \dots 3.0$), Cây con ($2.2 \dots 3.8$), Trưởng thành ($3.5 \dots 7.5$, $8 \dots 12$ bọt).
     - Phân bổ vị trí sinh bọt: Chuyển đổi vị trí lá sang toạ độ cây (`randomLeaf.parent?.convert(randomLeaf.position, to: self)`) hoặc trải đều tự nhiên khắp khung cây ($-44\% \dots +44\%$ chiều rộng, $18\% \dots 90\%$ chiều cao) với quãng đường bay $60 \dots 115\text{pt}$ và độ giãn nở `scaleUp: 1.30`.
     - Thân cọc/trụ leo (`assetId: 2` ở cây leo hoặc cây có thân riêng) không lắc độc lập làm rời cuống lá khỏi cành, thân chính chỉ đung đưa rất nhẹ ($0.003 \dots 0.008\text{rad}$).

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

## Quy chuẩn & Công thức bóc tách toạ độ từ SVG (SVG Coordinate Conversion)

Khi xuất cây từ Figma / Adobe Illustrator dạng file `.svg` để lấy vị trí các bộ phận:
- **Hệ toạ độ SVG**: Gốc `(0, 0)` tại góc **Trên - Trái** (Top-Left), trục Y hướng xuống dưới (`+Y` đi xuống).
- **Hệ toạ độ SpriteKit Scene (`PlantXScene`)**: Canvas `baseCanvasWidth x baseCanvasHeight`, gốc `(0, 0)` tại **Chính Giữa - Đáy chậu** (Bottom-Center, `anchorPoint = (0.5, 0.0)`), trục Y hướng lên trời (`+Y` đi lên).
- **Công thức quy đổi toạ độ SpriteKit (`skX`, `skY`)**:
  ```swift
  // Chuyển trục X: từ mép trái sang tâm giữa canvas
  let skX = (svgX + anchorX * width) - (baseCanvasWidth / 2.0)

  // Lật ngược trục Y: từ đỉnh SVG về đáy chậu (kèm offset cắm vào miệng chậu ~10px)
  let skY = baseCanvasHeight - svgY - (1.0 - anchorY) * height - 10.0
  ```
- **Quy ước điểm neo cuống lá (`anchorPoint` tại gốc lá)**:
  - Lá nghiêng sang trái (`isLeft: true`): cuống lá ở góc dưới bên phải (`anchorX: 0.80 -> 0.95`, `anchorY: 0.00 -> 0.05`).
  - Lá nghiêng sang phải (`isLeft: false`): cuống lá ở góc dưới bên trái (`anchorX: 0.05 -> 0.20`, `anchorY: 0.00 -> 0.05`).
  - Lá thẳng giữa: cuống lá ở chính giữa đáy (`anchorX: 0.50`, `anchorY: 0.00`).
- **Tool tự động trích xuất & cập nhật**: Dùng script `.agent/skills/plant-asset-convention/scripts/parse_plant_svg.py`:
  ```bash
  python3 .agent/skills/plant-asset-convention/scripts/parse_plant_svg.py --plant <X>
  ```

- **Thư mục lưu trữ SVG chuẩn**: Mọi file SVG trích xuất từ thiết kế được đặt tại `terrariumidle_ios/Resources/SVGPlants/plantX.svg`.

- **Quy trình Zero-Prompt (Khi người dùng chỉ ra lệnh ngắn: "từ plantX, sắp xếp lại toạ độ scene", "sắp xếp lại toạ độ plant X từ file svg" hoặc tag @plantX.svg)**:
  Agent **BẮT BUỘC** tự động thực thi ngay quy trình sau mà không cần người dùng hướng dẫn thêm prompt:
  1. Tìm file SVG tại `terrariumidle_ios/Resources/SVGPlants/plantX.svg` (hoặc file được tag).
  2. Bóc tách các thành phần cây (thẻ `<image>` hoặc vector `<g>/<path>`), trích xuất toạ độ pixel và kích thước `(x, y, w, h)`.
  3. Ánh xạ với canvas `baseCanvasWidth x baseCanvasHeight` và các layer asset trong `Assets.xcassets/Plants/plantX/`.
  4. Tính toán điểm neo cuống lá (`anchorPoint`) và toạ độ SpriteKit `(skX, skY)` theo đúng công thức chuẩn.
  5. Tự động cập nhật đồng bộ vào **CẢ 2 FILE**:
     - `terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/PlantX/PlantXScene.sks`: cập nhật toạ độ `_position` và `_anchorPoint` cho từng `leaf_X`.
     - `terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/PlantX/PlantXNode.swift`: cập nhật mảng `leavesMetadata`.
  6. Kiểm tra toàn vẹn bằng `plutil -lint` và `swiftc -parse`.


