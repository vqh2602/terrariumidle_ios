# Plant Asset & Animation Rules

Khi làm việc với các asset cây (Plants) và SpriteKit trong dự án:

1. **Asset-1**: Là ảnh nền / ảnh đại diện (avatar/thumbnail/preview) tĩnh.
   - Dùng để làm ảnh đại diện hoặc làm ảnh đối chiếu căn toạ độ pixel, anchor point.
   - **KHÔNG ĐƯỢC** đưa `Asset-1` vào scene làm layer chuyển động hay khung xương cây.
2. **Asset-2 -> Asset-99**: Là các thành phần hoạt ảnh động (các phiến lá, cuống, cành cây, v.v.).
   - Tạo nên hình thái hoàn chỉnh của cây trưởng thành (Level 3+).
   - Mỗi bộ phận chạy hiệu ứng rung rinh, uốn lượn riêng biệt.
3. **Asset-100**: Trạng thái gieo hạt giống (Level 1 / Seed state).
4. **Asset-200**: Trạng thái cây con (Level 2 / Sprout state).
