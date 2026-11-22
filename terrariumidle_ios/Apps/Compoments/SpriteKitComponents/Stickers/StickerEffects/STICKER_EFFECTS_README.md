# Hệ Thống Hiệu Ứng & Dữ Liệu Sticker (Sticker Tap & Motion Effects System)

Khi người chơi chạm (tap/click) vào Sticker hoặc vật trang trí trong Terrarium Idle iOS, phản hồi tương tác được điều phối qua **hai hệ thống hiệu ứng độc lập và song song**, phân tách thành 2 thư mục chuyên biệt:

1. **`StickerEffects/Motion/` (Hiệu ứng Chuyển động Vật lý - `StickerMotionEffect`)**: Điều khiển đung đưa nhàn rỗi theo gió (Idle Wind Sway), con lắc đu đưa (Pendulum Swing), hoặc nhún nảy đàn hồi (Squash & Stretch spring bounce) lên toàn bộ khung treo, thân sticker và ruy băng.
2. **`StickerEffects/Tap/` (Hiệu ứng Thị giác Dạng Hạt / Ánh Sáng - `StickerTapEffect`)**: Sinh các chùm ánh sáng mặt trời rạng rỡ (Sun Radiance), chùm sao vàng lấp lánh (Sparkle Star Burst), cầu vồng sau mưa (Rainbow Glow) hoặc hào quang kim sắc (Golden Aura) bùng nổ xung quanh sticker tại `zPosition = 200`.

