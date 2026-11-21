# Hệ Thống Hiệu Ứng Chạm Cây (Plant Tap & Motion Effects System)

Khi người chơi chạm (tap/click) vào cây trong Terrarium Idle iOS, phản hồi tương tác được điều phối qua **hai hệ thống hiệu ứng độc lập và song song**, được phân tách thành 2 thư mục chuyên biệt:
1. **`PlantEffects/Motion/` (Hiệu ứng Chuyển động Vật lý - `PlantMotionEffect`)**: Điều khiển nhún nảy cành lá, gió lay uốn lượn, hoặc dây leo rủ buông đung đưa theo các giai đoạn sinh trưởng (Hạt giống, Cây con, Trưởng thành).
2. **`PlantEffects/Tap/` (Hiệu ứng Thị giác Dạng Hạt - `PlantTapEffect`)**: Sinh các chùm bọt khí Oxy 3D căng bóng (`OxygenBubblesEffect`), bụi phấn hoa vàng lấp lánh (`SparklePollenEffect`), hoặc cánh hoa rụng (`FloatingPetalsEffect`) tại `zPosition = 200`.

```
PlantEffects/
├── Motion/                              # Thư mục chuyên trách hiệu ứng chuyển động vật lý
│   ├── PlantMotionEffect.swift          # Protocol, Context, Enum, Factory
│   ├── StandardPlantBounceMotionEffect.swift # Bản gốc: Nén nảy Squash & Stretch + Gợn sóng qua phiến lá
│   ├── WindSwayMotionEffect.swift       # Bản mới: Gió lay đu đưa mềm mại (Thân chao nghiêng, lá uốn lượn)
│   ├── CascadingVineMotionEffect.swift  # Bản mới: Dây leo buông rủ đung đưa chuỗi sóng (Chậu treo)
│   └── ElasticPulseMotionEffect.swift   # Bản mới: Nhún nảy đàn hồi tần số nhanh (Sen đá/xương rồng)
├── Tap/                                 # Thư mục chuyên trách hiệu ứng hạt thị giác
│   ├── PlantTapEffect.swift             # Protocol, Enum, Factory
│   ├── OxygenBubblesEffect.swift        # Bọt khí Oxy 3D (Emerald, Deep Ocean, Golden Sun, Floral Pink)
│   ├── SparklePollenEffect.swift        # Bụi phấn hoa lấp lánh
│   └── FloatingPetalsEffect.swift       # Cánh hoa rơi rụng bồng bềnh
└── PLANT_EFFECTS_README.md              # Tài liệu kiến trúc & hướng dẫn tra cứu
```

---

## 1. Hệ Thống Hiệu Ứng Chuyển Động Cây (`PlantMotionEffect`)

Mọi loài cây (`Plant1Node` $\rightarrow$ `Plant18Node`) đều quản lý hiệu ứng chuyển động qua thuộc tính:
```swift
public var motionEffect: PlantMotionEffect = ...
```

### 1.1. Danh Mục Các Hiệu Ứng Chuyển Động (`Motion Effects`)

| Tên Hiệu Ứng | Lớp Triển Khai (`Class`) | Định Danh Type | Phù Hợp Cho | Đặc Điểm Chuyển Động |
| :--- | :--- | :--- | :--- | :--- |
| **Nén nảy tiêu chuẩn (Bản gốc)** | `StandardPlantBounceMotionEffect` | `standardBounce` | Cây để bàn đứng thẳng (Mặc định: **Plant1, 3, 6, 9, 12**) | Squash & Stretch lò xo đàn hồi cả cây + Gợn sóng xao động lan truyền qua từng phiến lá + nảy mầm/hạt. |
| **Gió lay đu đưa (Bản mới)** | `WindSwayMotionEffect` | `windSway` | Cây tán lá rộng, cau, dương xỉ (Mặc định: **Plant2, 4, 7, 8, 10, 16**) | Thân cây chao nghiêng đón gió (`rotate: 0.048 rad`), từng phiến lá uốn cong nhịp nhàng đón gió theo chuỗi sóng mượt mà. |
| **Dây leo rủ (Bản mới)** | `CascadingVineMotionEffect` | `cascadingVine` | Cây dây leo, chậu treo buông rủ (Mặc định: **Plant11, 13, 14, 15, 17, 18**) | Từng nhánh lá/chuỗi hạt buông thõng đung đưa hình sin nối đuôi nhau từ miệng chậu xuống ngọn. |
| **Nhún nảy đàn hồi (Bản mới)** | `ElasticPulseMotionEffect` | `elasticPulse` | Sen đá, xương rồng, mọng nước (Mặc định: **Plant5**) | Nhịp co giãn nảy nhanh (Micro-pulse) chắc nịch, tạo cảm giác mọng nước đầy đặn. |

