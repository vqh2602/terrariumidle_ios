---
name: plant-asset-convention
description: Quy chuẩn quản lý, phân bổ Asset và xây dựng hiệu ứng SpriteKit cho các loài cây (Plants) trong Terrarium Idle iOS. Áp dụng khi tạo mới cây, tổ chức asset hoặc xây dựng hoạt ảnh cây SpriteKit.
---

# Quy chuẩn Cấu trúc Asset & Hoạt ảnh Cây (Plant Asset Convention)

Áp dụng cho tất cả các loài cây (`Plant1`, `Plant2`, `Plant3`,...) trong dự án `terrariumidle_ios`. Lấy `Plant1` làm chuẩn kiến trúc.

## 1. Phân bổ và Đánh số Asset (Asset ID Naming Convention)

Khi cấu hình asset trong `Assets.xcassets/Plants/<plant_folder>/` (Ví dụ `plant2/` sử dụng tiền tố `plant2_Asset-...` hoặc tên đặc thù theo yêu cầu):

| Asset ID | Tên Asset (`plantX_...`) | Vai trò & Mục đích | Cơ chế hoạt động & Quy tắc sử dụng |
| :--- | :--- | :--- | :--- |
| **`Asset-1` / Avatar** | `plantX_Asset-1` (hoặc `aloe-vera@4.167x`) | **Ảnh đại diện tĩnh (Avatar / Reference)** | **KHÔNG** đưa vào làm hiệu ứng chuyển động trong Scene SpriteKit. Chỉ dùng làm ảnh đại diện (avatar/thumbnail/store preview) hoặc làm ảnh tham chiếu (reference canvas) để đối chiếu tọa độ pixel, anchor point, scale khi dựng hoạt ảnh. |
| **`Asset-2` -> `Asset-99`** | `plantX_Asset-2`... | **Thành phần hoạt ảnh động (Animated Parts)** | Các bộ phận cấu tạo nên cây trưởng thành (Level 3+): các phiến lá, cuống, cành cây, bông hoa. Mỗi phần tử được render riêng biệt qua SpriteKit `SKSpriteNode` với điểm neo (`anchorPoint`) tại cuống/gốc và chạy hiệu ứng uốn lượn, lay động mềm mại trong gió (`SKAction.rotateBy`, `scaleY`). Khi ghép toàn bộ các asset này lại sẽ tạo thành một cây hoàn chỉnh mà không cần `Asset-1`. |
| **`Asset-100`** | `plant1_Asset-100` | **Gieo hạt (Seed Stage - Level 1)** | Hiển thị trạng thái hạt giống trong đất hoặc mầm vừa nhú. Ánh xạ tái sử dụng từ Plant 1. Kèm hiệu ứng thở nhẹ / nảy mầm khi người chơi chạm vào (`tapSquashStretch`). |
| **`Asset-200`** | `plant1_Asset-200` | **Cây con (Sprout Stage - Level 2)** | Hiển thị trạng thái cây con 2 mầm lá non. Ánh xạ tái sử dụng từ Plant 1. Kèm hiệu ứng lắc lư đung đưa (`swayAction`) và nhún nhẹ (`bobAction`). |

---

## 2. Mô hình Kiến trúc Lai: Visual `.sks` + Swift Code Animation (BẮT BUỘC ĐẦY ĐỦ 3 FILE)

Mỗi loài cây mới `PlantX` bắt buộc phải có folder `Plants/PlantX/` chứa đầy đủ:
1. `PlantXScene.sks`
2. `PlantXNode.swift`
3. `PlantXView.swift`

```mermaid
flowchart LR
    SKS["Xcode Scene Editor (*.sks)\n- Kéo thả vị trí cây, lá, mây, mặt trời\n- Chỉnh kích thước, xoay, zPosition, anchorPoint\n- Preview trực quan ngay trong Xcode"] --> Engine["SpriteKit Runtime"]
    Swift["Swift Code (*.swift)\n- Nạp node từ *.sks\n- Gán animation: gió thổi, uốn cong lá, lớn lên\n- Tương tác tap, nảy bọt khí, đổi level"] --> Engine
    Engine --> Output["60 FPS Metal GPU Output\n(Tự động cập nhật toạ độ mới khi sửa .sks)"]
```

### Yêu cầu cấu trúc file `.sks`:
- Kích thước scene đúng bằng kích thước ảnh tham chiếu (ví dụ: Plant1: 428x862, Plant2: 484x641, Plant3: 796x538), `anchorPoint = (0.5, 0.0)`.
- **Tự fill Asset vào mọi Sprite**: Mọi `SKSpriteNode` (`seedSprite`, `sproutSprite`, `leaf_X`) trong `.sks` **BẮT BUỘC PHẢI CÓ TEXTURE THẬT** (`imageNamed: ...`) tương ứng trong `Assets.xcassets`. Tuyệt đối không để `_texture = nil / $null` hoặc `color: .clear` khiến Xcode Scene Editor hiển thị khung chữ nhật rỗng.
- 3 nhóm node chuẩn:
  - `seedNode` (pos: (0, 0)) -> child `seedSprite` (pos: (0, -18.5), anchor: (0.5, 0.05), zPos: 10, texture: `plant1_Asset-100@4.167x`)
  - `sproutNode` (pos: (0, 0)) -> child `sproutSprite` (pos: (0, -18.5), anchor: (0.5, 0.05), zPos: 10, texture: `plant1_Asset-200@4.167x`)
  - `matureNode` (pos: (0, -10)) -> chứa các phiến lá con `leaf_1`, `leaf_2`,... sắp xếp đúng z-order (từ lớp sau ra trước), toạ độ cuống cắm vào chậu.

