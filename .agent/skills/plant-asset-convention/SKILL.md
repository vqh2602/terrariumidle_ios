---
name: plant-asset-convention
description: Quy chuẩn quản lý, phân bổ Asset và xây dựng hiệu ứng SpriteKit cho các loài cây (Plants) trong Terrarium Idle iOS. Áp dụng khi tạo mới cây, tổ chức asset hoặc xây dựng hoạt ảnh cây SpriteKit.
---

# Quy chuẩn Cấu trúc Asset & Hoạt ảnh Cây (Plant Asset Convention)

Áp dụng cho tất cả các loài cây (`Plant1`, `Plant2`,...) trong dự án `terrariumidle_ios`.

## 1. Phân bổ và Đánh số Asset (Asset ID Naming Convention)

Khi cấu hình asset trong `Assets.xcassets/Plants/<plant_folder>/`:

| Asset ID | Vai trò & Mục đích | Cơ chế hoạt động & Quy tắc sử dụng |
| :--- | :--- | :--- |
| **`Asset-1`** | **Ảnh nền / Ảnh đại diện tĩnh (Avatar / Reference)** | **KHÔNG** đưa vào làm hiệu ứng chuyển động trong Scene SpriteKit. Chỉ dùng làm ảnh đại diện (avatar/thumbnail/store preview) hoặc làm ảnh tham chiếu (reference canvas) để đối chiếu tọa độ pixel, anchor point, scale khi dựng hoạt ảnh. |
| **`Asset-2` -> `Asset-99`** | **Thành phần hoạt ảnh động (Animated Parts)** | Các bộ phận cấu tạo nên cây trưởng thành (Level 3+): các phiến lá, cuống, cành cây, bông hoa. Mỗi phần tử được render riêng biệt qua SpriteKit `SKSpriteNode` với điểm neo (`anchorPoint`) tại cuống/gốc và chạy hiệu ứng uốn lượn, lay động mềm mại trong gió (`SKAction.rotateBy`, `scaleY`). Khi ghép toàn bộ các asset này lại sẽ tạo thành một cây hoàn chỉnh mà không cần `Asset-1`. |
| **`Asset-100`** | **Gieo hạt (Seed Stage - Level 1)** | Hiển thị trạng thái hạt giống trong đất hoặc mầm vừa nhú. Kèm hiệu ứng thở nhẹ / nảy mầm khi người chơi chạm vào (`tapSquashStretch`). |
| **`Asset-200`** | **Cây con (Sprout Stage - Level 2)** | Hiển thị trạng thái cây con 2 mầm lá non. Kèm hiệu ứng lắc lư đung đưa (`swayAction`) và nhún nhẹ (`bobAction`). |

---

## 2. Quy tắc triển khai Code SpriteKit (`PlantXNode.swift`)

1. **Trạng thái Trưởng thành (Level 3+)**:
   - Chỉ load và add các node từ `Asset-2` đến `Asset-99` (ví dụ: `Plant1` gồm 18 lá từ `Asset-2` -> `Asset-19`).
   - Tuyệt đối **KHÔNG** add `Asset-1` vào `plantRootNode` làm thân cây hay nền phía sau vì nó là ảnh tĩnh đại diện và đối chiếu.
   - Anchor point cho từng lá đặt tại gốc cuống lá (ví dụ: mép phải `(0.95, 0.05)` cho lá vươn sang trái, mép trái `(0.05, 0.05)` cho lá vươn sang phải).
   - Hiệu ứng uốn lượn (`startLeafBendingAnimation`) sử dụng các chu kỳ dao động không đồng bộ (asynchronous sway duration từ 2.5s - 3.6s) để cây lay động tự nhiên như thở.

2. **Hệ tọa độ & Căn chỉnh (Alignment & Framing)**:
   - Toàn bộ cây và scene sử dụng hệ quy chiếu gốc đáy giữa: `anchorPoint = CGPoint(x: 0.5, y: 0.0)`.
   - Node gốc `plantRootNode.position = CGPoint(x: 0, y: isHanging ? containerSize.height : 0)`.
   - Tọa độ các bộ phận `(skX, skY)` được tính chuẩn hóa từ pixel ảnh gốc so với canvas kích thước chuẩn.
