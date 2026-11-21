# Hệ Thống Hiệu Ứng Sticker (Sticker Tap & Motion Effects System)

Khi người chơi chạm (tap/click) vào Sticker hoặc vật trang trí trong Terrarium Idle iOS, phản hồi tương tác được điều phối qua **hai hệ thống hiệu ứng độc lập và song song**, phân tách thành 2 thư mục chuyên biệt:

1. **`StickerEffects/Motion/` (Hiệu ứng Chuyển động Vật lý - `StickerMotionEffect`)**: Điều khiển đung đưa nhàn rỗi theo gió (Idle Wind Sway), con lắc đu đưa (Pendulum Swing), hoặc nhún nảy đàn hồi (Squash & Stretch spring bounce) lên toàn bộ khung treo, thân sticker và ruy băng.
2. **`StickerEffects/Tap/` (Hiệu ứng Thị giác Dạng Hạt / Ánh Sáng - `StickerTapEffect`)**: Sinh các chùm ánh sáng mặt trời rạng rỡ (Sun Radiance), chùm sao vàng lấp lánh (Sparkle Star Burst), cầu vồng sau mưa (Rainbow Glow) hoặc hào quang kim sắc (Golden Aura) bùng nổ xung quanh sticker tại `zPosition = 200`.

```
StickerEffects/
├── Motion/                              # Hiệu ứng chuyển động vật lý
│   ├── StickerMotionEffect.swift        # Protocol, Context, Enum, Factory
│   ├── WindSwayStickerMotionEffect.swift# Đung đưa theo gió tự nhiên + tăng nhịp khi tap (Sticker1)
│   ├── ElasticSwingStickerMotionEffect.swift # Con lắc đàn hồi tần số nhanh
│   ├── StandardBounceStickerMotionEffect.swift # Nảy lò xo cho sticker để bàn/dán tường
│   └── SubtleFlutterStickerMotionEffect.swift  # Rung rinh bay bổng vi mô
├── Tap/                                 # Hiệu ứng thị giác dạng hạt / ánh sáng
│   ├── StickerTapEffect.swift           # Protocol, Enum, Factory
│   ├── SunRadianceEffect.swift          # Mặt trời rực rỡ tỏa sáng kèm 12 tia nắng xoay & sao bụi
│   ├── SparkleBurstStickerEffect.swift  # Chùm sao vàng & bạc bung tỏa
│   ├── RainbowGlowEffect.swift          # Vệt cầu vồng tươi sáng sau mưa
│   └── GoldenAuraEffect.swift           # Vòng hào quang vàng kim
└── STICKER_EFFECTS_README.md            # Tài liệu kiến trúc & hướng dẫn
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

---

## 2. Hệ Thống Hiệu Ứng Thị Giác Khi Chạm (`StickerTapEffect`)

Mọi Sticker quản lý danh sách hiệu ứng hạt/ánh sáng qua thuộc tính:
```swift
public var tapEffects: [StickerTapEffect] = [SunRadianceEffect(), SparkleBurstStickerEffect()]
```

### 2.1. Danh Mục Các Hiệu Ứng Tap (`Tap Effects`)

| Tên Hiệu Ứng | Lớp Triển Khai (`Class`) | Định Danh Type | Phù Hợp Cho | Đặc Điểm Thị Giác |
| :--- | :--- | :--- | :--- | :--- |
| **Mặt trời tỏa sáng** | `SunRadianceEffect` | `sunRadiance` | Búp bê cầu nắng (**Sticker1**) | Vầng hào quang bung tỏa (`halo`), mặt trời vàng mặt cười tươi rói, 12 tia nắng dài ngắn xoay tròn, cùng 14 ngôi sao nắng bung lượn lấp lánh. |
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