---

## 3. Quy tắc triển khai Code SpriteKit (`PlantXNode.swift`)

1. **SKS Scene Loader cho CẢ 3 TRẠNG THÁI (Seed, Sprout, Mature)**:
   - Khai báo hàm `loadSceneTemplate() -> SKScene?` nạp `PlantXScene.sks`.
   - Cả 3 hàm `buildSeedState` (Level 1), `buildSproutState` (Level 2) và `buildMatureState` (Level 3+) **BẮT BUỘC** phải ưu tiên nạp trực tiếp node tương ứng (`seedNode`, `sproutNode`, `matureNode`) từ `PlantXScene.sks`.
   - Tuyệt đối **KHÔNG ĐƯỢC** hardcode toạ độ Y của hạt giống/cây con bằng công thức như `containerSize.height * 0.08` làm trôi lệch vị trí và khiến cây con bay lơ lửng trên không trung.
   - Luôn có kiểm tra fallback tự fill texture: `if sprite.texture == nil { sprite.texture = loadTexture(...) }`.
   - Khi chỉnh vị trí trong Xcode Scene Editor (`.sks`), code Swift phải tự động sử dụng vị trí mới đó mà không cần sửa code.

2. **Cơ chế Fallback Procedural**:
   - Luôn định nghĩa `leavesMetadata` chuẩn để nếu file `.sks` chưa tải được thì code vẫn render chính xác 100% hình thể cây.

---

## 4. Bóc tách Toạ độ từ SVG & Công thức chuyển đổi SpriteKit (SVG Extraction & Coordinate Conversion)

Khi Designer hoàn thiện cây trên **Figma** hoặc **Adobe Illustrator**, họ có thể xuất một file `.svg` chứa toàn bộ các layer bộ phận cây (hoặc ảnh đặt đúng vị trí trên canvas). File SVG chứa các thẻ `<image>` hoặc layer `<g id="...">` với toạ độ top-left `(x, y)` và kích thước `(width, height)`.

### 4.1. Khác biệt hệ toạ độ giữa SVG và SpriteKit

| Tiêu chí | Hệ toạ độ SVG / Figma | Hệ toạ độ SpriteKit Scene (`PlantXScene`) |
| :--- | :--- | :--- |
| **Gốc toạ độ `(0, 0)`** | **Góc Trên - Trái** (Top-Left) | **Chính Giữa - Đáy chậu** (Bottom-Center, `anchorPoint = (0.5, 0.0)`) |
| **Trục X** | Hướng sang phải ($0 \rightarrow \text{canvasWidth}$) | Đối xứng qua tâm ($-\frac{\text{canvasWidth}}{2} \rightarrow +\frac{\text{canvasWidth}}{2}$) |
| **Trục Y** | Hướng **chúc xuống dưới** ($+Y$ đi xuống) | Hướng **chỉ lên trên** ($+Y$ đi lên trời) |

### 4.2. Công thức quy đổi chuẩn (Swift Code)

Cho một phiến lá trong file SVG có toạ độ `(svgX, svgY)`, kích thước `(width, height)` trên canvas `(baseCanvasWidth, baseCanvasHeight)` và điểm neo cuống lá `(anchorX, anchorY)`:

```swift
// 1. Trục X: Dịch mốc từ mép trái SVG sang tâm giữa SpriteKit
let skX = (svgX + anchorX * width) - (baseCanvasWidth / 2.0)

// 2. Trục Y: Lật ngược trục Y từ gốc đỉnh SVG sang gốc đáy SpriteKit (kèm offset cắm vào chậu ~10px)
let skY = baseCanvasHeight - svgY - (1.0 - anchorY) * height - 10.0
```

### 4.3. Quy chuẩn xác định Điểm Neo Cuống Lá (`anchorPoint`)

Điểm neo (`anchorPoint`) là vị trí gốc/cuống của phiến lá cắm vào thân hoặc chậu, dùng làm tâm xoay khi lá đung đưa trong gió (`SKAction.rotate`):
- **Lá hướng/nghiêng sang trái** (`isLeft: true`): Tâm cuống lá nằm ở góc dưới bên phải phiến lá $\rightarrow$ `anchorX ≈ 0.80 - 0.95`, `anchorY ≈ 0.00 - 0.05`.
- **Lá hướng/nghiêng sang phải** (`isLeft: false`): Tâm cuống lá nằm ở góc dưới bên trái phiến lá $\rightarrow$ `anchorX ≈ 0.05 - 0.20`, `anchorY ≈ 0.00 - 0.05`.
- **Lá mọc thẳng giữa**: Tâm cuống lá ở chính giữa đáy $\rightarrow$ `anchorX ≈ 0.50`, `anchorY ≈ 0.00`.

### 4.4. Tool tự động bóc tách file SVG (`parse_plant_svg.py`)

Dự án cung cấp sẵn script bóc tách tự động tại:
`scripts/parse_plant_svg.py`

Cách chạy:
```bash
python3 .agent/skills/plant-asset-convention/scripts/parse_plant_svg.py <path/to/plant.svg> [--offset-y 10.0]
```

Script sẽ tự động đọc canvas `viewBox`, quét toàn bộ các layer/thẻ lá (`leaf_X`, `PlantX-X`), tính toán hướng lá (`isLeft`), điểm neo (`anchorX`), toạ độ `(skX, skY)` và in ra mảng mã nguồn Swift `leavesMetadata: [LeafData]` sẵn sàng để dán vào `PlantXNode.swift`.

