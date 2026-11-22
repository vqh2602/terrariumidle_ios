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
     - **⚠️ QUY TẮC VÀNG `plantRootNode.position` - TUYỆT ĐỐI KHÔNG VI PHẠM**: Trong cả 3 hàm `buildSeedState`, `buildSproutState`, `buildMatureState`, `plantRootNode` **BẮT BUỘC** phải đặt:
       ```swift
       plantRootNode.position = .zero
       ```
       **TUYỆT ĐỐI KHÔNG ĐƯỢC** dùng `CGPoint(x: 0, y: isHanging ? containerSize.height : 0)` hay bất kỳ offset `containerSize.height` nào cho `plantRootNode`. **Lý do**: Vị trí của toàn bộ cây (`asNode`) đã được scene cha quản lý tập trung — `TerrariumSlotScene` cắm `plant.asNode` vào socket `plantMount` với `position = .zero`; `SpriteKitPlantScene` set `custom.asNode.position = CGPoint(x: 0, y: isHanging ? size.height : 0)`. Nếu `PlantXNode` tự thêm offset `containerSize.height` vào `plantRootNode`, cây bị **double-offset** và bay vượt ra ngoài vùng hiển thị — không thấy gì trên màn hình. *(Bug này đã xảy ra với Plant19 và phải sửa thủ công.)*
   - Luôn có cơ chế Fallback Procedural chứa toạ độ chuẩn phòng trường hợp scene chưa tải được.
   - **QUY CHUẨN HIỆU ỨNG BỌT KHÍ OXY (Oxygen Bubbles Convention - LẤY PLANT1 LÀM CHUẨN)**:
     - Bọt khí **BẮT BUỘC** phải add trực tiếp vào chính Node cây (`addChild(bubble)`), **TUYỆT ĐỐI KHÔNG** add vào `plantRootNode` vì `plantRootNode` bị `setScale(baseScale)` (thường thu nhỏ chỉ còn 0.2 ~ 0.25) khiến bọt khí bị teo nhỏ như hạt bụi và giới hạn không gian bay.
     - Bọt khí phải có node con `highlight` (điểm sáng phản chiếu trắng $30\%$ radius, alpha 0.8) tạo hiệu ứng 3D căng bóng.
     - Kích thước bọt chuẩn theo `containerSize`: Hạt (radius $1.8 \dots 3.0$), Cây con ($2.2 \dots 3.8$), Trưởng thành ($3.5 \dots 7.5$, $8 \dots 12$ bọt).
     - Phân bổ vị trí sinh bọt: Chuyển đổi vị trí lá sang toạ độ cây (`randomLeaf.parent?.convert(randomLeaf.position, to: self)`) hoặc trải đều tự nhiên khắp khung cây ($-44\% \dots +44\%$ chiều rộng, $18\% \dots 90\%$ chiều cao) với quãng đường bay $60 \dots 115\text{pt}$ và độ giãn nở `scaleUp: 1.30`.
     - Thân cọc/trụ leo (`assetId: 2` ở cây leo hoặc cây có thân riêng) không lắc độc lập làm rời cuống lá khỏi cành, thân chính chỉ đung đưa rất nhẹ ($0.003 \dots 0.008\text{rad}$).
     - **QUY CHUẨN CHỐNG TRÔI GÓC & XOAY LẬT 180 ĐỘ (Anti-Rotation Drift Convention - BẮT BUỘC TUÂN THỦ)**:
       * **CẤM TUYỆT ĐỐI DÙNG `SKAction.rotate(byAngle:)`**: Trong cả hiệu ứng chạm (`PlantMotionEffect`) và hiệu ứng gió lay nghỉ (`addIdleSwayAnimation`) của cành, lá, thân hay gốc cây.
         - *Nguyên nhân cốt lõi*: `rotate(byAngle:)` là biến đổi tương đối. Khi người dùng tap liên tục (spam tap), hành động cũ bị ngắt (`removeAction`) giữa chừng khi lá chưa kịp quay về vị trí nghỉ, hành động mới lại cộng dồn thêm góc xoay. Chỉ sau vài lần chạm, góc xoay tích luỹ đạt tới $\pm\pi$ ($180^\circ$), khiến phiến lá hoặc cả cây bị lộn ngược, úp ngược xuống chậu hoặc quay mòng mòng không thể tự phục hồi.
       * **BẮT BUỘC DÙNG `SKAction.rotate(toAngle:)` TÍNH THEO GÓC NGHỈ TUYỆT ĐỐI**:
         - Mọi chuyển động xoay phải dao động quanh góc nghỉ gốc ban đầu: `SKAction.rotate(toAngle: restAngle \pm delta, duration: ...)`.
       * **GHI NHỚ VÀ KHỞI TẠO `leaf.restZRotation`**:
         - `SKNode.restZRotation` được khai báo mở rộng trong `PlantMotionEffect.swift` (lưu trữ góc nghỉ gốc qua Objective-C runtime association).
         - Khi khởi tạo bất kỳ phiến lá nào (`leaf_X`) trong `buildMatureState` (cả nhánh nạp từ `.sks` lẫn nhánh Fallback Procedural), **BẮT BUỘC** phải gán:
           ```swift
           leaf.restZRotation = leaf.zRotation
           ```
       * **RESET GÓC NGHỈ NGAY ĐẦU ACTION SEQUENCE**:
         - Trong mọi `PlantMotionEffect`, ngay khi bắt đầu xử lý tap, sau khi gọi `leaf.removeAction(forKey: ...)` hoặc `root.removeAction(forKey: ...)`, **BẮT BUỘC** phải đưa góc xoay về tức thì:
           ```swift
           leaf.zRotation = leaf.restZRotation
           root.zRotation = 0.0
           ```
       * **CHỐT CHẶN PHỤC HỒI Ở CUỐI SEQUENCE**:
         - Chuỗi hành động tap luôn phải quay về `toAngle: restAngle` và chốt chặn an toàn ở cuối chuỗi bằng block:
           ```swift
           SKAction.run { [weak leaf] in leaf?.zRotation = restAngle }
           ```
       * **IDLE SWAY ANIMATION QUANH `restZRotation`**:
         - Trong `addIdleSwayAnimation()`, lá phải đu đưa quanh `restZRotation`:
           ```swift
           let rest = leaf.restZRotation
           let swayRight = SKAction.rotate(toAngle: rest + swayAngle, duration: duration)
           let swayLeft  = SKAction.rotate(toAngle: rest - swayAngle, duration: duration)
           ```
           Tuyệt đối không dùng `rotate(byAngle:)` trong idle animation vì nó sẽ làm lệch tâm dao động vĩnh viễn khi bị ngắt bởi tap.
       * **DEBOUNCE CHỐNG SPAM TAP Ở TẦNG SCENE/VIEW**:
         - Mọi Scene/View nhận touch tap (như `SpriteKitPlantScene`, `TerrariumSlotView`) **BẮT BUỘC** có cơ chế debounce tối thiểu 80ms (`CACurrentMediaTime() - lastTapTime < 0.08`) để ngăn bão sự kiện touch từ người dùng.
     - **Quy chuẩn Quản lý Hiệu ứng Cây (Plant Tap & Motion Effects Convention)**: Tương tự như Chậu, mọi loài cây phân tách rõ ràng 2 hệ thống độc lập đặt trong 2 thư mục riêng biệt: **`PlantEffects/Motion/` (Hiệu ứng Chuyển động Vật lý `PlantMotionEffect`)** và **`PlantEffects/Tap/` (Hiệu ứng Thị giác Dạng Hạt `PlantTapEffect`)**.
       * Hiệu ứng chuyển động cành lá quản lý qua: `public var motionEffect: PlantMotionEffect = ...`. Hỗ trợ: `StandardPlantBounceMotionEffect` (bản gốc nén nảy lò xo), `WindSwayMotionEffect` (bản mới: gió lay đu đưa mềm mại uốn lượn tán lá), `CascadingVineMotionEffect` (bản mới: chuỗi dây leo rủ buông đung đưa hình sin), `ElasticPulseMotionEffect` (bản mới: nhún nảy đàn hồi tần số nhanh cho sen đá).
       * Hiệu ứng hạt thị giác quản lý qua: `public var tapEffects: [PlantTapEffect] = [OxygenBubblesEffect(theme: ...)]`. Cho phép gán nhiều hiệu ứng đồng thời (Bọt khí Oxy, Bụi phấn hoa `SparklePollenEffect`, Cánh hoa rơi `FloatingPetalsEffect`) và khởi tạo động qua `PlantTapEffectFactory`.
       * Chi tiết tra cứu tại `PlantEffects/PLANT_EFFECTS_README.md`.
     - **Quy chuẩn Z-Index Hiệu ứng Chậu & Cây**: Mọi hiệu ứng hạt của Chậu (`PotTapEffect`) **BẮT BUỘC** có `zPosition = 150` (nằm trước thân chậu z = 50 và dây treo z = 100), hiệu ứng hạt/bọt khí của Cây (`PlantTapEffect`) có `zPosition = 200`.

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

