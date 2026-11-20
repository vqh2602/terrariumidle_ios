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

### 3.2. Nhà máy `PotTapEffectFactory`
Khởi tạo hiệu ứng động qua chuỗi cấu hình từ `pots_data.json`:
```swift
// Tự động gán hiệu ứng dựa theo thuộc tính "effect" trong pots_data.json
if let effect = PotTapEffectFactory.create(named: potData.effect) {
    potNode.tapEffects = [effect]
}
```

### 3.3. Tích hợp trong từng Node Chậu (`PotXNode.swift`)
Mỗi Node chậu khai báo danh sách hiệu ứng có thể kích hoạt:
```swift
public var tapEffects: [PotTapEffect] = [SparkleBurstEffect()]

public func playTapAnimation() {
    guard let node = potNode else { return }
    // 1. Nảy đàn hồi vật lý
    PotBounceAnimator.applyBounce(to: node, ...)
    // 2. Kích hoạt toàn bộ danh sách hiệu ứng tap
    for effect in tapEffects {
        effect.trigger(on: node, in: potRootNode, isHanging: isHanging)
    }
}
```

---

## 4. Hướng Dẫn Thêm Hiệu Ứng Chậu Mới

1. Tạo file mới `[TenHieuUng]Effect.swift` trong thư mục `PotEffects/`.
2. Cho class kế thừa `PotTapEffect`:
   - Gán `particle.zPosition = 150` để nổi trên chậu.
   - Sử dụng `SKAction` chuỗi `[delay, fadeIn, group([move, rotate, scale]), fadeOut, removeFromParent()]`.
3. Khai báo thêm enum case trong `PotTapEffectType`.
4. Đăng ký từ khoá nhận diện trong `PotTapEffectFactory.create(named:)`.
