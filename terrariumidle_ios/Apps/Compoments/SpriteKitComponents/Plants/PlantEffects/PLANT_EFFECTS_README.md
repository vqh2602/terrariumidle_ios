# Hệ Thống Hiệu Ứng Bọt Khí Oxy & Chạm Cây (Plant Tap Oxygen Effects)

Hệ thống hiệu ứng thị giác dạng bọt khí Oxy 3D và các hạt sinh học (Bio-particles, Pollen, Petals) được kích hoạt mỗi khi người chơi chạm (tap/click) vào cây trong Terrarium Idle iOS.

---

## 1. Cấu Tạo Hiệu Ứng Bọt Khí Oxy 3D (`OxygenBubblesEffect`)

Bọt khí Oxy được thiết kế tỉ mỉ tạo cảm giác căng bóng, trong suốt 3D như nổi trên mặt nước/không khí:

```
        ┌─────────────┐
        │  * (White)  │  <- Điểm sáng phản chiếu góc Tây-Bắc (Highlight, 30% bán kính, alpha 0.85)
        │             │
        │             │  <- Thân bọt bán trong suốt (Theme Fill Color, alpha 0.85)
        └─────────────┘
          (Viền trắng mỏng 1.0pt, alpha 0.75)
```

### 1.1. Phân Bổ Theo Cấp Độ Sinh Trưởng (Levels)

| Giai Đoạn | Cấp Độ | Số Lượng Bọt | Bán Kính (`radius`) | Điểm Xuất Phát | Quãng Đường Bay |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Hạt giống** | Level 1 | **1 - 2** bọt nhỏ | $1.8 \dots 3.0\text{pt}$ | Thoát ra sát đáy hạt giống | $18 \dots 35\text{pt}$ |
| **Cây con** | Level 2 | **3 - 4** bọt vừa | $2.2 \dots 3.8\text{pt}$ | Thoát ra từ 2 mầm lá non | $25 \dots 45\text{pt}$ |
| **Trưởng thành** | Level 3+ | **8 - 12** bọt dồi dào | $3.5 \dots 7.5\text{pt}$ | Thoát ra từ từng phiến lá hoặc rải đều tán cây | $60 \dots 115\text{pt}$ |

### 1.2. Động Lực Học Bay (Motion Physics)
- **Quỹ đạo bay**: Bay uốn lượn hình sin với độ trôi dạt ngang (`driftX: -22 ... +22pt`).
- **Độ giãn nở (Scale-Up)**: Tăng kích thước thêm **$30\%$** (`scaleUp: 1.30`) trong quá trình bay lên tạo cảm giác bọt khí vỡ tan trong không khí.
- **Thời gian bay**: $0.85 \dots 1.55$ giây kết hợp `fadeIn` ($0.12$s) và `fadeOut` mờ dần ở $55\%$ cuối hành trình.

---

## 2. Quy Chuẩn Kỹ Thuật Bắt Buộc (Mandatory Rules)

> [!IMPORTANT]
> 1. **Gắn trực tiếp vào Node cây cha (`plantNode.addChild(bubble)`)**:
>    Tuyệt đối **KHÔNG** add vào `plantRootNode` vì `plantRootNode` thường bị `setScale(baseScale)` thu nhỏ còn $0.2 \dots 0.25$, sẽ khiến bọt khí bị teo nhỏ như hạt bụi.
> 2. **`zPosition = 200`**:
>    Bọt khí phải luôn bay nổi trên thành chậu ($z = 50$), cành lá ($z = 70$) và dây treo ($z = 100$).
> 3. **Chuyển đổi không gian toạ độ khi sinh bọt từ lá**:
>    Dùng `leaf.parent?.convert(leaf.position, to: plantNode)` để đảm bảo vị trí sinh bọt luôn chính xác dù phiến lá nằm trong cây phân nhánh hay scene phức tạp.

---

## 3. Các Bộ Theme Màu Sắc Bọt Khí