## Quy chuẩn Chậu cây SpriteKit (Pot Views & widthFill Convention)

Mọi Chậu cây (`SpriteKitPotView`, `PotView`, và các View chuyên biệt `Pot1View` -> `Pot14View`) cùng các Node SpriteKit (`Pot1Node` -> `Pot14Node`):
1. **Tham số `widthFill: CGFloat`**:
   - Khoảng giá trị: `0.0 ... 1.0` (mặc định `0.0`, tối đa `1.0`, kiểu phần trăm `%`).
   - Có bí danh `public var fillWidth: CGFloat` tương thích 2 chiều.
   - **Ý nghĩa & mục đích**: Dùng để xử lý các chậu có tỉ lệ nguyên bản dạng dọc/hẹp (ví dụ `pot8`, `pot10`, `pot11`, `pot12`, `pot13` với tỉ lệ $H/W \ge 1.0$) khiến chậu bị teo hẹp khi đặt dưới cây có tán rộng trên kệ.
2. **Công thức tính toán độ rộng chuẩn (`targetW`)**:
   ```swift
   let targetH = containerSize.height * 0.98
   let naturalW = targetH / aspect
   let maxW = max(naturalW, containerSize.width * 0.96)
   let targetW = naturalW + (maxW - naturalW) * min(max(widthFill, 0.0), 1.0)
   ```
   - Khi `widthFill == 0`: chậu chỉ fill theo chiều cao (`targetH`), bề rộng tính tự nhiên theo `naturalW = targetH / aspect` giữ nguyên $100\%$ tỉ lệ gốc không bao giờ bị méo.
   - Khi `widthFill == 1.0`: chậu phủ tối đa chiều rộng cho phép (`maxW`).
   - Khi `0 < widthFill < 1`: mở rộng mượt mà theo tỉ lệ phần trăm giữa `naturalW` và `maxW`.
