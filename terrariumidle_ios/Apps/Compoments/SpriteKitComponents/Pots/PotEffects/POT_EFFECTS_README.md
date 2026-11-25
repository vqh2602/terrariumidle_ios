# Hệ Thống Hiệu Ứng Chạm Chậu Cây (Pot Tap & Motion Effects System)

Khi người chơi chạm (tap/click) vào chậu cây trong Terrarium Idle iOS, phản hồi tương tác được điều phối qua **hai hệ thống hiệu ứng độc lập và song song**, được phân tách thành 2 thư mục chuyên biệt:
1. **`PotEffects/Motion/` (Hiệu ứng Chuyển động Vật lý - `PotMotionEffect`)**: Điều khiển rung lắc, con lắc đu đưa (Pendulum Swing), hoặc nhún nảy đàn hồi (Squash & Stretch spring bounce) lên khung chậu / dây treo / bóng đổ.
2. **`PotEffects/Tap/` (Hiệu ứng Thị giác Dạng Hạt - `PotTapEffect`)**: Sinh các chùm hạt lấp lánh (Sparkle, Gold Glint, Heart, Dust, Wood Pollen, Emerald Jade, Coral Bubble, Bamboo Mist...) bùng nổ xung quanh thân chậu tại `zPosition = 150`.

```
PotEffects/
├── Motion/                              # Thư mục chuyên trách hiệu ứng chuyển động vật lý
│   ├── PotMotionEffect.swift            # Protocol, Context, Enum, Factory
│   ├── PotBounceAnimator.swift          # Core Animator nén nảy Squash & Stretch
│   ├── ElasticPendulumMotionEffect.swift # Mẫu chậu 15, 19 (đu đưa nhanh + nảy scaleY)
│   ├── WidePendulumMotionEffect.swift    # Mẫu chậu 16, 17 (đu đưa góc rộng 5 nhịp)
│   ├── SpringPendulumMotionEffect.swift  # Mẫu chậu 18 (đu đưa lò xo + khôi phục idle)
│   ├── StandardBounceMotionEffect.swift  # Mẫu chậu để bàn 1..14, 20..30 (chuẩn & firm)
│   └── SubtleWobbleMotionEffect.swift    # Rung lắc vi mô
├── Tap/                                 # Thư mục chuyên trách hiệu ứng hạt thị giác
│   ├── PotTapEffect.swift               # Protocol, Enum, Factory
│   ├── SparkleBurstEffect.swift         # Đá lấp lánh (Pot1, 15, 16, 27)
│   ├── GoldGlintEffect.swift            # Vệt ánh vàng (Pot2, 25)
│   ├── StoneDustEffect.swift            # Bụi đá xám (Pot3, 17, 21)
│   ├── HeartBurstEffect.swift           # Trái tim bay (Pot4)
│   ├── ClayGlintEffect.swift            # Ánh gốm nung (Pot5, 22, 24)
│   ├── QuartzBurstEffect.swift          # Thạch anh lăng kính (Pot6, 19, 26)
│   ├── EarthenParticlesEffect.swift     # Bụi đất mộc (Pot7..14, 18, 23)
│   ├── WoodPollenEffect.swift           # Bụi phấn gỗ thơm ấm áp (Pot20)
│   ├── EmeraldJadeEffect.swift          # Ánh ngọc bích băng tuyết (Pot28)
│   ├── CoralBubbleEffect.swift          # Bọt ngọc san hô phập phồng (Pot29)
│   └── BambooMistEffect.swift           # Sương mai thiền tịnh (Pot30)
└── POT_EFFECTS_README.md                # Tài liệu kiến trúc & hướng dẫn
```

---

## 1. Hệ Thống Hiệu Ứng Chuyển Động Tap (`PotMotionEffect`)

Mọi chậu cây (`Pot1Node` -> `Pot30Node`) đều có thuộc tính:
```swift
public var motionEffect: PotMotionEffect = ...
```

### 1.1. Danh Mục Các Hiệu Ứng Chuyển Động (`Motion Effects`)