### 1.2. Protocol `PlantMotionEffect` & `PlantMotionContext`

```swift
public protocol PlantMotionEffect: AnyObject {
    var name: String { get }
    func apply(context: PlantMotionContext)
}
```

Ngữ cảnh `PlantMotionContext` đóng gói đầy đủ:
- `plantNode`: Node cây gốc (`self`).
- `plantRootNode`: Node chứa bộ khung hiển thị cây.
- `seedNode`: Node hạt giống (giai đoạn Level 1).
- `sproutNode`: Node mầm cây con (giai đoạn Level 2).
- `matureNode`: Node cây trưởng thành (giai đoạn Level 3+).
- `leafNodes`: Mảng các phiến lá trên cây (`leaf_X`).
- `baseScale`: Tỉ lệ scale cơ sở của cây.
- `level`: Cấp độ sinh trưởng hiện tại ($1, 2, 3\dots$).
- `initialSeedPosition`, `initialSproutPosition`: Tọa độ gốc chống trôi khi tap liên tục.
- `containerSize`: Kích thước khung chứa cây.
- `onComplete`: Callback khi chuỗi chuyển động hoàn tất.

### 1.3. Cách Chỉnh Sửa / Đổi Kiểu Chuyển Động Giữa Các Cây

Để thay đổi kiểu rung lắc hoặc uốn lượn của cây, bạn chỉ cần sửa **1 dòng code duy nhất** trong file Node của loài cây đó:

```swift
// Ví dụ 1: Muốn Plant1 (Lưỡi hổ) chuyển từ nảy lò xo sang đu đưa theo gió:
// Trong Plant1Node.swift:
public var motionEffect: PlantMotionEffect = WindSwayMotionEffect()

// Ví dụ 2: Tinh chỉnh độ nghiêng và độ uốn lá khi đón gió của Plant2 (Trầu bà):
public var motionEffect: PlantMotionEffect = WindSwayMotionEffect(swayAngle: 0.06, leafBendAngle: 0.16)

// Ví dụ 3: Muốn Plant15 (Chuỗi tim) dùng hiệu ứng dây leo rủ buông:
public var motionEffect: PlantMotionEffect = CascadingVineMotionEffect(waveAngle: 0.11)
```

---

## 2. Hệ Thống Hiệu Ứng Bọt Khí Oxy & Dạng Hạt (`PlantTapEffect`)

Mỗi loài cây quản lý danh sách hiệu ứng hạt qua mảng:
```swift
public var tapEffects: [PlantTapEffect] = [OxygenBubblesEffect(theme: .emerald)]
```

### 2.1. Cấu Tạo Bọt Khí Oxy 3D (`OxygenBubblesEffect`)

```
        ┌─────────────┐
        │  * (White)  │  <- Điểm sáng phản chiếu góc Tây-Bắc (Highlight, 30% bán kính, alpha 0.85)
        │             │
        │             │  <- Thân bọt bán trong suốt (Theme Fill Color, alpha 0.85)
        └─────────────┘
          (Viền trắng mỏng 1.0pt, alpha 0.75)
```

- **Level 1 (Hạt giống)**: $1 \dots 2$ bọt nhỏ ($1.8 \dots 3.0\text{pt}$), bay $18 \dots 35\text{pt}$.
- **Level 2 (Cây con)**: $3 \dots 4$ bọt vừa ($2.2 \dots 3.8\text{pt}$), bay $25 \dots 45\text{pt}$.
- **Level 3+ (Trưởng thành)**: $8 \dots 12$ bọt dồi dào ($3.5 \dots 7.5\text{pt}$), bay $60 \dots 115\text{pt}$, giãn nở thêm $+30\%$.

### 2.2. Các Bộ Theme Màu Sắc Bọt Khí

