---
name: plant-asset-convention
description: Quy chuẩn quản lý, phân bổ Asset và xây dựng hiệu ứng SpriteKit cho các loài cây (Plants) trong Terrarium Idle iOS. Áp dụng khi tạo mới cây, tổ chức asset hoặc xây dựng hoạt ảnh cây SpriteKit.
---

# Quy chuẩn Cấu trúc Asset & Hoạt ảnh Cây (Plant Asset Convention)

Áp dụng cho tất cả các loài cây (`Plant1`, `Plant2`, `Plant3`,...) trong dự án `terrariumidle_ios`. Lấy `Plant1` làm chuẩn kiến trúc.

## Ngân sách Texture Cây & Quy trình Sinh Plant Nhẹ Bộ nhớ (BẮT BUỘC)

- **Ngân sách mỗi cây trưởng thành: tối đa 4 MiB RGBA** cho tổng các texture khác nhau được `matureNode` tham chiếu. Khi vượt, chuẩn hóa về khoảng **3.75 MiB** để chừa sai số làm tròn pixel. Không chỉ kiểm tra từng ảnh: Plant28 có 30 lớp từng gây tổng khoảng 72 MiB.
- **Cạnh dài texture lá/thân tối đa 768 px; canvas thiết kế tối đa 1024 đơn vị.** Ảnh đại diện/composite không dùng trong animation cũng phải được thu nhỏ, tối đa 1024 px; ảnh tham chiếu được scale đồng bộ với bộ thiết kế. Không upscale ảnh nhỏ.
- **Dùng cùng một hệ số scale cho toàn bộ hình ghép**, không ép từng lá về cùng chiều rộng/cao. Scale canvas, vị trí/kích thước mọi node, group offset, `leavesMetadata`, canvas constants Swift, tọa độ/kích thước fallback và cả hạt/mầm để giữ kích thước hiển thị ở cả ba trạng thái. Giữ nguyên anchor, zPosition, góc nghỉ và kiểu animation. Pixel ảnh làm tròn nguyên; tọa độ thiết kế có thể là số thực.
- Các giá trị chuẩn `-18.5` (hạt/mầm), `-10` (mature group) và kích thước fallback là giá trị trong **hệ thiết kế nguồn**; khi chuẩn hóa phải nhân cùng hệ số, không ghi đè lại offset nguồn vào scene đã tối ưu. `plantRootNode.position` vẫn luôn `.zero`.
- Giữ SVG nguồn làm tham chiếu. Không khôi phục PNG độ phân giải lớn vào asset runtime khi parse/gen lại. Không chạy lại toàn bộ generator lên các cây đã chỉnh thủ công chỉ để tối ưu ảnh; dùng công cụ bên dưới để giữ nguyên tọa độ và animation hiện tại.
- Công cụ chuẩn: `.agent/skills/plant-asset-convention/scripts/optimize_plant_assets.py` (Python standard library + `sips`, không cần Pillow):
  ```bash
  # Audit, không sửa file
  python3 .agent/skills/plant-asset-convention/scripts/optimize_plant_assets.py
  # Tối ưu mọi cây, đồng bộ PNG + SKS + Swift và sửa preview
  python3 .agent/skills/plant-asset-convention/scripts/optimize_plant_assets.py --apply
  # Chỉ một cây
  python3 .agent/skills/plant-asset-convention/scripts/optimize_plant_assets.py --plant 28 --apply
  # Chốt kiểm tra sau mỗi lần gen; phải trả exit code 0
  python3 .agent/skills/plant-asset-convention/scripts/optimize_plant_assets.py --check
  ```
- `generate_plants_20_30.py` và `parse_plant_svg.py` phải gọi bước tối ưu sau khi cập nhật các file. **Mọi generator cây mới cũng bắt buộc áp dụng bước này trước khi báo hoàn tất.** Không chạy build để kiểm tra ngân sách; dùng audit, `plutil -lint`, `swiftc -parse`, và đối chiếu bố cục trước/sau.


## 1. Phân bổ và Đánh số Asset (Asset ID Naming Convention)

Khi cấu hình asset trong `Assets.xcassets/Plants/<plant_folder>/` (Ví dụ `plant2/` sử dụng tiền tố `plant2_Asset-...` hoặc tên đặc thù theo yêu cầu):