| Tên Hiệu Ứng | Lớp Triển Khai (`Class`) | Định Danh Type | Phù Hợp Cho | Đặc Điểm Chuyển Động |
| :--- | :--- | :--- | :--- | :--- |
| **Con lắc đàn hồi** | `ElasticPendulumMotionEffect` | `elasticPendulum` | Chậu treo (Mặc định: **Pot15, Pot19**) | Lắc con lắc nhanh quanh móc treo (`0.045 rad`) kết hợp nhún nảy nén trục Y (`scaleY: 0.96 -> 1.025 -> 1.0`). |
| **Đu đưa góc rộng** | `WidePendulumMotionEffect` | `widePendulum` | Chậu treo (Mặc định: **Pot16, Pot17**) | Đu đưa con lắc biên độ rộng (`0.08 rad` ~ 4.6°), dao động 5 nhịp tắt dần mượt mà, thuần túy góc xoay, không méo hình. |
| **Con lắc lò xo** | `SpringPendulumMotionEffect` | `springPendulum` | Chậu treo (Mặc định: **Pot18**) | Lắc 3 nhịp (`0.065 rad -> -0.050 rad -> 0.0`) rồi tự động khôi phục chuyển động đung đưa nhàn rỗi (`addIdlePendulumSway()`). |
| **Nén nảy tiêu chuẩn** | `StandardBounceMotionEffect` | `standardBounce` | Chậu để bàn (Mặc định: **Pot1, 4, 6..14, 20, 22..25, 29**) | Squash & Stretch lò xo đàn hồi (nén X: 1.10, Y: 0.90 -> bật X: 0.95, Y: 1.07 -> cân bằng) kèm co giãn bóng đổ đáy. |
| **Nén nảy đầm chắc** | `FirmBounceMotionEffect` | `firmBounce` | Chậu để bàn (Mặc định: **Pot2, 3, 5, 21, 26..28, 30**) | Biên độ nảy nhỏ hơn, đầm chắc cho chậu làm từ đá, kim loại, ngọc hoặc gốm sứ dày nặng. |
| **Rung lắc vi mô** | `SubtleWobbleMotionEffect` | `subtleWobble` | Tùy chọn chậu nhỏ/kim loại | Rung lắc nhẹ trái/phải tần số nhanh (Micro-wobble/jiggle) trong 0.2s. |

### 1.2. Protocol `PotMotionEffect` & `PotMotionContext`

```swift
public protocol PotMotionEffect: AnyObject {
    var name: String { get }
    func apply(context: PotMotionContext)
}
```

Ngữ cảnh `PotMotionContext` đóng gói đầy đủ:
- `targetNode`: Node nhận chuyển động (với chậu treo là `hangingRigNode`, chậu để bàn là `potNode`).
- `potNode`: Sprite thân chậu (nếu cần scale co giãn Squash & Stretch).
- `shadowNode`: Node bóng đổ dưới đáy chậu.
- `initialPosition`: Tọa độ ban đầu (reset chống trôi khi tap dồn dập).
- `isHanging`: Cờ phân biệt chậu treo hay chậu để bàn.
- `onComplete`: Callback thông báo khi chuỗi chuyển động kết thúc.

### 1.3. Cách Chỉnh Sửa / Đổi Kiểu Rung Giữa Các Chậu Cực Kỳ Dễ Dàng

Nếu bạn muốn thay đổi kiểu rung của một chậu, chỉ cần sửa **1 dòng duy nhất** trong file Node của chậu đó:

```swift
// Ví dụ 1: Muốn Pot16 đu đưa đàn hồi nảy nén giống Pot15:
public var motionEffect: PotMotionEffect = ElasticPendulumMotionEffect()

// Ví dụ 2: Muốn Pot15 đu đưa biên độ rộng 5 nhịp giống Pot16:
public var motionEffect: PotMotionEffect = WidePendulumMotionEffect()

// Ví dụ 3: Tinh chỉnh góc xoay hoặc thời gian cho Pot16:
public var motionEffect: PotMotionEffect = WidePendulumMotionEffect(swingAngle: 0.12, durationMultiplier: 1.2)
```