Toàn bộ thông tin danh mục, vị trí hiển thị trên kệ, giá bán và âm thanh SFX được quản lý tập trung và nhất quán thông qua file cấu hình JSON [stickers_data.json](file:///Users/vuongquanghuy/code/prj_ios/terrariumidle_ios/terrariumidle_ios/Apps/Data/Items/stickers_data.json).

```
StickerEffects/
├── Motion/                                  # Hiệu ứng chuyển động vật lý
│   ├── StickerMotionEffect.swift            # Protocol, Context, Enum, Factory
│   ├── WindSwayStickerMotionEffect.swift    # Đung đưa theo gió tự nhiên + tăng nhịp khi tap (Sticker1)
│   ├── ElasticSwingStickerMotionEffect.swift # Con lắc đàn hồi tần số nhanh
│   ├── StandardBounceStickerMotionEffect.swift # Nảy lò xo cho sticker để bàn/dán tường
│   └── SubtleFlutterStickerMotionEffect.swift  # Rung rinh bay bổng vi mô
├── Tap/                                     # Hiệu ứng thị giác dạng hạt / ánh sáng
│   ├── StickerTapEffect.swift               # Protocol, Enum, Factory
│   ├── SunRadianceEffect.swift              # Mặt trời rực rỡ tỏa sáng kèm 12 tia nắng xoay & sao bụi
│   ├── SparkleBurstStickerEffect.swift      # Chùm sao vàng & bạc bung tỏa
│   ├── RainbowGlowEffect.swift              # Vệt cầu vồng tươi sáng sau mưa
│   └── GoldenAuraEffect.swift               # Vòng hào quang vàng kim
└── STICKER_EFFECTS_README.md                # Tài liệu kiến trúc & hướng dẫn JSON toàn diện
```

---

## 1. Hệ Thống Hiệu Ứng Chuyển Động (`StickerMotionEffect`)

Mọi Node Sticker (`Sticker1Node`, v.v.) tuân thủ giao thức `StickerInteractiveNode` đều sở hữu thuộc tính:
```swift
public var motionEffect: StickerMotionEffect = WindSwayStickerMotionEffect()
```

### 1.1. Danh Mục Các Hiệu Ứng Chuyển Động (`Motion Effects`)

| Tên Hiệu Ứng | Lớp Triển Khai (`Class`) | Định Danh Type | Phù Hợp Cho | Đặc Điểm Chuyển Động |
| :--- | :--- | :--- | :--- | :--- |
| **Đung đưa theo gió** | `WindSwayStickerMotionEffect` | `windSway` | Sticker treo (Mặc định: **Sticker1**) | Tự động đu đưa nhàn rỗi (`zRotation: ±0.048 rad`, trôi nổi Y `±2.2pt`), ruy băng bay nhẹ. Khi chạm: lắc mạnh `0.160 rad` (~9.2°) rồi dịu dần về nhịp gió tự nhiên. |
| **Con lắc đàn hồi** | `ElasticSwingStickerMotionEffect` | `elasticSwing` | Sticker treo nhịp nhanh | Lắc con lắc tần số cao quanh đỉnh móc treo kết hợp nhún nảy nén trục Y (`scaleY: 0.92 -> 1.06 -> 1.0`). |
| **Nén nảy lò xo** | `StandardBounceStickerMotionEffect` | `standardBounce` | Sticker để bàn / dán tường | Nén nảy Squash & Stretch tiêu chuẩn (`scaleX: 1.10, scaleY: 0.90 -> bật 0.95/1.07 -> 1.0`). |
| **Rung rinh bay bổng** | `SubtleFlutterStickerMotionEffect` | `subtleFlutter` | Sticker nhỏ / phù hiệu | Rung lắc nhẹ trái/phải tần số nhanh (Micro-flutter/jiggle). |

### 1.2. Protocol `StickerMotionEffect` & `StickerMotionContext`

```swift
public protocol StickerMotionEffect: AnyObject {
    var name: String { get }
    func startIdle(context: StickerMotionContext)
    func stopIdle(context: StickerMotionContext)
    func apply(context: StickerMotionContext)
}
```

Ngữ cảnh `StickerMotionContext` đóng gói đầy đủ:
- `targetNode`: Node nhận chuyển động (với sticker treo là `rigNode`, sticker để bàn là thân chính).
- `secondaryNodes`: Danh sách node con nhận chuyển động phụ thuộc (như 2 dải ruy băng `ribbonLeftNode`, `ribbonRightNode`).
- `initialPosition`: Tọa độ ban đầu chống trôi khi tap dồn dập.
- `isHanging`: Cờ xác định sticker treo hay sticker để bàn.
- `onComplete`: Callback thông báo khi chuỗi chuyển động hoàn tất.

---

## 2. Hệ Thống Hiệu Ứng Thị Giác Khi Chạm (`StickerTapEffect`)

Mọi Sticker quản lý danh sách hiệu ứng hạt/ánh sáng qua thuộc tính:
```swift
public var tapEffects: [StickerTapEffect] = [SunRadianceEffect(), SparkleBurstStickerEffect()]
```

### 2.1. Danh Mục Các Hiệu Ứng Tap (`Tap Effects`)

| Tên Hiệu Ứng | Lớp Triển Khai (`Class`) | Định Danh Type | Phù Hợp Cho | Đặc Điểm Thị Giác |
| :--- | :--- | :--- | :--- | :--- |
| **Mặt trời tỏa sáng** | `SunRadianceEffect` | `sunRadiance` | Búp bê cầu nắng (**Sticker1**) | Vầng hào quang bung tỏa (`halo`), mặt trời vàng mặt cười tươi rói, 12 tia nắng dài ngắn xoay tròn, cùng 14 ngôi sao nắng bung lượn lấp lánh (không bị cắt mép khung). |
| **Chùm sao lấp lánh** | `SparkleBurstStickerEffect` | `sparkleBurst` | Mọi loại Sticker | 16 ngôi sao 4 cánh vàng và bạc bung tỏa 360° bay lên trên và tan biến nhẹ nhàng. |
| **Cầu vồng sau mưa** | `RainbowGlowEffect` | `rainbowGlow` | Búp bê cầu nắng, hoa lá | 6 dải màu cầu vồng uốn cong tỏa sáng rạng ngời phía trên sticker. |
| **Hào quang vàng kim** | `GoldenAuraEffect` | `goldenAura` | Tượng thần, huy hiệu | 3 vòng sóng hào quang ánh kim đồng tâm mở rộng và mờ dần. |

### 2.2. Protocol `StickerTapEffect`

```swift
public protocol StickerTapEffect: AnyObject {
    var name: String { get }
    func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool)
}
```

---

## 3. Khởi Tạo Động Qua Factory

```swift
// Khởi tạo chuyển động theo tên hoặc enum:
stickerNode.motionEffect = StickerMotionEffectFactory.create(named: "windSway")

// Khởi tạo hiệu ứng tap theo tên hoặc enum:
stickerNode.tapEffects = [
    StickerTapEffectFactory.create(named: "sunRadiance"),
    StickerTapEffectFactory.create(named: "sparkleBurst")
]
```

---

## 4. Quy Chuẩn Cấu Hình Dữ Liệu JSON Cho Sticker (`stickers_data.json Convention`)

File dữ liệu cấu hình chuẩn: [stickers_data.json](file:///Users/vuongquanghuy/code/prj_ios/terrariumidle_ios/terrariumidle_ios/Apps/Data/Items/stickers_data.json).

### 4.1. Cấu Trúc Schema Chi Tiết của Từng Phần Tử Sticker

Mỗi phần tử trong file `stickers_data.json` là một đối tượng JSON đại diện cho một Sticker / Vật phẩm trang trí với đầy đủ các thuộc tính:

```json
{
    "id": "sticker1",
    "name": "Sunshine doll",
    "description": "Búp bê cầu nắng treo đung đưa theo gió, mang lại ngày nắng đẹp trời.",
    "image": "sticker1-1@4.167x",
    "priceStore": 30000,
    "priceOxygen": 25000,
    "currencyUnit": "oxygen",
    "type": "sticker",
    "effect": "",
    "itemTypeAttribute": "hanging,front",
    "levelUnlock": 50,
    "effectDescription": "Mặt trời tỏa sáng & đung đưa theo gió",
    "music": "",
    "musicDescription": "",
    "effectLandscape": "",
    "effectLandscapeDescription": "",
    "effectSfx": "sfx4",
    "effectSfxDescription": "Tiếng gió"
}
```

### 4.2. Bảng Diễn Giải Chi Tiết Các Trường Dữ Liệu (`Data Fields`)

| Trường Dữ Liệu | Kiểu Dữ Liệu | Bắt Buộc | Ý Nghĩa & Vai Trò Trong Game |
| :--- | :--- | :--- | :--- |
| `id` | `String` | **Có** | Mã định danh duy nhất (ví dụ `"sticker1"`, `"sticker2"`). Khớp với ID đăng ký trong `StickerAvailability.supportedStickerIds` và `StickerFactory.createSticker(id:)`. |
| `name` | `String` | **Có** | Tên hiển thị của sticker trên giao diện Cửa hàng và Kệ cây (ví dụ `"Sunshine doll"`, `"Tượng người lùn hoa hướng dương"`). |
| `description` | `String` | **Có** | Đoạn văn bản mô tả nguồn gốc, ý nghĩa của sticker hiển thị trong Bottom Sheet chi tiết. |
| `image` | `String` | **Có** | Tên asset ảnh đại diện trong `Assets.xcassets` (ví dụ `"sticker1-1@4.167x"`) hoặc link ảnh tĩnh dùng làm thumbnail preview. |
| `priceStore` | `Int` | **Có** | Giá mua bằng tiền xu/vàng trong Store. |
| `priceOxygen` | `Int` | **Có** | Giá mua bằng điểm Oxy trong Store. |
| `currencyUnit` | `String` | **Có** | Đơn vị tiền tệ chính để giao dịch (`"oxygen"` hoặc `"coin"`). |
| `type` | `String` | **Có** | Phân loại danh mục vật phẩm. Luôn đặt là `"sticker"`. |
| `itemTypeAttribute` | `String` | **Có** | **CỜ THUỘC TÍNH VỊ TRÍ & PHÂN LỚP LAYER CỰC KỲ QUAN TRỌNG** (xem chi tiết mục 4.3). Hỗ trợ ghép nhiều cờ: `"hanging"`, `"hanging,front"`, `"none"`, `"front"`. |
| `levelUnlock` | `Int` | **Có** | Cấp độ tài khoản yêu cầu để mở khóa mua vật phẩm trong Store (ví dụ `50`). |
| `effect` | `String` | Không | ID(s) hiệu ứng thời tiết/overlay toàn cảnh mở khóa kèm theo (nếu có, để trống `""` nếu không mở khóa overlay). |
| `effectDescription` | `String` | Không | Tóm tắt hiệu ứng thị giác hiển thị trên thẻ vật phẩm (ví dụ `"Mặt trời tỏa sáng & đung đưa theo gió"`). |
| `music` | `String` | Không | ID bài hát BGM mở khóa kèm theo (nếu có, ví dụ `"m1"`). |
| `musicDescription` | `String` | Không | Tên bài hát BGM mở khóa kèm theo. |
| `effectLandscape` | `String` | Không | ID phong cảnh nền ban công mở khóa kèm theo (ví dụ `"landscape1"`). |
| `effectLandscapeDescription` | `String` | Không | Tên phong cảnh nền mở khóa kèm theo. |
| `effectSfx` | `String` | Không | ID âm thanh SFX môi trường mở khóa kèm theo (ví dụ `"sfx4"`). |
| `effectSfxDescription` | `String` | Không | Mô tả âm thanh SFX môi trường (ví dụ `"Tiếng gió"`, `"Tiếng chim"`). |

---

### 4.3. Quy Chuẩn Cờ Thuộc Tính Phân Tầng Vị Trí (`itemTypeAttribute`)

Trường `itemTypeAttribute` quyết định trực tiếp cách hệ thống SwiftUI và SpriteKit render sticker trên tầng kệ:

1. **`"hanging"` (Sticker Treo)**:
   - Dùng cho các sticker buông rủ từ đỉnh xuống (chuông gió, búp bê cầu nắng, lồng chim).
   - **Vị trí trên kệ (`PlantItemView.swift`)**: Neo chặt đỉnh kệ với `alignment: .top`.
   - **SpriteKit Anchor Point**: Gốc neo nằm ở đỉnh móc treo `anchorPoint = (0.5, 1.0)`.
   - **Chiều cao hiển thị**: Tính theo tỷ lệ an toàn của kệ:
     ```swift
     let stickerH = min(slotHeight * 0.58, itemWidth * 1.15)
     ```

2. **`"hanging,front"` (Sticker Treo Phân Lớp Đa Thành Phần - Điển hình: `sticker1`)**:
   - Vừa là sticker treo (`isHanging = true`), vừa có các chi tiết ruy băng hoặc cành lá vươn ra mặt trước (`isInFront = true`).
   - Ghép nối đa lớp: Dây treo nằm phía sau (`z = 5`), thân búp bê ở giữa (`z = 10`), ruy băng nơ nằm đè phía trước (`z = 20`).

3. **`"none"` (Sticker Để Bàn / Đặt Kệ - Điển hình: `sticker2`, `sticker3`, `sticker4`)**:
   - Dùng cho các tượng trang trí để đứng trên mặt thanh gỗ của tầng kệ (tượng người lùn hoa hướng dương, tượng cà rốt, chậu mini).
   - **Vị trí trên kệ (`PlantItemView.swift`)**: Neo đáy kệ với `alignment: .bottom`.
   - **SpriteKit Anchor Point**: Gốc neo nằm ở chính giữa đáy `anchorPoint = (0.5, 0.0)`.
   - **Chiều cao hiển thị**: `155pt` tiêu chuẩn.

4. **`"front"` (Sticker Phủ Mặt Trước)**:
   - Dùng cho các vật phẩm dán mép trước của thanh kệ gỗ.

---

### 4.4. Phân Định Rõ Ràng Giữa Dữ Liệu JSON và Code SpriteKit Node

Tuân thủ nghiêm ngặt nguyên tắc thiết kế Data-Driven:

- **Trong file JSON (`stickers_data.json`)**:
  * Chỉ quản lý thông tin danh mục, giá cả, mở khóa cấp độ, phân loại kệ (`itemTypeAttribute`), mô tả và âm thanh SFX môi trường (`effectSfx`).
  * **TUYỆT ĐỐI KHÔNG** đưa các hiệu ứng hạt cục bộ (Mặt trời tỏa sáng, sao bung lượn, hào quang vàng) vào trường `effect` của JSON. Trường `effect` trong JSON chỉ dùng cho các overlay toàn màn hình (lá rơi, mưa rơi...).

- **Trong Node SpriteKit (`Sticker1Node.swift`, v.v.)**:
  * Trực tiếp quản lý và kích hoạt các hiệu ứng chuyển động vật lý (`motionEffect: StickerMotionEffect`) và hiệu ứng hạt bùng nổ khi chạm (`tapEffects: [StickerTapEffect]`).
  * Độc lập, đóng gói hoàn chỉnh, dễ dàng cắm ghép hoặc thay đổi kiểu hiệu ứng mà không làm xáo trộn dữ liệu trò chơi.

---

### 4.5. Mô Hình Ghép Nối Đa Thành Phần (Multi-Component Assembled Sticker) từ SVG

Đối với các Sticker động phức tạp như `sticker1` (Sunshine doll):
- **Bóc tách từ file vector gốc [sticker1.svg](file:///Users/vuongquanghuy/code/prj_ios/terrariumidle_ios/terrariumidle_ios/Resources/SVGSticker/sticker1.svg)**:
  * `sticker1-1`: Thumbnail tổng hợp nguyên mẫu (Avatar đại diện tĩnh).
  * `sticker1-2`: Dây treo (`ropeNode`, z = 5).
  * `sticker1-3`: Thân và đầu búp bê cầu nắng (`dollNode`, z = 10, anchor tại nút thắt dây).
  * `sticker1-4`: Ruy băng bên trái (`ribbonLeftNode`, z = 20, anchor tại điểm thắt nơ).
  * `sticker1-5`: Ruy băng bên phải (`ribbonRightNode`, z = 20, anchor tại điểm thắt nơ).
- **Thiết kế trực quan trong Scene Editor**:
  * File `Sticker1Scene.sks` (canvas $122 \times 375$, `anchorPoint = (0.5, 1.0)`).
  * Chuyển động đa tầng: Dây treo đu đưa con lắc quanh đỉnh móc treo, thân búp bê đung đưa nhịp lớn theo gió, 2 dải ruy băng phất phơ nhịp riêng bằng `SKAction.rotate` tạo cảm giác chuyển động vật lý chân thực.

---

### 4.6. Quy Chuẩn Vùng Đệm Chống Cắt Biên (Anti-Clipping Buffer) và Hiệu Ứng Mặt Trời

Nhằm giải quyết triệt để lỗi hiệu ứng mặt trời và sao bị cắt ngang khung viền Metal GPU:
1. **SpriteKitStickerView Buffer**:
   ```swift
   public var overflowRatioX: CGFloat = 0.22 // Mở rộng 22% chiều rộng render
   public var overflowRatioY: CGFloat = 0.15 // Mở rộng 15% chiều cao render
   ```
2. **Thuật toán định vị Mặt Trời (`SunRadianceEffect`)**:
   - Tâm mặt trời tự động lấy theo tọa độ gương mặt búp bê:
     ```swift
     let dollOrigin = doll.position
     let dollH = doll.size.height
     let sunCenterY = dollOrigin.y - dollH * 0.16
     ```
   - Khống chế bán kính hào quang trong vùng an toàn:
     ```swift
     let safeRadius = min(sceneW * 0.34, sceneH * 0.22, 46.0)
     ```
   - Đảm bảo toàn bộ vầng hào quang, 12 tia nắng xoay tròn và các ngôi sao bung lượn luôn nằm trọn vẹn trong vùng hiển thị của ô kệ.

---

### 4.7. Bảng Tra Cứu Toàn Bộ Sticker Trong Game (`stickers_data.json`)

| ID | Tên Sticker | Asset Preview | Loại (`itemTypeAttribute`) | Âm Thanh SFX | Mô Tả Hiệu Ứng |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`sticker1`** | Sunshine doll | `sticker1-1@4.167x` | `"hanging,front"` (Treo phân lớp) | `sfx4` (Tiếng gió) | Mặt trời tỏa sáng & đung đưa theo gió |
| **`sticker2`** | Tượng người lùn hoa hướng dương | `https://i.imgur.com/FVRkr9L.png` | `"none"` (Để bàn) | `sfx1` (Tiếng chim) | Nén nảy lò xo & chùm sao lấp lánh |
| **`sticker3`** | Tượng người lùn cà rốt | `https://i.imgur.com/qycI2xZ.png` | `"none"` (Để bàn) | `sfx2` (Tiếng ếch) | Nén nảy lò xo & chùm sao lấp lánh |
| **`sticker4`** | Tượng người lùn hoa cúc | `https://i.imgur.com/JRiiJn8.png` | `"none"` (Để bàn) | `sfx3` (Tiếng mưa) | Nén nảy lò xo & chùm sao lấp lánh |

---

## 5. Quy Trình Thêm Sticker Mới Từng Bước (Step-by-Step Guide)

Khi tạo một Sticker mới (ví dụ `stickerX`):

1. **Chuẩn bị Asset**:
   - Đặt file thiết kế vector tại `terrariumidle_ios/Resources/SVGSticker/stickerX.svg`.
   - Xuất các asset thành phần vào `Assets.xcassets/Stickers/stickerX/` (`stickerX-1` làm thumbnail, `stickerX-2` trở đi làm layer chuyển động).
2. **Khai báo trong `stickers_data.json`**:
   - Thêm bản ghi JSON với đầy đủ thông tin: `id`, `name`, `image`, `itemTypeAttribute`, `levelUnlock`, `effectSfx`.
3. **Tạo Bộ File SpriteKit (`Plant1 / Sticker1` làm chuẩn)**:
   - Tạo `StickerXScene.sks` trực quan trong Xcode Scene Editor.
   - Tạo `StickerXNode.swift` kế thừa `SKNode` và tuân thủ `StickerInteractiveNode`. Gán `motionEffect` và `tapEffects`.
   - Tạo `StickerXView.swift` xem trước độc lập kèm `#Preview`.
4. **Đăng ký vào hệ thống**:
   - Thêm `"stickerX"` vào `StickerAvailability.supportedStickerIds` trong `SpriteKitStickerView.swift`.
   - Thêm case `"stickerX"` vào `StickerFactory.swift`.
5. **Kiểm tra**:
   - Chạy `swiftc -typecheck` kiểm tra biên dịch không lỗi.
