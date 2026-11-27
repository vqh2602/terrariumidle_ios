# Thành tích Terrarium Idle

Bản mở rộng có **70 thành tích, 19 nhóm, 700 điểm Game Center**. Dành **30 thành tích / 300 điểm** cho các lần mở rộng. Không có mốc chỉ cần trồng một cây, mở màn hình hoặc bấm một lần.

## Các mốc chính

| Nhóm | Ngưỡng |
|---|---|
| Loài cây đã sưu tầm | 25 / 55 / 80 |
| Mẫu chậu đã sưu tầm | 25 / 55 / 80 |
| Vật trang trí | 4 / 15 / 30 / 50 |
| Động vật trong vườn | 2 / 8 / 16 / 25 |
| Loài cây từng trưởng thành, cấp ≥ 3 | 5 / 15 / 30 / 55 / 80 |
| Cấp cao nhất của một cây | 10 / 25 / 50 / 100 / 150 / 200 |
| Cấp người chơi | 20 / 50 / 100 / 200 |
| Chỉ số tầng kệ `userFloor` | 5 / 10 / 20 |
| Ngày ghé vườn, không cần liên tiếp | 7 / 30 / 60 / 90 / 180 / 365 |
| Thu hoạch oxy thành công, gồm tự động | 1.000 / 10.000 / 100.000 / 1.000.000 lần |
| Tổng oxy thu hoạch từ cây | 100.000 / 1 triệu / 10 triệu / 100 triệu |
| Tưới cây / bón phân | 25 / 100 / 500 lần mỗi loại |
| Tạo mưa hoặc gió | 10 / 50 / 200 lần |
| Vườn khác đã ghé / đã thích | 10 / 50 / 100 vườn khác nhau |
| Lượt thích nhận được | 25 / 100 / 500 |
| Trồng cây mới | 25 / 100 / 500 lần |
| Số cây cùng có trong vườn | 9 / 18 / 36 |

**Theo lựa chọn phát hành:** cả mốc 25, 55 và 80 đều được hiển thị ngay. Danh mục hiện tại có 31 loài cây và 31 mẫu chậu nên mốc 55/80 chỉ đạt được sau các bản cập nhật bổ sung nội dung. Không hạ điều kiện của các ID này sau khi đã phát hành.

## Cấu hình trên Apple

Phần code và tệp chuẩn bị đã có trong repository; các mục dưới đây **chưa được tạo hay gửi duyệt trong tài khoản Apple**.

1. Mở target iOS → Signing & Capabilities, kiểm tra Game Center. Entitlement và capability đã thêm vào project; App ID/provisioning profile trên Apple cũng cần hỗ trợ Game Center.
2. Trong App Store Connect → ứng dụng → Game Center, tạo 60 achievement theo `app-store-connect.csv`. CSV là bảng tham chiếu/đầu vào cho công cụ API riêng; App Store Connect không được giả định có nút nhập CSV này.
3. Giữ đúng `achievementID`, đặt 10 điểm/mục, Hidden = No, Achievable More Than Once = No. Thêm localization vi / en-US, tên, mô tả trước và sau khi đạt; ảnh tương ứng ở `Badges/`.
4. Mỗi ảnh PNG là 1024 × 1024, RGB không alpha, 72 ppi. Các ảnh này chỉ dùng cho App Store Connect, không đưa vào runtime asset catalog của game.
5. Bật Game Center cho phiên bản phát hành, gắn các thành tích vào phiên bản và gửi Apple review. Có thể khai báo/test cục bộ bằng cấu hình GameKit của Xcode trước khi phát hành.
6. Trên thiết bị, mở menu khu vườn → **Thành tích** → **Kết nối Game Center**. Kiểm tra màn hình Apple, cập nhật phần trăm và banner khi hoàn tất bằng tài khoản thử nghiệm.