---

## 2. Hệ Thống Hiệu Ứng Dạng Hạt (`PotTapEffect`)

Mỗi chậu quản lý danh sách hiệu ứng hạt qua mảng:
```swift
public var tapEffects: [PotTapEffect] = [SparkleBurstEffect()]
```

### 2.1. Danh Mục Các Hiệu Ứng Hạt Hiện Có

| Tên Hiệu Ứng | Lớp Triển Khai (`Class`) | Định Danh Type | Mô Tả Thị Giác & Màu Sắc |
| :--- | :--- | :--- | :--- |
| **Đá lấp lánh** | `SparkleBurstEffect` | `sparkleBurst` | Chùm sao 4 cánh nhọn phát sáng (mặc định `.classic`: Vàng hoàng yến & Hồng phấn), hỗ trợ thêm `.golden`, `.emeraldJade`, `.sapphireAqua`, `.amethystRose`, `.rainbow`. |
| **Vệt ánh vàng** | `GoldGlintEffect` | `goldGlint` | Vệt ánh kim quét chéo lướt qua thân chậu kèm tia sao 4 cánh vàng rực nhấp nháy 2 nhịp và mảnh vàng lá. |
| **Bụi đá xám** | `StoneDustEffect` | `stoneDust` | Làn khói bụi đá xám khoáng mịn tỏa hai bên kết hợp mảnh đá góc cạnh văng theo trọng lực và hạt mica ánh bạc. |
| **Trái tim bay** | `HeartBurstEffect` | `heartBurst` | Chùm trái tim bay vút lên trời kèm nhịp thở phập phồng (mặc định `.classic`), hỗ trợ thêm `.pastel`, `.crimsonPassion`, `.rainbow`. |
| **Ánh gốm nung** | `ClayGlintEffect` | `clayGlint` | Vệt bóng men gốm ấm áp phản chiếu trên thân chậu cùng sao men nung cam đào và mảnh gốm hình thoi sắc nét. |
| **Thạch anh lăng kính**| `QuartzBurstEffect` | `quartzBurst` | Tinh thể kim cương/lăng kính xoay lấp lánh (mặc định `.roseAmethyst`: Hồng & Tím), hỗ trợ thêm `.citrineGold`, `.aquamarine`, `.prism`. |
| **Bụi đất mộc** | `EarthenParticlesEffect` | `earthenDust` | Vụn đất sét góc cạnh nảy parabol theo trọng lực kết hợp làn bụi đất nung ấm áp mộc mạc. |
| **Bụi phấn gỗ thơm** | `WoodPollenEffect` | `woodPollen` | Chùm hạt phấn gỗ ấm áp bay bổng (mặc định `.warmAmber`), hỗ trợ thêm `.forestBlossom`, `.goldenDust`. |
| **Ánh ngọc bích băng** | `EmeraldJadeEffect` | `emeraldJade` | Chùm tinh thể ngọc phát sáng xoay 360° (mặc định `.iceJade`), hỗ trợ thêm `.imperialGreen`, `.amethystJade`. |
| **Bọt ngọc san hô** | `CoralBubbleEffect` | `coralBubble` | Chùm bọt ngọc phập phồng (mặc định `.coralPink`), hỗ trợ thêm `.oceanPearl`, `.sunset`, `.multicolor`. |
| **Sương mai thiền tịnh** | `BambooMistEffect` | `bambooMist` | Chùm hạt sương mai và đốm sáng thanh khiết (mặc định `.zenDew`), hỗ trợ thêm `.morningSky`, `.autumnZen`. |

### 2.2. Các Bộ Theme Màu Sắc Hiệu Ứng Hạt Chậu (`Theme`)

Các hiệu ứng hạt chậu hỗ trợ truyền `theme` trực tiếp khi khởi tạo (ví dụ `SparkleBurstEffect(theme: .rainbow)`) hoặc qua `PotTapEffectType`:

| Hiệu Ứng | Các Bộ Theme (`Theme`) | `PotTapEffectType` Tương Ứng |
| :--- | :--- | :--- |
| **`SparkleBurstEffect`** | `.classic` (mặc định), `.golden`, `.emeraldJade`, `.sapphireAqua`, `.amethystRose`, `.rainbow` | `sparkleBurst`, `sparkleGolden`, `sparkleEmerald`, `sparkleSapphire`, `sparkleAmethyst`, `sparkleRainbow` |
| **`HeartBurstEffect`** | `.classic` (mặc định), `.pastel`, `.crimsonPassion`, `.rainbow` | `heartBurst`, `heartPastel`, `heartCrimson`, `heartRainbow` |
| **`QuartzBurstEffect`** | `.roseAmethyst` (mặc định), `.citrineGold`, `.aquamarine`, `.prism` | `quartzBurst`, `quartzCitrine`, `quartzAquamarine`, `quartzPrism` |
| **`WoodPollenEffect`** | `.warmAmber` (mặc định), `.forestBlossom`, `.goldenDust` | `woodPollen`, `woodPollenBlossom`, `woodPollenGolden` |
| **`EmeraldJadeEffect`** | `.iceJade` (mặc định), `.imperialGreen`, `.amethystJade` | `emeraldJade`, `emeraldImperial`, `emeraldAmethyst` |
| **`CoralBubbleEffect`** | `.coralPink` (mặc định), `.oceanPearl`, `.sunset`, `.multicolor` | `coralBubble`, `coralOceanPearl`, `coralSunset`, `coralMulticolor` |
| **`BambooMistEffect`** | `.zenDew` (mặc định), `.morningSky`, `.autumnZen` | `bambooMist`, `bambooMorningSky`, `bambooAutumnZen` |

---

## 3. Quy Chuẩn Phân Tầng Chiều Sâu (Z-Index Hierarchy)

> [!IMPORTANT]
> Toàn bộ hiệu ứng tap hạt của Chậu **BẮT BUỘC** phải có `zPosition >= 150` (chuẩn là `150` đến `200`).
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

## 4. Bảng Tra Cứu Cấu Hình Toàn Bộ 30 Chậu (Pot1 -> Pot30)