3. **Bóng đổ tự động co giãn (`shadowNode`)**:
   - Luôn tính bề rộng bóng đổ dựa theo `targetW` đã qua co giãn (`baseContactW = targetW * ratio`), đảm bảo bóng đổ luôn ôm sát đáy chậu khi kéo rộng.
4. **Định danh SwiftUI & Cập nhật Thời gian thực (`.id` & `PotRegistry`)**:
   - Mỗi View chậu (`PotXView`) có thể thiết lập `public static var defaultWidthFill: CGFloat` riêng (mặc định các chậu là `0.0`, riêng `pot13` là `0.35`).
   - `PotRegistry.defaultWidthFill(for: potId)` tự động liên kết giá trị này với `SpriteKitPotView` khi màn hình chính (`PlantItemView`) hiển thị chậu mà không truyền `widthFill`.
   - Khi sửa `defaultWidthFill` trong bất kỳ `PotXView.swift`, cả Preview và màn hình chính trang chủ đều tự động nhận giá trị đó ngay lập tức.
   - Khi caller chủ động truyền tham số `widthFill` cụ thể (kể cả `0.0`), giá trị truyền vào luôn có độ ưu tiên cao nhất.
   - `SpriteKitPotView` **BẮT BUỘC** phải gán modifier `.id("\(potId)-\(isHanging)-\(activeFill)-\(width)-\(height)")` cho `SpriteView` và gọi `scene.configure` đồng bộ trong `body` để đảm bảo khi `widthFill` thay đổi thì SpriteKit cập nhật kích thước ngay lập tức mà không bị cache `@State`.
5. **Quy chuẩn Quản lý Hiệu ứng Chạm Chậu (Pot Tap & Motion Effects Convention)**:
   - Tách biệt rõ ràng 2 hệ thống độc lập đặt trong 2 thư mục riêng biệt: **`PotEffects/Motion/` (Hiệu ứng Chuyển động Vật lý `PotMotionEffect`)** và **`PotEffects/Tap/` (Hiệu ứng Thị giác Dạng Hạt `PotTapEffect`)**.
   - Mọi chậu (`Pot1Node` -> `Pot18Node`) quản lý hiệu ứng rung/lắc/đu đưa qua thuộc tính:
     ```swift
     public var motionEffect: PotMotionEffect = ...
     ```
   - Các loại chuyển động tiêu chuẩn:
     * `ElasticPendulumMotionEffect`: Chậu treo lắc con lắc vật lý quanh đỉnh móc treo (`0.045 rad`) kết hợp nhún nảy đàn hồi trục Y (`scaleY: 0.96 -> 1.025 -> 1.0`) (Mặc định: **Pot15**).
     * `WidePendulumMotionEffect`: Chậu treo đu đưa con lắc biên độ rộng (`0.08 rad` ~ 4.6°), dao động 5 nhịp tắt dần mượt mà, thuần túy góc xoay (Mặc định: **Pot16, Pot17**).
     * `SpringPendulumMotionEffect`: Chậu treo con lắc đàn hồi 3 nhịp + khôi phục đu đưa tự nhiên (`addIdlePendulumSway()`) (Mặc định: **Pot18**).
     * `StandardBounceMotionEffect`: Chậu để bàn Squash & Stretch nén nảy lò xo đàn hồi tiêu chuẩn + co giãn bóng đổ đáy (Mặc định: **Pot1, 4, 6..14**).
     * `FirmBounceMotionEffect`: Chậu để bàn đầm chắc, biên độ nhỏ cho chậu đá/gốm nặng (Mặc định: **Pot2, 3, 5**).
     * `SubtleWobbleMotionEffect`: Rung lắc nhẹ trái/phải tần số nhanh (Micro-wobble/jiggle).
   - Khi cần đổi kiểu rung giữa các chậu (ví dụ muốn Pot16 rung nảy giống Pot15 hoặc ngược lại), chỉ cần sửa 1 dòng khai báo `motionEffect` trong Node chậu đó. Chi tiết tra cứu tại `PotEffects/POT_EFFECTS_README.md`.