| Asset ID | Tên Asset (`plantX_...`) | Vai trò & Mục đích | Cơ chế hoạt động & Quy tắc sử dụng |
| :--- | :--- | :--- | :--- |
| **`Asset-1` / Avatar** | `plantX_Asset-1` (hoặc `aloe-vera@4.167x`) | **Ảnh đại diện tĩnh (Avatar / Reference)** | **KHÔNG** đưa vào làm hiệu ứng chuyển động trong Scene SpriteKit. Chỉ dùng làm ảnh đại diện (avatar/thumbnail/store preview) hoặc làm ảnh tham chiếu (reference canvas) để đối chiếu tọa độ pixel, anchor point, scale khi dựng hoạt ảnh. |
| **`Asset-2` -> `Asset-99`** | `plantX_Asset-2`... | **Thành phần hoạt ảnh động (Animated Parts)** | Các bộ phận cấu tạo nên cây trưởng thành (Level 3+): các phiến lá, cuống, cành cây, bông hoa. Mỗi phần tử được render riêng biệt qua SpriteKit `SKSpriteNode` với điểm neo (`anchorPoint`) tại cuống/gốc và chạy hiệu ứng uốn lượn, lay động mềm mại trong gió (`SKAction.rotate(toAngle:)`, `scaleY`). Khi ghép toàn bộ các asset này lại sẽ tạo thành một cây hoàn chỉnh mà không cần `Asset-1`. |
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

3. **Quy chuẩn Hiệu ứng Bọt khí Oxy (Oxygen Bubbles Convention - Lấy Plant 1 làm chuẩn)**:
   - **Thêm trực tiếp vào Node cây**: Bọt khí phải được add trực tiếp vào chính Node cây (`addChild(bubble)`), **TUYỆT ĐỐI KHÔNG** add vào `plantRootNode` vì `plantRootNode` bị `setScale(baseScale)` (thường thu nhỏ 0.2 ~ 0.25) khiến bọt khí bị teo nhỏ và không bay được ra khắp khung hình.
   - **Điểm sáng phản chiếu (Specular Highlight)**: Thêm node con `highlight` màu trắng (radius bằng 30% bọt, alpha 0.8) tạo hiệu ứng bọt khí 3D căng bóng.
   - **Kích thước và số lượng**:
     - Hạt giống (Lv.1): 1 - 2 bọt nhỏ (radius 1.8 - 3.0 pt).
     - Cây con (Lv.2): 3 - 4 bọt vừa (radius 2.2 - 3.8 pt).
     - Trưởng thành (Lv.3+): 8 - 12 bọt dồi dào (radius 3.5 - 7.5 pt).
   - **Vị trí sinh bọt**: Phân bổ từ các vị trí phiến lá ngẫu nhiên (`randomLeaf.parent?.convert(randomLeaf.position, to: self)`) hoặc trải đều tự nhiên khắp khung cây ($-44\% \dots +44\%$ chiều rộng, $18\% \dots 90\%$ chiều cao) với quãng đường bay $60 \dots 115\text{pt}$ và độ giãn nở `scaleUp: 1.30`.
   - **Thân cọc/trụ leo**: Nếu cây có cọc gỗ hoặc thân chính riêng (`assetId: 2`), không được lắc độc lập làm rời cuống lá khỏi cành; thân chính chỉ đung đưa rất nhẹ ($0.003 \dots 0.008\text{rad}$).