| Theme | Mã Màu Fill | Phù Hợp Cho Loài Cây |
| :--- | :--- | :--- |
| **`emerald`** (Mặc định) | `rgba(89, 235, 166, 0.85)` | Đa số các loài cây xanh lá (`Plant1` Lưỡi hổ, `Plant2` Trầu bà, `Plant3` Begonia...) |
| **`deepOcean`** | `rgba(64, 209, 242, 0.85)` | Cây mọng nước, cây dây leo buông rủ (`Plant15` Chuỗi tim, `Plant11`...) |
| **`goldenSun`** | `rgba(255, 224, 97, 0.88)` | Cây có lá vàng, hoa hướng dương hoặc cây nhiệt đới ánh sáng |
| **`floralPink`** | `rgba(255, 173, 209, 0.88)` | Cây nở hoa hồng, sen đá viền hồng, phong lan |

---

## 3. Bảng Tra Cứu Cấu Hình Toàn Bộ 18 Loài Cây (Plant1 -> Plant18)

| Loài Cây | Tên Khoa Học / Tiếng Việt | Hiệu Ứng Chuyển Động (`motionEffect`) | Hiệu Ứng Thị Giác (`tapEffects`) |
| :--- | :--- | :--- | :--- |
| **Plant1** | Lưỡi hổ (*Sansevieria trifasciata*) | `StandardPlantBounceMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant2** | Trầu bà lá xẻ (*Monstera deliciosa*) | `WindSwayMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant3** | Thu hải đường (*Begonia rex*) | `StandardPlantBounceMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant4** | Cỏ gương (*Pilea peperomioides*) | `WindSwayMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant5** | Sen đá móng rồng (*Haworthia fasciata*) | `ElasticPulseMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant6** | Cẩm cù trái tim (*Hoya kerrii*) | `StandardPlantBounceMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant7** | Cau tiểu trâm (*Chamaedorea elegans*) | `WindSwayMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant8** | Dương xỉ (*Nephrolepis exaltata*) | `WindSwayMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant9** | Bàng Singapore (*Ficus lyrata*) | `StandardPlantBounceMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant10** | Trúc bách hợp (*Dracaena reflexa*) | `WindSwayMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant11** | Cây dây leo (*Climbing Vine*) | `CascadingVineMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant12** | Cẩm nhung (*Fittonia albivenis*) | `StandardPlantBounceMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant13** | Trầu bà leo (*Philodendron hederaceum*) | `CascadingVineMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant14** | Trầu bà tim (*Heartleaf philodendron*) | `CascadingVineMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant15** | Chuỗi tim (*Ceropegia woodii*) | `CascadingVineMotionEffect()` | `[OxygenBubblesEffect(theme: .deepOcean)]` |
| **Plant16** | Cỏ lan chi (*Chlorophytum comosum*) | `WindSwayMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant17** | Cúc tần Ấn Độ (*Vernonia elliptica*) | `CascadingVineMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |
| **Plant18** | Chuỗi ngọc (*Curio rowleyanus*) | `CascadingVineMotionEffect()` | `[OxygenBubblesEffect(theme: .emerald)]` |

---

## 4. Hướng Dẫn Thêm Hiệu Ứng Mới Cho Cây

### 4.1. Thêm Hiệu Ứng Chuyển Động Mới (Motion Effect)
1. Tạo file mới `[TenHieuUng]MotionEffect.swift` trong thư mục `PlantEffects/Motion/`.
2. Cho class kế thừa protocol `PlantMotionEffect`:
   ```swift
   public final class MyPlantMotionEffect: PlantMotionEffect {
       public var name: String { "MyPlantMotion" }

       public func apply(context: PlantMotionContext) {
           let root = context.plantRootNode
           root.removeAction(forKey: "customPlantMotion")
           let action = SKAction.sequence([
               SKAction.rotate(byAngle: 0.05, duration: 0.15),
               SKAction.rotate(byAngle: -0.05, duration: 0.15),
               SKAction.run { context.onComplete?() }
           ])
           root.run(action, withKey: "customPlantMotion")
       }
   }
   ```
3. Gán trực tiếp vào bất kỳ cây nào qua `public var motionEffect: PlantMotionEffect = MyPlantMotionEffect()`.
4. (Tuỳ chọn) Khai báo case trong `PlantMotionEffectType` và `PlantMotionEffectFactory`.

### 4.2. Thêm Hiệu Ứng Hạt Mới (Tap Particle Effect)
1. Tạo file mới `[TenHieuUng]Effect.swift` trong thư mục `PlantEffects/Tap/`.
2. Cho class kế thừa protocol `PlantTapEffect` (`trigger(on:containerSize:level:leaves:)`).
3. Gán trực tiếp vào mảng `tapEffects` trong `PlantXNode.swift`.
