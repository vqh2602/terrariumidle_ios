# Giấc ngủ trong Góc vườn

Mở **Góc vườn → Giấc ngủ**. Màn hình dùng `AccountStyle`/`AccountPanel` hiện có, nền kem và xanh lá, có biểu đồ ngày/tuần/tháng và lịch lá thể hiện các ngày đạt mục tiêu.

## Luồng dữ liệu

- Yêu cầu quyền đọc và ghi `sleepAnalysis` khi bấm kết nối. Ghi chỉ áp dụng cho bản ghi người dùng chọn xuất; hoàn thành hộp thoại không có nghĩa đã được cấp quyền đọc/ghi.
- Có thể ghi thủ công không cần kết nối Health: giờ bắt đầu/kết thúc thực tế (không tương lai, tối đa 24h), cảm nhận sau khi thức dậy. Lưu JSON cục bộ với complete file protection, loại khỏi backup, không gửi lên Firebase. Nhật ký thuộc thiết bị, không theo tài khoản game.
- Mỗi bản ghi có lựa chọn xuất riêng. Khi xuất thất bại, giữ bản ghi và lựa chọn để thử lại khi đồng bộ. Nút “Đồng bộ nhật ký thủ công” chọn xuất tất cả bản ghi hiện có. Bản ghi xuất dùng `asleepUnspecified`, metadata user-entered và sync identifier UUID/version ổn định để thử lại không nhân đôi mẫu HealthKit. Không tự suy đoán stage.
- Health và nhật ký cục bộ được hợp nhất khoảng thời gian trước khi cộng; cả hai nguồn được dùng cho mục tiêu/phần thưởng theo quy tắc hiện có. Nếu truy vấn Health thất bại, chỉ bỏ dữ liệu Health cũ và giữ nhật ký cục bộ.
- Lịch ngủ trong app mặc định tắt, có giờ ngủ/thức hằng ngày và tùy chọn thông báo cục bộ. Không thay đổi Sleep Focus/lịch Health, không tự ghi giấc ngủ, không phải báo thức. Chỉ yêu cầu quyền thông báo khi bật nhắc nhở. Tắt lịch/nhắc nhở sẽ gỡ đúng hai thông báo của module.
- Biểu đồ ngày/tuần/tháng dùng dữ liệu hợp nhất; so sánh trung bình kỳ trước chỉ tính ngày có dữ liệu, kỳ đang diễn ra so cùng số ngày đã qua. Đánh giá dựa mục tiêu cá nhân và cảm nhận, không suy luận chất lượng/y khoa từ thời lượng.
- Xin quyền khi người dùng bấm kết nối. `hasRequestedAccess` chỉ ghi nhận đã hoàn thành luồng xin quyền; không đại diện cho quyền đọc đã được cấp. HealthKit không tiết lộ trạng thái từ chối đọc.
- Tự đọc lại khi app hoạt động, khi mở màn hình và khi kéo làm mới. Lấy khoảng một năm gần nhất; không gửi mẫu, thời lượng hay giai đoạn ngủ lên Firebase, không lưu mẫu HealthKit vào UserDefaults; nhật ký thủ công lưu riêng trên thiết bị.
- Chỉ tính `asleepUnspecified/core/deep/REM`, bỏ `inBed` và `awake`. Hợp nhất các khoảng chồng nhau trước khi cộng để không cộng trùng nhiều nguồn.
- Ngày thống kê là cửa sổ 12h trưa hôm trước → 12h trưa ngày ghi nhận, theo lịch/múi giờ thiết bị, giữ đêm qua nửa đêm trong một cột. Khoảng ngủ cắt tại biên trưa; dùng phép cộng ngày của Calendar để hỗ trợ DST.
- Không có dữ liệu được hiển thị là thiếu dữ liệu, không kết luận người dùng không ngủ hay đã từ chối quyền. Lỗi đọc sẽ bỏ dữ liệu Health đang hiển thị để không nhận quà từ kết quả Health cũ; nhật ký thủ công vẫn được giữ.

## Thưởng