| Chậu | Loại Chậu | Hiệu Ứng Chuyển Động (`motionEffect`) | Hiệu Ứng Hạt (`tapEffects`) |
| :--- | :--- | :--- | :--- |
| **Pot1** | Để bàn | `StandardBounceMotionEffect(config: custom)` | `[SparkleBurstEffect()]` |
| **Pot2** | Để bàn | `FirmBounceMotionEffect()` | `[GoldGlintEffect()]` |
| **Pot3** | Để bàn | `FirmBounceMotionEffect()` | `[StoneDustEffect()]` |
| **Pot4** | Để bàn | `StandardBounceMotionEffect()` | `[HeartBurstEffect()]` |
| **Pot5** | Để bàn | `FirmBounceMotionEffect()` | `[ClayGlintEffect()]` |
| **Pot6** | Để bàn | `StandardBounceMotionEffect(config: custom)` | `[QuartzBurstEffect()]` |
| **Pot7** | Để bàn | `StandardBounceMotionEffect()` | `[EarthenParticlesEffect()]` |
| **Pot8** | Để bàn | `StandardBounceMotionEffect()` | `[EarthenParticlesEffect()]` |
| **Pot9** | Để bàn | `StandardBounceMotionEffect()` | `[EarthenParticlesEffect()]` |
| **Pot10** | Để bàn | `StandardBounceMotionEffect()` | `[EarthenParticlesEffect()]` |
| **Pot11** | Để bàn | `StandardBounceMotionEffect()` | `[EarthenParticlesEffect()]` |
| **Pot12** | Để bàn | `StandardBounceMotionEffect()` | `[EarthenParticlesEffect()]` |
| **Pot13** | Để bàn | `StandardBounceMotionEffect()` | `[EarthenParticlesEffect()]` |
| **Pot14** | Để bàn | `StandardBounceMotionEffect()` | `[EarthenParticlesEffect()]` |
| **Pot15** | Treo | `ElasticPendulumMotionEffect()` | `[SparkleBurstEffect()]` |
| **Pot16** | Treo | `WidePendulumMotionEffect()` | `[SparkleBurstEffect()]` |
| **Pot17** | Treo | `WidePendulumMotionEffect()` | `[StoneDustEffect()]` |
| **Pot18** | Treo/Bàn | `SpringPendulumMotionEffect()` | `[EarthenParticlesEffect()]` |
| **Pot19** | Treo | `ElasticPendulumMotionEffect()` | `[QuartzBurstEffect()]` |
| **Pot20** | Để bàn | `StandardBounceMotionEffect()` | `[WoodPollenEffect()]` |
| **Pot21** | Để bàn | `FirmBounceMotionEffect()` | `[StoneDustEffect()]` |
| **Pot22** | Để bàn | `StandardBounceMotionEffect()` | `[ClayGlintEffect()]` |
| **Pot23** | Để bàn | `StandardBounceMotionEffect()` | `[EarthenParticlesEffect()]` |
| **Pot24** | Để bàn | `StandardBounceMotionEffect()` | `[ClayGlintEffect()]` |
| **Pot25** | Để bàn | `StandardBounceMotionEffect()` | `[GoldGlintEffect()]` |
| **Pot26** | Để bàn | `FirmBounceMotionEffect()` | `[QuartzBurstEffect()]` |
| **Pot27** | Để bàn | `FirmBounceMotionEffect()` | `[SparkleBurstEffect()]` |
| **Pot28** | Để bàn | `FirmBounceMotionEffect()` | `[EmeraldJadeEffect()]` |
| **Pot29** | Để bàn | `StandardBounceMotionEffect()` | `[CoralBubbleEffect()]` |
| **Pot30** | Để bàn | `FirmBounceMotionEffect()` | `[BambooMistEffect()]` |

---

## 5. Hướng Dẫn Thêm Hiệu Ứng Mới

### 5.1. Thêm Hiệu Ứng Chuyển Động Mới (Motion Effect)
1. Tạo file mới `[TenHieuUng]MotionEffect.swift` trong thư mục `PotEffects/Motion/`.
2. Cho class kế thừa protocol `PotMotionEffect`:
   ```swift
   public final class MyCustomMotionEffect: PotMotionEffect {
       public var name: String { "MyCustomMotion" }
       
       public func apply(context: PotMotionContext) {
           let target = context.targetNode
           target.removeAction(forKey: "potMotionTap")
           
           let action = SKAction.sequence([
               SKAction.rotate(byAngle: 0.1, duration: 0.1),
               SKAction.rotate(byAngle: -0.1, duration: 0.1),
               SKAction.run { context.onComplete?() }
           ])
           target.run(action, withKey: "potMotionTap")
       }
   }
   ```
3. Gán trực tiếp vào bất kỳ chậu nào qua `public var motionEffect: PotMotionEffect = MyCustomMotionEffect()`.
4. (Tuỳ chọn) Đăng ký enum trong `PotMotionEffectType` và `PotMotionEffectFactory` để hỗ trợ tạo động theo tên.

### 5.2. Thêm Hiệu Ứng Hạt Mới (Tap Particle Effect)
1. Tạo file mới `[TenHieuUng]Effect.swift` trong thư mục `PotEffects/Tap/`.
2. Cho class kế thừa `PotTapEffect`:
   - Gán `particle.zPosition = 150` để nổi trên thân chậu và dây treo.
   - Sử dụng `SKAction` chuỗi `[delay, fadeIn, group([move, rotate, scale]), fadeOut, removeFromParent()]`.
3. Gán trực tiếp vào mảng `tapEffects` trong `PotXNode.swift`.
4. (Tuỳ chọn) Khai báo thêm enum case trong `PotTapEffectType` và `PotTapEffectFactory`.