| Theme | Mã Màu Fill | Phù Hợp Cho Loài Cây |
| :--- | :--- | :--- |
| **`emerald`** (Mặc định) | `rgba(89, 235, 166, 0.85)` | Đa số các loài cây xanh lá (`Plant1` Lưỡi hổ, `Plant2` Trầu bà, `Plant3` Begonia...) |
| **`deepOcean`** | `rgba(64, 209, 242, 0.85)` | Cây mọng nước, cây dây leo buông rủ (`Plant15` Chuỗi tim, `Plant11`...) |
| **`goldenSun`** | `rgba(255, 224, 97, 0.88)` | Cây có lá vàng, hoa hướng dương hoặc cây nhiệt đới ánh sáng |
| **`floralPink`** | `rgba(255, 173, 209, 0.88)` | Cây nở hoa hồng, sen đá viền hồng, phong lan |

---

## 4. Danh Sách Hiệu Ứng Cây Khác

- **`SparklePollenEffect`**: Bụi phấn hoa lấp lánh màu vàng kim nhấp nháy tỏa ra từ đầu cành ngọn lá.
- **`FloatingPetalsEffect`**: Cánh hoa / lá non rụng bay lượn bồng bềnh hình sin và xoay nhẹ nhàng.

---

## 5. Kiến Trúc Lập Trình & Quản Lý Hiệu Ứng Theo Danh Sách

Tương tự như Chậu (`PotTapEffect`), mọi loài Cây đều quản lý hiệu ứng qua danh sách `tapEffects: [PlantTapEffect]`:

```swift
// Trong PlantXNode.swift:
public var tapEffects: [PlantTapEffect] = [
    OxygenBubblesEffect(theme: .emerald)
]

public func playTapAnimation() {
    // 1. Rung lắc nhấp nhô cành lá
    playLeafBounce()

    // 2. Kích hoạt toàn bộ danh sách hiệu ứng tap đã đăng ký
    for effect in tapEffects {
        effect.trigger(on: self, containerSize: containerSize, level: currentLevel, leaves: leafNodes)
    }
}
```

### Tuỳ Biến Động Qua Factory
```swift
// Gán nhiều hiệu ứng cùng lúc (Vừa nhả bọt Oxy vừa tung bụi phấn hoa)
plantNode.tapEffects = [
    OxygenBubblesEffect(theme: .emerald),
    SparklePollenEffect()
]
```

---

## 6. Quy Chuẩn Cấu Trúc JSON Mới (`plants_data.json`)

> [!IMPORTANT]
> - Các hiệu ứng hạt bọt khí Oxy 3D (`OxygenBubblesEffect`), phấn hoa, cánh hoa rụng khi chạm vào cây **BẮT BUỘC ĐƯỢC CẤU HÌNH TRONG CODE SWIFT NODE (`PlantXNode.swift`)**, **KHÔNG đưa vào JSON**.
> - File `plants_data.json` chỉ cấu hình âm thanh tap click và các item mở khóa khi trồng cây:

| Trường JSON | Kiểu Dữ Liệu | Mô Tả & Ý Nghĩa | Ví Dụ |
| :--- | :--- | :--- | :--- |
| `sound` | `String` | Âm thanh phát ra khi tap vào cây (mặc định `"tap"`) | `"tap"` |
| `effect` | `String` | Danh sách ID hiệu ứng overlay mở khóa khi trồng (phân tách bởi `,`) | `"overlay3"`, `"overlay4,overlay5"` |
| `effectDescription` | `String` | Mô tả hiệu ứng overlay | `"Cánh hoa oải hương"` |
| `music` | `String` | Danh sách ID bài hát BGM mở khóa (phân tách bởi `,`) | `"m0"`, `"m1"`, `"m0,m1"` |
| `musicDescription` | `String` | Mô tả bài hát BGM mở khóa | `"Relax"`, `"Một ngày thư thái"` |
| `effectLandscape` | `String` | Danh sách ID phong cảnh nền mở khóa (phân tách bởi `,`) | `"landscape1"`, `"landscape3"` |
| `effectLandscapeDescription` | `String` | Mô tả phong cảnh mở khóa | `"Ban công quang đãng"` |
| `effectSfx` | `String` | Danh sách ID âm thanh SFX mở khóa (phân tách bởi `,`) | `"sfx5"`, `"sfx6,sfx7"` |
| `effectSfxDescription` | `String` | Mô tả âm thanh SFX | `"Tiếng nước chảy"`, `"Tiếng bão"` |