## Quy chuẩn Kiến trúc Slot Hợp nhất (Unified Terrarium Slot: Cây + Chậu)

Để giải quyết triệt để các vấn đề:
1. **Lá rủ qua mặt trước chậu** (draping leaves in front of the pot rim).
2. **Dây treo vắt đè lên lá** (hanging cords in front of leaves).
3. **Định vị chính xác gốc cây cho chậu treo** qua socket `plantMount`.
4. **Tối ưu 50% số lượng `SKView` trên màn hình chính** (gộp 2 SKView thành 1 SKView duy nhất trên mỗi ô kệ).

### 1. Ma trận Chiều sâu Phân tầng (Z-Layer Interleaving Convention)
Trong một Scene SpriteKit duy nhất (`TerrariumSlotScene`), độ sâu hiển thị được quản lý bằng `zPosition`:
- `z = 0`: Dây treo phía sau (`backRopes` - chỉ có ở chậu treo).
- `z = 1`: Bóng đổ dưới đáy chậu (`shadowNode` - chỉ có ở chậu để bàn).
- `z = 5`: Lòng đất và thành sau chậu (`soilNode` / `backRim`).
- `z = 10`: Mỏ neo cắm cây (`plantMount` SKNode) & thân cây, cọc leo, các lá mọc phía sau (`backLeaves`, các lá có zPos từ 11 đến 19, tổng tích luỹ 21..29 < potBody 50).
- `z = 50`: Thân chậu & thành trước của chậu (`potBody` / `frontRim`) -> che khuất gốc cây tự nhiên.
- `z = 70`: Các phiến lá mọc tản / rủ xuống qua mặt trước miệng chậu (`frontLeaves` / `drapingLeaves`, tổng tích luỹ 81..89 > potBody 50).
- `z = 100`: Dây treo phía trước (`frontRopes` - chỉ có ở chậu treo) -> vắt ngang đè lên trên các phiến lá.
- `z = 200`: Hiệu ứng hạt bụi khí Oxy, bong bóng, đá lấp lánh (Sparkle, Twinkle, Oxygen bubbles).

### 2. Socket Mount Node (`plantMount`) trong Chậu
Mọi Node Chậu (`PotInteractiveNode`) đều cung cấp:
- `var plantMountNode: SKNode?`: Node mang tên `"plantMount"` trong `PotXScene.sks` (hoặc tạo bằng code), luôn có `zPosition = 10` nằm SAU mặt trước của chậu (`potNode` z = 50).
- `var plantMountPoint: CGPoint`: Toạ độ điểm cắm cây (Mount Point).
  - Với chậu để bàn: gốc cây cắm tại miệng chậu (`(0, targetH * 0.88)`).
  - Với chậu treo: gốc cây cắm trong lòng bầu chậu treo (`(0, -targetH * 0.65)` tính từ móc treo).

