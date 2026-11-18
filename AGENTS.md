# Workspace Guidelines

## Mô hình Kiến trúc Lai SpriteKit (Visual `.sks` + Swift Code)

1. **Thiết kế trực quan (`*.sks` - Xcode Scene Editor)**:
   - Dùng kéo thả bằng chuột trong Xcode để chỉnh vị trí cây, lá, cành, mây, mặt trời, kích thước, góc xoay, thứ tự layer (`zPosition`), điểm neo (`anchorPoint`).
   - Chia nhóm node rõ ràng: `seedNode` (Hạt giống), `sproutNode` (Cây con), `matureNode` (Cây trưởng thành).
   - Khi chỉnh vị trí trong Xcode `.sks`, code Swift phải tự động sử dụng vị trí mới đó, không bắt buộc sửa tọa độ bằng tay trong code.

2. **Lập trình Logic & Hoạt ảnh (`*.swift`)**:
   - Code Swift 100% cho logic và animation: mưa rơi, gió thổi, cây uốn lượn, lớn lên theo level, phản hồi tương tác tap (squash & stretch, sinh bọt khí oxy).
   - Tải các node từ `.sks` và gắn các `SKAction` hoạt ảnh động.

3. **Xem trước (Preview)**:
   - Preview được giao diện và animation trực tiếp trên SwiftUI Canvas Preview (ví dụ: `Plant1View.swift`) mà không phải chạy toàn bộ game mỗi lần.

## Quy ước Asset Cây (Plant Asset Convention)

- **`Asset-1`** (hoặc `plantX_Asset-1`): Ảnh nền/ảnh đại diện của cây (ảnh tĩnh dùng làm thumbnail và đối chiếu toạ độ). **Tuyệt đối KHÔNG đưa vào scene làm hiệu ứng hay layer chuyển động**.
- **`Asset-2` -> `Asset-99`**: Các thành phần hoạt ảnh động (lá cây, cành, hoa uốn lượn). Toàn bộ cây trưởng thành được ghép và diễn hoạt từ các thành phần này.
- **`Asset-100`**: Trạng thái gieo hạt giống (Level 1).
- **`Asset-200`**: Trạng thái cây con (Level 2).
