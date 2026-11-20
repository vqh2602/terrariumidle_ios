# Hệ Thống Hiệu Ứng Chạm Chậu Cây (Pot Tap Effects System)

Hệ thống hiệu ứng thị giác dạng hạt (Particles & Visual Accents) được kích hoạt đồng thời cùng hiệu ứng nảy vật lý (`PotBounceAnimator`) mỗi khi người chơi chạm (tap/click) vào chậu cây trong Terrarium Idle iOS.

---

## 1. Danh Mục Các Hiệu Ứng Hiện Có

| Tên Hiệu Ứng | Lớp Triển Khai (`Class`) | Định Danh JSON / Từ Khoá | Mô Tả Thị Giác & Màu Sắc |
| :--- | :--- | :--- | :--- |
| **Đá lấp lánh** | `SparkleBurstEffect` | `sparkleBurst`, `đá lấp lánh`, `lấp lánh` | Chùm sao 4 cánh nhọn phát sáng (Vàng hoàng yến & Hồng phấn), xoay 360° bung toả quanh chậu. |
| **Vệt ánh vàng** | `GoldGlintEffect` | `goldGlint`, `vàng`, `gold` | Các đốm ánh sáng vàng hoàng kim rực rỡ bay lượn dọc thân chậu. |
| **Bụi đá xám** | `StoneDustEffect` | `stoneDust`, `bụi đá`, `stone` | Chùm hạt bụi đá xám bạc mộc mạc bay bổng nhẹ nhàng. |
| **Trái tim bay** | `HeartBurstEffect` | `heartBurst`, `trái tim`, `heart` | Chùm trái tim hồng ngọc và đỏ san hô bay vút lên trời kèm nhịp thở phập phồng. |
| **Ánh gốm nung** | `ClayGlintEffect` | `clayGlint`, `gốm`, `caro`, `clay` | Đốm sáng màu đất nung sữa ấm áp phản chiếu bề mặt men gốm. |
| **Thạch anh lăng kính**| `QuartzBurstEffect` | `quartzBurst`, `thạch anh`, `quartz` | Tinh thể kim cương/lăng kính thạch anh tím & hồng xoay lấp lánh. |
| **Bụi đất mộc** | `EarthenParticlesEffect` | `earthenDust`, `đất sét`, `đất` | Hạt đất sét nung mộc mạc tỏa nhẹ ra xung quanh thân chậu. |

---

## 2. Quy Chuẩn Phân Tầng Chiều Sâu (Z-Index Hierarchy)

> [!IMPORTANT]
> Toàn bộ hiệu ứng tap của Chậu **BẮT BUỘC** phải có `zPosition >= 150` (chuẩn là `150` đến `200`).
> Tuyệt đối không để `zPosition <= 50` vì sẽ bị thân chậu (`potNode` z = 50) hoặc dây treo phía trước (`frontRopes` z = 100) che khuất.

Ma trận Z-Index trong chậu:
- `z = 0`: Dây treo phía sau chậu treo (`backRopes`)
- `z = 1`: Bóng đổ tiếp xúc mặt sàn (`shadowNode`)
- `z = 10`: Socket cắm cây (`plantMount`) & thân cây sau
- `z = 50`: Thân chậu & thành trước (`potNode` / `potBody`)
- `z = 70`: Cành lá rủ mặt trước miệng chậu
- `z = 100`: Dây treo phía trước chậu treo (`frontLeftRope`, `frontRightRope`)
- **`z = 150`**: **Các hạt hiệu ứng Tap của Chậu (`PotTapEffect`)** -> Luôn nổi bật trên mặt chậu và dây treo.
- `z = 200`: Bọt khí Oxy từ cây (`OxygenBubblesEffect`).

---

## 3. Kiến Trúc Lập Trình (Architecture)

### 3.1. Protocol `PotTapEffect`
Mọi hiệu ứng chậu đều kế thừa từ giao diện chuẩn:
```swift
public protocol PotTapEffect: AnyObject {
    var name: String { get }
    func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool)
}
```
- `potNode`: Sprite thân chậu (dùng để tính `potNode.frame` làm vùng xuất phát của hạt).
- `containerNode`: Node gốc của chậu (`potRootNode`). Hạt được add vào đây để không bị méo biến dạng khi `potNode` nảy co giãn đàn hồi.
- `isHanging`: Cờ báo chậu treo hay chậu để bàn (để đảo chiều bay nếu cần).