4. **Quy chuẩn Chống Trôi Góc & Xoay Lật 180 Độ (Anti-Rotation Drift Convention - BẮT BUỘC TUÂN THỦ)**:
   - **CẤM TUYỆT ĐỐI DÙNG `SKAction.rotate(byAngle:)`**: Trong cả hiệu ứng chạm (`PlantMotionEffect`) và hiệu ứng gió lay nghỉ (`addIdleSwayAnimation`) của cành, lá, thân hay gốc cây.
     * *Nguyên nhân*: `rotate(byAngle:)` tính xoay tương đối. Khi chạm liên tục (spam tap), chuỗi animation cũ bị ngắt giữa chừng qua `removeAction` trước khi kịp quay về, chuỗi mới cộng dồn góc xoay. Tích luỹ qua nhiều lần chạm khiến góc xoay lệch dần tới $180^\circ$ ($\pi\text{ rad}$), làm lá hoặc cây bị úp ngược xuống chậu.
   - **BẮT BUỘC DÙNG `SKAction.rotate(toAngle:)` TÍNH THEO GÓC NGHỈ TUYỆT ĐỐI**:
     * Mọi chuyển động xoay phải tính dao động quanh góc nghỉ ban đầu: `SKAction.rotate(toAngle: restAngle ± delta, duration: ...)`.
   - **Ghi nhớ và khởi tạo `leaf.restZRotation`**:
     * Extension `SKNode.restZRotation` (trong `PlantMotionEffect.swift`) lưu trữ góc nghỉ ban đầu.
     * Khi khởi tạo bất kỳ phiến lá nào (`leaf_X`) trong `buildMatureState` (cả nhánh `.sks` lẫn procedural fallback), **BẮT BUỘC** gán:
       ```swift
       leaf.restZRotation = leaf.zRotation
       ```
   - **Reset góc nghỉ ngay đầu chuỗi tap action**:
     * Trong mọi `PlantMotionEffect`, ngay sau khi `leaf.removeAction(forKey:)` hoặc `root.removeAction(forKey:)`, **BẮT BUỘC** đưa góc xoay về vị trí nghỉ ngay lập tức:
       ```swift
       leaf.zRotation = leaf.restZRotation
       root.zRotation = 0.0
       ```
   - **Chốt chặn phục hồi ở cuối sequence**:
     * Chuỗi tap action luôn phải kết thúc bằng `SKAction.rotate(toAngle: restAngle)` kèm block chốt:
       ```swift
       SKAction.run { [weak leaf] in leaf?.zRotation = restAngle }
       ```
   - **Idle Sway Animation quanh `restZRotation`**:
     * Trong `addIdleSwayAnimation()`, lá phải đu đưa quanh `restZRotation`:
       ```swift
       let rest = leaf.restZRotation
       let swayRight = SKAction.rotate(toAngle: rest + swayAngle, duration: duration)
       let swayLeft  = SKAction.rotate(toAngle: rest - swayAngle, duration: duration)
       ```
   - **Debounce chống spam tap ở tầng Scene/View**:
     * Mọi Scene/View nhận touch tap (`SpriteKitPlantScene`, `TerrariumSlotView`) **BẮT BUỘC** có debounce tối thiểu 80ms (`CACurrentMediaTime() - lastTapTime < 0.08`) để ngăn bão sự kiện touch.

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

### 4.4. Tool tự động bóc tách và cập nhật Scene (`parse_plant_svg.py`)

Dự án cung cấp sẵn script bóc tách và cập nhật tự động tại:
`scripts/parse_plant_svg.py`

Cách chạy tự động theo Plant ID:
```bash
python3 .agent/skills/plant-asset-convention/scripts/parse_plant_svg.py --plant <X>
```

Hoặc chỉ định file SVG cụ thể:
```bash
python3 .agent/skills/plant-asset-convention/scripts/parse_plant_svg.py <path/to/plant.svg> --update [--offset-y 10.0]
```

Script sẽ tự động:
1. Đọc kích thước canvas và scale tương ứng với `baseCanvasWidth x baseCanvasHeight` của `PlantXNode.swift`.
2. Quét toàn bộ các phiến lá/bộ phận (cả thẻ `<image>` và vector `<g>/<path>`).
3. Tự động tính toán điểm neo cuống lá (`anchorPoint`) và toạ độ SpriteKit `(skX, skY)`.
4. Cập nhật trực tiếp vào file **`PlantXScene.sks`** và **`PlantXNode.swift`**.

### 4.5. Cơ chế Zero-Prompt Workflow (Quy trình tự động không cần Prompt dài)

- **Vị trí lưu trữ SVG**: File SVG xuất từ Figma / Illustrator luôn được đặt tại:
  `terrariumidle_ios/Resources/SVGPlants/plantX.svg`
- **Tác vụ khi người dùng chỉ ra lệnh ngắn** (ví dụ: *"từ plantX, sắp xếp lại toạ độ scene đi"*, *"sắp xếp lại toạ độ plant X từ file svg"*, hoặc tag `@plantX.svg`):
  1. Tự động lấy file `terrariumidle_ios/Resources/SVGPlants/plantX.svg`.
  2. Bóc tách toạ độ và quy đổi sang hệ toạ độ SpriteKit (`skX, skY`).
  3. Đồng bộ cập nhật vào cả `PlantXScene.sks` (toạ độ và điểm neo visual) và `PlantXNode.swift` (`leavesMetadata`).
  4. Chạy kiểm tra linting (`plutil -lint`) và Swift syntax (`swiftc -parse`).

---

## 5. Quy chuẩn Phong cảnh Nền SpriteKit & Tối ưu Hóa VRAM GPU (Landscape Convention & GPU Texture Memory Optimization)

Áp dụng cho tất cả các Phong cảnh nền (`Landscape1`, `Landscape2`, `Landscape6`, `Landscape7`,...) trong `terrariumidle_ios`:

### 5.1. Cấu trúc Bộ 3 File Phong Cảnh Chuẩn
Mỗi Phong cảnh `LandscapeX` được đặt trong thư mục `Apps/Compoments/SpriteKitComponents/Landscapes/LandscapeX/`:
- **`LandscapeXScene.sks` (Thiết kế trực quan trong Xcode Scene Editor)**:
  - Canvas chuẩn $750 \times 1334$ (hoặc $1700 \times 1943.233$ dạng dọc portrait), `anchorPoint = (0.5, 0.5)` hoặc `(0.5, 0.0)`.
  - Bắt buộc gắn sẵn texture thật vào mọi sprite trong scene (`bgNode`, `sunNode`, các lớp núi `mountain_X`, mây `cloud_X`).
- **`LandscapeXNode.swift` (Lập trình Hoạt cảnh & Tương tác)**:
  - Tuân thủ protocol `LandscapeInteractiveNode` (`configure(containerSize:)`, `asNode`, `playTapAnimation(at:)`).
  - Nạp ưu tiên từ file `.sks` (`loadSceneTemplate()`), kèm cơ chế Fallback Procedural an toàn khi scene chưa tải được.
  - Quản lý toạ độ nghỉ `restPositions: [String: CGPoint]` để chống trôi lệch toạ độ tuyệt đối khi bị ngắt bởi tương tác tap.
- **`LandscapeXView.swift` (Xem trước SwiftUI độc lập)**:
  - Bọc `SpriteView(scene: activeScene, options: [.allowsTransparency, .shouldCullNonVisibleNodes])` kèm SwiftUI `#Preview`.
- **Đăng ký vào hệ thống**:
  - Đăng ký ID và các alias trong `LandscapeFactory.createLandscape(id:containerSize:)`.
  - Bổ sung `"sksFile": "LandscapeXScene.sks"` trong `landscapes_data.json`.

### 5.2. Quy chuẩn Bóc Tách SVG & Thứ Tự Phân Tầng Chiều Sâu (Back-to-Front Z-Order)
- **Thư mục lưu trữ SVG phong cảnh**: `terrariumidle_ios/Resources/SVGLandscape/landscapeX.svg`.
- **Hệ toạ độ chuyển đổi**:
  - SVG: Gốc $(0, 0)$ tại Top-Left, Y chúc xuống dưới.
  - SpriteKit: Gốc $(0, 0)$ tại Center $(0.5, 0.5)$ hoặc Bottom-Center $(0.5, 0.0)$, Y hướng lên trời.
- **Thứ tự phân tầng chuẩn từ sau ra trước (Back-to-Front)**:
  $$\mathbf{Background\ (Nền\ trời,\ z = 0)} \;\longrightarrow\; \mathbf{Mặt\ trời\ (Sun,\ z = 5)} \;\longrightarrow\; \mathbf{Dãy\ núi\ (Layers\ từ\ xa\ tới\ gần,\ z = 10 \dots 20)} \;\longrightarrow\; \mathbf{Hạt\ hiệu\ ứng\ (z = 30)}$$
  * **Hiện tượng che khuất tự nhiên**: Đỉnh của các dãy núi xa vươn cao hơn đáy mặt trời và che khuất chân mặt trời, tạo hiệu ứng vầng dương đang lặn/mọc sau núi. **TUYỆT ĐỐI KHÔNG** đặt mặt trời đè lên trên dãy núi làm mất đường chân trời tự nhiên.