### 3. Thành phần Hợp nhất `TerrariumSlotView`
- Được sử dụng trên màn hình chính ([PlantItemView.swift](file:///Users/vuongquanghuy/code/prj_ios/terrariumidle_ios/terrariumidle_ios/Apps/Compoments/HomeCompoments/PlantItemView.swift)).
- **Quy chuẩn Chạm Hợp nhất (Unified Tap Interaction)**: Chạm vào bất kỳ vị trí nào trên Slot (cây hoặc chậu) đều kích hoạt **ĐỒNG THỜI** cả hiệu ứng chậu (`pot.playTapAnimation()`) và hiệu ứng cây (`plant.playTapAnimation()`), loại bỏ hoàn toàn xung đột phân vùng bấm. Được bọc `.contentShape(Rectangle())` và `.onTapGesture` kèm debounce 80ms chống tap đúp, đảm bảo nhận diện ngay lập tức 100% từ lần chạm đầu tiên.
- Tương thích ngược: `SpriteKitPotView` và `SpriteKitPlantView` độc lập vẫn được giữ nguyên cho màn hình Shop và Preview đơn lẻ.

### 4. Cấu hình Vị trí Layer Cây theo JSON (`itemTypeAttribute`)
Mỗi loài cây trong [plants_data.json](file:///Users/vuongquanghuy/code/prj_ios/terrariumidle_ios/terrariumidle_ios/Apps/Data/Items/plants_data.json) được cấu hình thuộc tính `"itemTypeAttribute"` điều khiển Z-Index phân tầng tự động.
Thuộc tính này hỗ trợ kết hợp nhiều cờ thuộc tính phân tách bằng dấu phẩy:
- `"none"` (mặc định cho cây để bàn đứng thẳng): Cây nằm **SAU** mặt trước của chậu (cắm vào `plantMount` z = 10, tổng z các lá 21..29 < `potBody` 50). Gốc cây cắm ngập trong lòng đất, vết cắt cuống được che giấu tự nhiên sau thành chậu (ví dụ: `plant1`, `plant2`, `plant3`, v.v.).
- `"front"` (cho cây dây leo, cành rủ): Cây nằm **TRƯỚC** mặt chậu (`plant.asNode.zPosition = 60` trong `plantMount`, tổng z các lá 81..89 > `potBody` 50). Toàn bộ cành lá phủ rủ xuống qua miệng chậu và đè lên mặt trước của chậu (ví dụ: `plant13` Philodendron hederaceum, `plant14` Heartleaf philodendron).
- `"hanging"`: Cây chậu treo, chúc ngược từ móc hoặc lòng chậu treo xuống.
- **`"hanging,front"` (kết hợp đa thuộc tính)**: Vừa là cây chậu treo (`isHanging = true`), vừa có cành lá vươn phủ đè ra **TRƯỚC** mặt chậu (`isInFront = true`).
- **Cơ chế Data-Driven**: `TerrariumSlotScene` và `TerrariumSlotView` tự động truy vấn `itemTypeAttribute` từ `ItemDataManager.shared.getPlant(byId: plantId)` nếu caller không truyền thủ công. Khi sửa thuộc tính này trong JSON, app tự động áp dụng ngay mà không cần sửa code Swift.
- Trong Swift Model: `ItemData.swift` định nghĩa:
  ```swift
  public struct ItemTypeAttribute: RawRepresentable, Codable, Hashable, Equatable, ExpressibleByStringLiteral {
      public var rawValue: String
      public var isHanging: Bool { flags.contains("hanging") }
      public var isInFront: Bool { flags.contains("front") }
      public var isNone: Bool { flags.contains("none") || flags.isEmpty || (!isHanging && !isInFront) }
      public func contains(_ flag: String) -> Bool { flags.contains(flag) }
  }
  ```

### 5. Cấu hình Vị trí Layer Chậu theo JSON (`pots_data.json` & Chậu Phân Lớp - Layered Pot)
Tương tự như Cây, các Chậu trong [pots_data.json](file:///Users/vuongquanghuy/code/prj_ios/terrariumidle_ios/terrariumidle_ios/Apps/Data/Items/pots_data.json) cũng hỗ trợ cấu hình đa thuộc tính `"itemTypeAttribute"`:
- `"none"` (mặc định): Chậu để bàn thông thường, hiển thị nguyên khối kèm bóng đổ đáy (`shadowNode`).
- `"hanging"`: Chậu treo thông thường (nguyên khối), treo từ đỉnh slot xuống.
- **`"hanging,front"` (Chậu Treo Phân Lớp - Layered Hanging Pot, điển hình `pot15` "Chậu sứ Msuit")**:
  - Chậu được bóc tách thành các thành phần asset riêng biệt theo file SVG thiết kế (`Pot15.svg`):
    * `backRope` (`Pot15-4@4.167x`, `z = 5`): Dây treo ở giữa nằm **phía sau** cây.
    * `plantMount` (Socket cắm cây, `z = 10`): Điểm gắn gốc cây.
    * `potBody` (`Pot15-5@4.167x`, `z = 50`): Bầu chậu sứ trắng che giấu cuống cây đứng (`none`), nằm sau cành lá rủ (`front`).
    * `frontLeftRope` (`Pot15-2@4.167x`, `z = 100`) & `frontRightRope` (`Pot15-3@4.167x`, `z = 100`): Hai dây treo đằng trước vắt ngang **đè lên trên** toàn bộ cành lá cây.
  - Khi tương tác chạm (Tap): Toàn bộ móc treo, các dây và bầu chậu đu đưa vật lý (Pendulum Swing) quanh đỉnh móc treo `(0, 0)`.

### 6. Quy chuẩn Khung Ô Gọn Gàng & Vùng Đệm Chống Cắt Biên (Fit Frame & Anti-Clipping Buffer)
Để cây luôn nằm gọn gàng, thanh lịch trong khung ô của mình mà không bao giờ bị cắt cụt mép lá:
- **Kích thước Cây chuẩn (`plantContainerSize`)**:
  - `plantFitW = baseW * 0.88`: Khống chế bề rộng tối đa của cây ở mức $88\%$ bề rộng ô kệ, để lại khoảng đệm an toàn $6\%$ mỗi bên trái/phải. Cây không bao giờ bị to quá cỡ hay lấn át sang cây khác.
  - `plantFitH = (baseH - slotMountPosition.y) * 0.86`: Khống chế chiều cao ngọn cây dừng lại ở $86\%$ khoảng cách lên thanh kệ trên, không đâm vào thanh kệ gỗ phía trên.
- **Vùng đệm an toàn chống cắt mép (Anti-Clipping Buffer)**:
  - `overflowRatioX = 0.12` ($+6\%$ mỗi bên trái/phải) và `overflowRatioY = 0.08` ($+8\%$ đỉnh/đáy).
  - Biên canvas render mở rộng nhẹ để khi cành lá đung đưa lắc lư tự nhiên theo gió, mép lá không bao giờ chạm vào biên render của Metal GPU (triệt tiêu 100% hiện tượng hard-clip).
- **SwiftUI Viewport**:
  ```swift
  SpriteView(scene: scene, options: [.allowsTransparency])
      .frame(width: renderWidth, height: renderHeight)
      .frame(width: width, height: height, alignment: isHanging ? .top : .bottom)
      .contentShape(Rectangle())
  ```
  - Gắn `.contentShape(Rectangle())` sau frame gốc `(width x height)`: Giữ trọn vẹn $100\%$ độ chính xác khi chạm tap từng ô mà không bị bấm nhầm sang ô bên cạnh.

### 7. Quy chuẩn Full Height Tầng Kệ & Chậu Treo Dính Đỉnh (Full Height Shelf & Top-Anchored Hanging Pot)
Để toàn bộ các tầng kệ có chiều cao đồng nhất, xoá bỏ hiện tượng chậu treo lơ lửng chơi vơi giữa không trung:
- **Chiều cao cố định chuẩn cho một tầng kệ (`slotHeight`)**:
  - `let slotHeight = itemWidth * 1.95`: Áp dụng đồng nhất cho **TẤT CẢ** các ô (ô có cây để bàn, ô có chậu treo, ô trống `Color.clear` và ô thêm cây `isEditing`).
  - Hàng kệ không bị co giãn méo mó theo từng ô.
- **Cơ chế Neo Toạ độ Đỉnh / Đáy (Geometric Anchor Alignment)**:
  - **Chậu để bàn (`isHanging == false`)**:
    * SwiftUI: `alignment: .bottom`.
    * SpriteKit: `pot.asNode.position = CGPoint(x: 0, y: 0)`.
    * Đáy chậu nằm chính xác trên mặt thanh kệ dưới. Cây mọc vươn từ dưới lên: cây thấp (mầm, sen đá) có ngọn ở giữa tầng, cây cao vươn lên đỉnh tầng, tạo cảnh quan tự nhiên phong phú.
  - **Chậu treo (`isHanging == true`)**:
    * SwiftUI: `alignment: .top`.
    * SpriteKit: `pot.asNode.position = CGPoint(x: 0, y: size.height)`.
    * Đỉnh móc chậu dính chặt 100% vào mép dưới thanh kệ gỗ phía trên. Dây treo và bầu chậu buông rủ xuống phía dưới.
    * Socket cắm cây `plantMountPoint` của chậu treo có toạ độ Y âm tính từ đỉnh móc treo (ví dụ `-targetH * 0.65`). Khi cắm cây, cây cắm vào miệng chậu và buông rủ xuống tự nhiên.

## Quy chuẩn Phong cảnh Nền SpriteKit (Landscapes Architecture)

Tương tự như `Pots` và `Plants`, mọi Phong cảnh nền (`Landscape1`, `Landscape2`, ...) đều áp dụng mô hình Kiến trúc Lai SpriteKit:
1. **Cấu trúc bộ 3 file & thư mục**:
   - `LandscapeXScene.sks` (Thiết kế trực quan trong Xcode Scene Editor): Canvas dọc $750 \times 1334$, `anchorPoint = (0.5, 0.5)` ở tâm.
   - `LandscapeXNode.swift`: Kế thừa `SKNode` và tuân thủ `LandscapeInteractiveNode`, ưu tiên nạp từ file `.sks` kèm Fallback code procedural an toàn.
   - `LandscapeXView.swift`: View SwiftUI xem trước độc lập kèm `#Preview`.
   - Đăng ký khởi tạo qua `LandscapeFactory.createLandscape(id:containerSize:)`.
2. **Quy chuẩn phân tầng Layer (`Landscape1` làm chuẩn)**:
   - `z = 0`: `bgNode` (`bg1-1@4.167x`) phủ tràn toàn màn hình dọc (Aspect Fill).
   - `z = 10`: `sunGroup` (Mặt trời & Hào quang đồng tâm):
     * `sunCore` (`sunbg1-2@4.167x`, z = 15): Mặt trời chính nhịp thở nhẹ nhàng.
     * `sunAura1` -> `sunAura4` (`sunbg1-3` -> `sunbg1-6`, z = 14..11): Các lớp hào quang xoay đa chiều ngược nhau, mờ tỏ nhịp nhàng.
   - `z = 20`: `cloudsGroup` (8 cụm mây `Cloudbg1-1` -> `Cloudbg1-8`): Trôi Parallax nhiều tầng vận tốc, tự động wrap vòng quanh màn hình.
   - `z = 35`: Hiệu ứng hạt bụi nắng / lấp lánh (Sparkle particles) sinh ra khi tương tác chạm tap.

3. **Quy chuẩn Asset Thumbnail & `landscapes_data.json` (`Landscape1` làm chuẩn)**:
   - Trường `"image"` trong `landscapes_data.json` **BẮT BUỘC** lấy `landscape1` làm chuẩn: `"image": "i_sky_sun_day"`.
   - Mọi phong cảnh (`landscape1` -> `landscape7`) đều sử dụng tên asset thumbnail có tiền tố `i_` trong `Assets.xcassets/Images/effect/`:
     * `landscape1`: `"image": "i_sky_sun_day"`
     * `landscape2`: `"image": "i_sky_sun_set"`
     * `landscape3`: `"image": "i_sky_rain"`
     * `landscape4`: `"image": "i_sky_moon_night"`
     * `landscape5`: `"image": "i_sky_moon_star"`
     * `landscape6`: `"image": "i_landscape6"`
     * `landscape7`: `"image": "i_landscape7"`
   - Tuyệt đối không đặt tên thiếu `i_` để tránh lỗi hình ảnh (broken image) khi render trong `EffectsSheetView`.

## Quy chuẩn Sticker & Vật trang trí SpriteKit (Sticker Architecture & stickers_data.json Convention)

Mọi Sticker / Vật trang trí (`Sticker1`, `Sticker2`, ...) tuân thủ mô hình Kiến trúc Lai SpriteKit:
1. **Cấu trúc bộ 3 file & thư mục (`Sticker1` làm chuẩn)**:
   - `StickerXScene.sks` (Thiết kế trực quan trong Xcode Scene Editor): Canvas $122 \times 375$, `anchorPoint = (0.5, 1.0)` cho sticker treo (`isHanging = true`), hoặc `anchorPoint = (0.5, 0.0)` cho sticker để bàn (`isHanging = false`).
   - `StickerXNode.swift`: Kế thừa `SKNode` và tuân thủ `StickerInteractiveNode`, ưu tiên nạp từ file `.sks` kèm Fallback code procedural an toàn.
   - `StickerXView.swift`: View SwiftUI xem trước độc lập kèm `#Preview`.
   - Đăng ký khởi tạo qua `StickerFactory.createSticker(id:containerSize:isHanging:)` và `StickerAvailability.supportedStickerIds`.

2. **Quy chuẩn Quản lý Hiệu ứng Sticker (Sticker Tap & Motion Effects Convention)**:
   - Tách biệt rõ ràng 2 hệ thống độc lập đặt trong 2 thư mục: **`StickerEffects/Motion/` (`StickerMotionEffect`)** và **`StickerEffects/Tap/` (`StickerTapEffect`)**.
   - Hiệu ứng chuyển động cành lá/dây/ruy băng quản lý qua:
     ```swift
     public var motionEffect: StickerMotionEffect = WindSwayStickerMotionEffect()
     ```
     * `WindSwayStickerMotionEffect` (Mặc định: **Sticker1**): Đung đưa tự nhiên nhịp gió nhàn rỗi (`zRotation: ±0.048 rad`, trôi nổi Y `±2.2pt`), khi chạm tăng nhịp mạnh `0.160 rad` (~9.2°) rồi dịu dần về nhịp gió tự nhiên.
     * `ElasticSwingStickerMotionEffect`: Con lắc đàn hồi quanh móc treo tần số cao + nhún nảy nén trục Y.
     * `StandardBounceStickerMotionEffect`: Nén nảy Squash & Stretch cho sticker để bàn/dán tường.
     * `SubtleFlutterStickerMotionEffect`: Rung rinh bay bổng vi mô.
   - Hiệu ứng hạt thị giác quản lý qua:
     ```swift
     public var tapEffects: [StickerTapEffect] = [SunRadianceEffect(), SparkleBurstStickerEffect()]
     ```
     * `SunRadianceEffect`: Vầng hào quang bung tỏa (`halo`), mặt trời vàng mặt cười tươi rói, 12 tia nắng xoay tròn và 14 ngôi sao nắng bung lượn lấp lánh (Mặc định: **Sticker1**).
     * `SparkleBurstStickerEffect`: Chùm sao vàng & bạc bung tỏa 360°.
     * `RainbowGlowEffect`: Vệt cầu vồng tươi sáng sau mưa.
     * `GoldenAuraEffect`: Vòng hào quang vàng kim đồng tâm.
   - Chi tiết tra cứu tại `StickerEffects/STICKER_EFFECTS_README.md`.

3. **Cấu hình Dữ liệu JSON `stickers_data.json`**:
   - Quản lý danh mục trong [stickers_data.json](file:///Users/vuongquanghuy/code/prj_ios/terrariumidle_ios/terrariumidle_ios/Apps/Data/Items/stickers_data.json).
   - Các trường dữ liệu chính: `id`, `name`, `description`, `image`, `priceStore`, `priceOxygen`, `currencyUnit`, `type` (`"sticker"`), `itemTypeAttribute`, `levelUnlock`, `effect`, `effectDescription`, `music`, `musicDescription`, `effectLandscape`, `effectLandscapeDescription`, `effectSfx`, `effectSfxDescription`.
   - **Quy chuẩn `itemTypeAttribute`**:
     * `"hanging"`: Sticker treo đỉnh kệ (`alignment: .top`, `anchorPoint = (0.5, 1.0)`).
     * `"hanging,front"`: Sticker treo phân lớp đa thành phần (Dây treo z=5, Thân búp bê z=10, Ruy băng trước z=20 như `sticker1`).
     * `"none"`: Sticker để bàn (`alignment: .bottom`, `anchorPoint = (0.5, 0.0)` như `sticker2`, `sticker3`, `sticker4`).
     * `"front"`: Sticker phủ mặt trước kệ.
   - **Vùng đệm an toàn chống cắt mép (Anti-Clipping Buffer)**: `SpriteKitStickerView` mở rộng biên render `overflowRatioX: 0.22`, `overflowRatioY: 0.15` và khống chế bán kính hào quang trong `safeRadius` để hiệu ứng mặt trời không bao giờ bị cắt mép.

## Quy chuẩn Cấu hình Dữ liệu JSON Mới & Âm Thanh Chạm (Data Schema & Audio Convention)

### 1. Phân định rõ giữa Code Node SpriteKit và File JSON
- **Hiệu ứng Tap hạt / hoạt ảnh chậu, cây & sticker (`tapEffects: [PotTapEffect]`, `[PlantTapEffect]`, `[StickerTapEffect]`)**:
  * BẮT BUỘC cấu hình trực tiếp bên trong file Node (`PlantXNode.swift`, `PotXNode.swift`, `StickerXNode.swift`).
  * **TUYỆT ĐỐI KHÔNG** đưa các hiệu ứng tap cục bộ (bong bóng oxy, đá lấp lánh, mặt trời tỏa sáng, trái tim nhịp đập, v.v.) vào trường `effect` của JSON.
- **Trường dữ liệu JSON (`plants_data.json`, `pots_data.json`, `stickers_data.json`)**:
  * Quản lý độc lập âm thanh tap click và các item mở khóa khi trồng:
    - `sound`: Âm thanh khi click vào cây, mặc định `"tap"` (chỉ áp dụng với `plants_data.json`).
    - `effect`: Danh sách ID hiệu ứng overlay mở khóa khi trồng (phân tách bởi dấu phẩy `,`, ví dụ: `"overlay1,overlay2"`).
    - `effectDescription`: Mô tả các hiệu ứng overlay (ví dụ: `"Lá rơi xanh ngọc"`).
    - `music`: Danh sách ID bài hát BGM mở khóa (ví dụ: `"m0,m1"`, `"m3"`).
    - `musicDescription`: Mô tả bài hát BGM mở khóa (ví dụ: `"Relax"`, `"Mong một ngày mưa"`).
    - `effectLandscape`: Danh sách ID phong cảnh nền mở khóa (ví dụ: `"landscape1"`, `"landscape5"`).
    - `effectLandscapeDescription`: Mô tả phong cảnh mở khóa (ví dụ: `"Ban công quang đãng"`).
    - `effectSfx`: Danh sách ID âm thanh SFX mở khóa (ví dụ: `"sfx5"`, `"sfx7"`).
    - `effectSfxDescription`: Mô tả âm thanh SFX mở khóa (ví dụ: `"Tiếng nước chảy"`).

### 2. Quy chuẩn Phát Âm Thanh Tap Trên Ban Công
- Khi chạm (tap/click) vào bất kỳ vị trí nào trên ô cây hoặc chậu trên ban công:
  * `TerrariumSlotScene.handleTap()` **BẮT BUỘC** gọi `AudioPlayer.shared.playClickSound(named: soundName)`.
  * `soundName` ưu tiên lấy từ thuộc tính `plant.clickSound` (mặc định `"tap"`), nếu ô không có cây (chỉ có chậu/sticker) thì fallback sang `pot.clickSound` hoặc `"tap"`.