### 3.2. Cấu Hình Hiệu Ứng Tap Trong Node (Không Đưa Ra JSON)
> [!IMPORTANT]
> **Quy chuẩn phân định rõ giữa JSON và Node Code**:
> - Các hiệu ứng hạt lấp lánh, đốm sáng, nhịp tim hay bong bóng tap **BẮT BUỘC ĐƯỢC CẤU HÌNH TRỰC TIẾP TRONG FILE NODE** (`PotXNode.swift`) thông qua mảng `public var tapEffects: [PotTapEffect]`.
> - **TUYỆT ĐỐI KHÔNG** đưa các hiệu ứng tap cục bộ của chậu này vào trường `effect` trong JSON.
> - Trường `effect` trong file JSON chỉ dành riêng cho việc kích hoạt/mở khóa hiệu ứng phủ màn hình (**Overlay Effects** như `overlay1`, `overlay2` - lá rơi, hoa đào rơi).

Khởi tạo và gán trực tiếp trong từng Node Chậu:
```swift
// Trong Pot1Node.swift:
public var tapEffects: [PotTapEffect] = [SparkleBurstEffect()]

// Trong Pot4Node.swift:
public var tapEffects: [PotTapEffect] = [HeartBurstEffect()]

// Trong Pot6Node.swift:
public var tapEffects: [PotTapEffect] = [QuartzBurstEffect()]
```

### 3.3. Tích hợp trong từng Node Chậu (`PotXNode.swift`)
Mỗi Node chậu khai báo danh sách hiệu ứng có thể kích hoạt khi tap:
```swift
public var tapEffects: [PotTapEffect] = [SparkleBurstEffect()]

public func playTapAnimation() {
    guard let node = potNode else { return }
    // 1. Nảy đàn hồi vật lý
    PotBounceAnimator.applyBounce(to: node, containerSize: containerSize, isHanging: isHanging)
    // 2. Kích hoạt toàn bộ danh sách hiệu ứng tap
    for effect in tapEffects {
        effect.trigger(on: node, in: potRootNode, isHanging: isHanging)
    }
}
```

---

## 4. Quy Chuẩn Cấu Trúc JSON Mới (`pots_data.json` & `plants_data.json`)

Mỗi item trong JSON quản lý độc lập các trường mở khóa và mô tả:

| Trường JSON | Kiểu Dữ Liệu | Mục Đích & Ý Nghĩa | Ví Dụ |
| :--- | :--- | :--- | :--- |
| `effect` | `String` | Danh sách ID hiệu ứng overlay mở khóa khi trồng (phân tách bởi dấu phẩy `,`) | `"overlay1"`, `"overlay1,overlay2"`, `""` |
| `effectDescription` | `String` | Mô tả chi tiết hiệu ứng overlay | `"Lá rơi xanh ngọc"` |
| `sound` | `String` | Âm thanh phát ra khi tap vào (chỉ áp dụng với plant, mặc định `"tap"`) | `"tap"` |
| `music` | `String` | Danh sách ID bài hát BGM mở khóa (phân tách bởi `,`) | `"m0"`, `"m0,m1"`, `"m3"` |
| `musicDescription` | `String` | Mô tả bài hát nhạc nền mở khóa | `"Mong một ngày mưa"`, `"Relax"` |
| `effectLandscape` | `String` | Danh sách ID phong cảnh nền mở khóa (phân tách bởi `,`) | `"landscape5"` |
| `effectLandscapeDescription` | `String` | Mô tả phong cảnh mở khóa | `"Đêm muộn trời sao"` |
| `effectSfx` | `String` | Danh sách ID âm thanh SFX mở khóa (phân tách bởi `,`) | `"sfx5"`, `"sfx1,sfx2"` |
| `effectSfxDescription` | `String` | Mô tả âm thanh SFX | `"Tiếng nước chảy"` |

---

## 5. Hướng Dẫn Thêm Hiệu Ứng Chậu Mới

1. Tạo file mới `[TenHieuUng]Effect.swift` trong thư mục `PotEffects/`.
2. Cho class kế thừa `PotTapEffect`:
   - Gán `particle.zPosition = 150` để nổi trên thân chậu và dây treo.
   - Sử dụng `SKAction` chuỗi `[delay, fadeIn, group([move, rotate, scale]), fadeOut, removeFromParent()]`.
3. Gán hiệu ứng trực tiếp vào mảng `tapEffects` trong `PotXNode.swift`.
4. (Tuỳ chọn) Khai báo thêm enum case trong `PotTapEffectType` và `PotTapEffectFactory` nếu muốn hỗ trợ tạo động.