### 5.3. Quy chuẩn Tối Ưu Hóa VRAM GPU & Chống Lỗi Metal / SIGKILL (BẮT BUỘC TUÂN THỦ)
- **Giới hạn phần cứng Apple Metal**: Mọi texture nạp vào Metal GPU **TUYỆT ĐỐI KHÔNG ĐƯỢC VƯỢT QUÁ $8192\text{px}$** ở cả chiều rộng lẫn chiều cao. Ảnh $> 8192\text{px}$ sẽ kích hoạt assertion crash: `MTLTextureDescriptor has height/width greater than the maximum allowed size of 8192`.
- **Ngăn ngừa sập ứng dụng Out Of Memory (`SIGKILL` / Jetsam)**:
  * Ảnh xuất thô tỉ lệ `@4.167x` từ Figma/AI thường có kích thước $3000\text{px} - 7000\text{px}$. Nạp đồng loạt 10-20 layer sẽ ngốn $> 1.2\text{ GB}$ VRAM, khiến iOS Jetsam gửi tín hiệu `SIGKILL` buộc dừng app.
  * **BẮT BUỘC Resample về kích thước Retina chuẩn ($750\text{px} - 1000\text{px}$)**:
    - Nền toàn màn hình: tối đa $750\text{px} - 1000\text{px}$ chiều ngang (hoặc $1334\text{px}$ chiều dọc).
    - Các thành phần nhỏ hơn (mặt trời, mây, sóng, rặng đá): resample về $300\text{px} - 600\text{px}$.
  * **Nền đơn sắc (`bgNode`)**: Dùng `SKSpriteNode(color: ...)` hoặc ảnh texture siêu nhỏ ($64 \times 64\text{px}$ hoặc $128 \times 128\text{px}$), tiêu tốn $0\text{ MB}$ VRAM texture thay vì $16 - 30\text{ MB}$.
  * **Hào quang & Shape Node**: Tránh lạm dụng `SKShapeNode.glowWidth` lớn (gây pass blur offscreen ngốn GPU), ưu tiên dùng các vành tròn đồng tâm phẳng với alpha dịu nhẹ.
  * **Particle Limiting**: Giới hạn số lượng hạt bụi/sao hoạt động đồng thời (tối đa 12-15 hạt) kèm `removeFromParent()`.
  * **Texture Caching**: Khai báo `static var sharedTextureCache: [String: SKTexture]` để tái sử dụng texture trong VRAM khi chuyển cảnh hoặc resize view.
  * **Tool tự động tối ưu toàn bộ Landscape**:
    ```bash
    python3 .agent/skills/plant-asset-convention/scripts/optimize_all_landscapes.py
    ```





### Ngân sách texture sticker & bước tối ưu bắt buộc

- Tổng texture khác nhau được scene sticker tham chiếu **không vượt 4 MiB RGBA** (`width * height * 4`); nếu vượt, giảm về mục tiêu 3.75 MiB hoặc thấp hơn. Mọi ảnh layer và thumbnail/composite có cạnh dài **tối đa 768 px**, giữ alpha và tỉ lệ, không upscale ảnh nhỏ.
- **Phân biệt pixel ảnh với hệ tọa độ thiết kế**: các sticker hiện có dùng canvas khoảng 122–433 đơn vị, trong khi PNG xuất `@4.167x` có thể cao 1100–1800 px. Khi canvas/sprite đã nhỏ và Swift dùng cùng hệ tọa độ, chỉ resample PNG và cập nhật texture `_size`, `_pixelSize`; **không nhân lại tọa độ/canvas/Swift theo tỉ lệ giảm pixel**. Giữ nguyên vị trí, bounds, anchor, zPosition, rig và fallback. Canvas sticker mặc định không vượt 512 đơn vị; nếu thiết kế thật sự quá lớn, phải chuẩn hóa scene và Swift cùng nhau trước.
- Đồng bộ preview `_PB_previewSKEditorSceneSizeWidth/Height` đúng với `Scene_bounds`. Không để lại preview mẫu `428×862` cho sticker có canvas khác. Dọn object không còn được root tham chiếu và remap đầy đủ UID.
- Dùng một hệ số giảm chung cho các layer của sticker; ảnh đại diện/composite có thể bị giới hạn thêm về 768 px. Giữ các tên asset/alias đang được JSON, Swift hoặc scene sử dụng; không xóa ảnh trùng khi chưa kiểm tra mọi nơi tham chiếu.
- Công cụ chuẩn (Python standard library + `sips`, không build):
  ```bash
  python3 .agent/skills/plant-asset-convention/scripts/optimize_sticker_assets.py
  python3 .agent/skills/plant-asset-convention/scripts/optimize_sticker_assets.py --apply
  python3 .agent/skills/plant-asset-convention/scripts/optimize_sticker_assets.py --sticker 3 --apply
  python3 .agent/skills/plant-asset-convention/scripts/optimize_sticker_assets.py --check
  ```
- **Mọi generator sticker phải gọi `optimize_sticker(...)` sau khi tạo scene và trước khi báo hoàn tất.** `generate_sticker1_scene.py` và `generate_sticker_scenes.py` đã tích hợp. Tìm prototype theo tên node và class trong archive; cấm hardcode chỉ số như `objs[19]` hoặc UID class cố định vì archive có thể đã được thu gọn.
- Kiểm tra PNG/alpha, tính hợp lệ và đầy đủ của texture reference, bố cục trước/sau, `plutil -lint`, ngân sách `--check` và tính lặp lại không thay đổi file sau lần tối ưu đầu tiên. Không chạy lại generator lên scene đã chỉnh tay chỉ để giảm texture; dùng `--apply`.