- Mục tiêu mặc định 8h, điều chỉnh 6–10h, bước 30 phút; đây là mục tiêu trong game, không phải tư vấn sức khỏe.
- Đạt mục tiêu nhận 1.000 Oxy, mỗi ngày một lần, nhận bù hôm nay và 6 ngày trước. Đổi mục tiêu không xóa dấu đã nhận. Không thưởng nhiều hơn khi ngủ lâu hơn, không phạt ngày thiếu ngủ.
- Mỗi 7 ngày liên tiếp đạt mục tiêu nhận 10 gem; chuỗi dài có thể nhận tiếp sau mỗi 7 ngày, không dùng lại ngày đã thưởng tuần. Đạt mục tiêu trọn tháng dương lịch (28/29/30/31 ngày) nhận 20 gem + 1 ticket. Mốc tuần và tháng cộng dồn với thưởng ngày, không yêu cầu mở app hoặc nhận thưởng mỗi ngày. Các mốc có cùng thời hạn nhận bù 7 ngày từ ngày hoàn thành.
- Cần tài khoản đã tải vườn và kết nối mạng để commit transaction. Receipt và cộng Oxy được ghi cùng transaction vào `users/{uid}`: `sleepRewardDays.{yyyy-MM-dd}` (timestamp) và `sleepRewardOxygen` (tổng Oxy đã phát). Mốc tuần/tháng lưu trong `sleepRewardMilestones`; `sleepRewardWeekDays` đánh dấu các ngày đã dùng cho thưởng tuần, chống dùng lại một phần chuỗi ở thiết bị khác. `sleepRewardGems` và `sleepRewardTickets` giữ tổng thưởng tương ứng. Không có thời lượng ngủ trong receipt.
- Các lần lưu vườn được xếp hàng với transaction thưởng. Model giữ tổng credit đã phản ánh vào ví; transaction lưu vườn bù credit mới hơn snapshot để một lần lưu chậm không xóa phần thưởng vừa phát. Vì vậy lưu vườn hiện có thêm một lần đọc transaction và cần mạng để hoàn tất; UI tap vẫn cập nhật local ngay theo luồng hiện tại.
- Transaction chống nhận trùng theo tài khoản trên các thiết bị. Kiểm tra điều kiện giấc ngủ đang ở client; không phải hệ thống chống sửa app. Nếu cần nền kinh tế chống gian lận, phải có thiết kế backend riêng, không gửi dữ liệu HealthKit thô lên server để mặc định xác thực.

## Cấu hình và kiểm tra

Đã thêm HealthKit capability/entitlement và `NSHealthShareUsageDescription`/`NSHealthUpdateUsageDescription`. App ID/provisioning profile dùng để ký bản chạy phải hỗ trợ HealthKit. Firebase rules của môi trường triển khai cần cho chủ tài khoản đọc/cập nhật các trường thưởng trên document của chính họ; không mở quyền cho khách.

`SleepRewardRulesTests.swift` kiểm tra mức thưởng, chuỗi bị ngắt, lặp tuần không chồng, tháng 28/29/30/31 ngày, cộng dồn và mốc hết hạn. `SleepSummaryTests.swift` kiểm tra chồng nguồn, khoảng thức giấc, nhận bù 7 ngày, DST và biên trưa. Có thể chạy riêng phần logic Foundation mà không build app. Parse Swift/plist và kiểm tra diff không thay cho chạy trên iPhone.

Kiểm tra trên thiết bị thật trước phát hành:

1. Có/không cấp quyền, có/không có dữ liệu; quay lại từ Apple Health tự đồng bộ.
2. Nhận quà, mở lại app, đổi mục tiêu, cập nhật bản ghi: cùng ngày không được nhận lần hai.
3. Mất mạng khi nhận, bấm thử lại; hai thiết bị cùng tài khoản nhận cùng ngày.
4. Nhận thưởng trong lúc có cập nhật vườn đang chờ, xác nhận số Oxy sau tải lại.
5. Nhập thủ công khi chưa kết nối, tắt lựa chọn xuất rồi kết nối lại (không được tự xuất), từ chối ghi, thử lại sau khi cấp quyền; khoảng chồng Health/thủ công không cộng hai lần.
6. Bật/tắt lịch và nhắc nhở, đổi giờ, từ chối thông báo; xác nhận các thông báo khác không bị xóa.
7. Biểu đồ/lịch trên màn hình nhỏ và cỡ chữ trợ năng.

Tham chiếu: [HealthKit authorization](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data), [sleep analysis values](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis).