Apple giới hạn 100 thành tích, 100 điểm/mục và tổng 1.000 điểm. Yêu cầu ảnh hiện tại là 1024 × 1024 RGB, tối thiểu 72 ppi. Nguồn: [GameKit achievements](https://developer.apple.com/documentation/gamekit/rewarding-players-with-achievements), [App Store Connect achievement properties](https://developer.apple.com/help/app-store-connect/reference/game-center/achievements/).

## Hoạt động và lưu tiến độ

- Chỉ chủ vườn đang đăng nhập Firebase mới được ghi thành tích. Thành tích Game Center thuộc tài khoản Apple, độc lập với cách đăng nhập Firebase. Khi một tài khoản Game Center dùng nhiều khu vườn, các huy hiệu Apple đã đạt vẫn thuộc tài khoản Game Center đó.
- Liên kết mỗi khu vườn với một `gamePlayerID` bằng Firestore transaction trước khi gửi lên Apple. Nếu đổi sang tài khoản Game Center khác, dừng gửi và hiển thị thông báo. Ngắt kết nối chỉ tắt đồng bộ, không xóa huy hiệu Apple hoặc tiến độ.
- Tiến độ local lưu riêng theo Firebase UID trong UserDefaults, đồng bộ vào `users/{uid}.achievementProgress`; ID Apple liên kết nằm ở `achievementGameCenterPlayerID`. Các lần lưu khu vườn cũ dùng merge nên không ghi đè hai field này.
- Bộ đếm tách theo installation UUID: merge max cho cùng thiết bị, cộng giữa các thiết bị; tập hợp ID và giá trị cao nhất cũng chỉ tăng. Retry transaction hoặc nhận snapshot cũ không cộng trùng. Cài lại app nhận UUID mới, rồi hợp nhất lịch sử cloud.
- Gộp ghi local trong 1 giây và ghi cloud trong cửa sổ 15 giây. Khi app chuyển nền, lưu local ngay. Đổi tài khoản hủy tác vụ chờ, vô hiệu callback cũ và nạp đúng bộ nhớ theo UID. Lỗi cloud giữ tiến độ trên máy; thử lại khi tiếp tục chơi, trở lại foreground hoặc bấm đồng bộ lại.
- Báo Apple theo lô, phần trăm nguyên, tối đa khoảng một lần mỗi 10 giây khi tiến độ thay đổi. Tải tiến độ Apple trước và chỉ báo tăng. Chỉ gửi ID Apple thực sự đã cấu hình; các mục chưa cấu hình vẫn xem tiến độ được trong app và có thông báo kết nối.
- Collection/cấp độ/cây trưởng thành/lượt thích hiện có được ghi nhận ngay. Tổng oxy, số lần thu hoạch, tưới, bón phân, thời tiết, trồng mới, ngày ghé vườn và các vườn đã ghé/thích bắt đầu đếm từ khi có hệ thống; không suy đoán lịch sử từ số dư ví. Nhổ cây, đổi chậu hay di chuyển cây không làm lùi tiến độ.
- Theo dõi oxy thực nhận từ thu hoạch thành công, gồm thu hoạch tự động; không tính oxy mua, quà thưởng hoặc số dư. Thao tác bị từ chối/hủy không tăng bộ đếm chăm sóc.
- Lưu ID vườn khác trong lịch sử ghé/thích để không đếm lặp. Nếu Firestore rules dùng danh sách field được phép sửa, cần bổ sung hai field thành tích cho chủ vườn. Không cấp quyền ghi cho khách.
- Chưa thêm thưởng oxy/gem từ thành tích; Game Center points là điểm huy hiệu, không phải tiền trong game.
- Danh mục Apple xuất vi/en-US; danh mục trong app dùng vi hoặc English cho các ngôn ngữ khác. Các nút/trạng thái giao diện có bản dịch trong 5 ngôn ngữ của app.

## Mở rộng về sau

Nguồn duy nhất của danh mục là `Apps/Modules/Achievements/AchievementCatalog.swift`.

1. Thêm mốc cao hơn vào cuối nhóm hoặc thêm nhóm metric mới; ID có dạng `terrarium.achievement.<metric>.<target>`, không phụ thuộc thứ tự hiển thị.
2. Giữ nguyên ID/điều kiện/điểm/tên cấp của mốc đã phát hành. Không chèn mốc thấp vào giữa khiến tên cấp của các mục cũ thay đổi. Bộ đếm vẫn ghi nhận vượt ngưỡng hiện tại để các mốc mở rộng nhận lại tiến độ đã tích lũy.
3. Với metric hoàn toàn mới, thêm hook tại thao tác thành công. Với số liệu chưa từng lưu, phải ghi rõ thời điểm bắt đầu đếm.
4. Chạy `python3 scripts/export_game_center.py` để sinh lại JSON, bảng CSV, danh mục Markdown và ảnh huy hiệu từ cùng nguồn Swift.
5. Kiểm tra bằng `python3 scripts/check_achievements.py`, `swiftc -parse` và `git diff --check`. Script kiểm tra chỉ chạy logic Foundation/XCTest trên macOS; không build app hay mở simulator. Khi mở rộng danh mục, cập nhật kiểm tra số mốc/điểm dự phòng theo kế hoạch phát hành mới.
6. Cấu hình ID mới trên Apple trước khi phát hành app có mốc mới. Không vượt phần dự phòng 40 mục / 400 điểm. Có thể dùng phần dự phòng cho nhạc/phong cảnh, giấc ngủ hoặc sự kiện theo mùa khi có logic đếm tương ứng.

## Kiểm tra thiết bị còn cần thực hiện

Xác thực/hủy xác thực, tài khoản Game Center bị giới hạn, đổi Firebase/Apple ID, tắt mạng rồi mở lại, dùng hai thiết bị cùng vườn, các ID chưa cấu hình, tiến độ 99 → 100%, nhận banner đúng một lần và quay về game từ giao diện Apple. Chạy các kiểm tra này sau khi cấu hình Apple và có provisioning phù hợp; không thể xác nhận end-to-end chỉ bằng parse Swift.
