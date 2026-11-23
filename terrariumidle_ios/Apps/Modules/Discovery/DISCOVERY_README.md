# Khám phá khu vườn

Menu `Khám phá` mở danh sách thế giới, tìm kiếm chính xác theo ID người chơi, top lượt thích, top cấp độ và bảng xếp hạng thu thập oxy. Mỗi lần mở hoặc tải lại danh sách thế giới, app chọn một document-ID ngẫu nhiên làm điểm bắt đầu, lấy tối đa 30 tài liệu rồi trộn thứ tự. Phân trang đi tới cuối collection, quay về đầu một lần và dừng ở điểm bắt đầu để tránh lặp; các bảng xếp hạng vẫn đọc 10 tài liệu theo thứ tự xếp hạng. Cơ chế này khắc phục nhược điểm của bản Flutter cũ (tải toàn bộ collection và lỗi lấy ngẫu nhiên khi hệ thống có ít hơn 30 người dùng).

## Tách biệt hoàn toàn với khu vườn của người dùng (Owner's garden)

- `DiscoveryRepository` triển khai protocol chỉ đọc `DiscoveryReading`. Repository chỉ đọc từ collection `users` và `rankings`, hoàn toàn không lắng nghe realtime, không ghi dữ liệu, không đăng xuất, và không phụ thuộc vào `FireStoreService`.
- `DiscoveredProfile` và `VisitorGarden` chỉ chứa các trường hiển thị công khai. Các model này lược bỏ email, tiền tệ, túi đồ và công cụ. Kiểu dữ liệu của chúng không thể truyền vào các phương thức lưu dữ liệu người dùng hiện có. Firestore vẫn trả về toàn bộ document theo schema hiện hành; quyền truy cập hồ sơ công khai ở phía server tiếp tục được kiểm soát bởi Firestore rules của dự án.
- Mỗi màn hình ghé thăm sở hữu ViewModel và snapshot độc lập. Cơ chế kiểm tra huỷ bỏ (cancellation) và thế hệ yêu cầu (generation) ngăn chặn phản hồi cũ đè lên lượt ghé thăm mới hơn. Mọi lỗi tải dữ liệu được cô lập trong màn hình khách ghé thăm.
- Màn hình khách ghé thăm hiển thị trực tiếp `TerrariumSlotView`/`SpriteKitStickerView` mà không gắn callback tính toán kinh tế. Màn hình không khởi tạo `HomeView`, `PlantItemView`, các sheet chỉnh sửa của chủ vườn, HUD, hay bộ điều khiển âm nhạc. Thao tác chạm chỉ kích hoạt chuyển động sprite. Nút Thích sử dụng service riêng, chỉ cập nhật trường `user.userTotalLike` của vườn đích; không lưu lại snapshot vườn khách.
- Các view hiện tại của chủ vườn, cơ chế lưu trữ (persistence), tác vụ lưu đang chờ, đăng ký realtime, hình nền và cài đặt âm nhạc hoàn toàn không bị ảnh hưởng bởi tính năng này.

Document ID đóng vai trò là định danh đích khi ghé thăm, bất kể trường `userID` legacy bên trong có bị thiếu hay không khớp. Các vị trí không hợp lệ sẽ bị bỏ qua; nếu trùng ô (slot), ưu tiên bản ghi đầy đủ cây lẫn chậu và có cấp độ cao hơn. Cấp độ hiển thị được giới hạn trong khoảng 1...10 và số tầng (hàng) từ 0...500 mà không làm biến đổi document đã lưu trên cơ sở dữ liệu. Các asset legacy chưa hỗ trợ sẽ hiển thị thumbnail từ danh mục hoặc placeholder thay vì tự ý thay thế bằng cây/chậu khác. Các sprite hỗ trợ giữ nguyên tỷ lệ chiều cao kệ 1.95 và căn chỉnh chậu treo hiện hành.

Bộ kiểm thử (Tests) bao quát các trường hợp phân tích dữ liệu công khai, ô không hợp lệ/trùng lặp, loại trừ chủ vườn khỏi danh sách, phân trang, tìm kiếm/xử lý lỗi, phản hồi đến muộn và huỷ tác vụ (cancellation). Khi gặp lỗi quyền mạng, giao diện hiển thị trạng thái cho phép thử lại và tuyệt đối không làm đăng xuất người dùng hiện tại.


## Like và log Discord

- `GardenLikeService` dùng transaction để đọc lượt thích mới nhất và chỉ cập nhật `user.userTotalLike`. Hỗ trợ giá trị legacy dạng chuỗi số; chặn tự like, chặn yêu cầu đồng thời và chỉ ghi nhận thành công sau khi Firestore xác nhận.
- Biên nhận like được lưu theo cặp tài khoản khách/chủ vườn trong UserDefaults. Mỗi cặp chỉ được like một lần trên thiết bị này, kể cả khi đóng/mở lại màn hình. Đây là chống lặp trên thiết bị, không phải cơ chế chống gian lận xuyên thiết bị ở server.
- Luồng lưu vườn nhà bỏ trường `user.userTotalLike` khỏi payload merge để snapshot cũ không ghi đè lượt thích người khác vừa gửi. Các trường cây, tiền tệ và túi đồ tiếp tục dùng luồng lưu hiện có.
- Sau khi like thành công, `GardenLikeReporter` tạo `Documents/text_file_<viewerID>.txt` chứa ID người gửi, ID vườn được thích và tổng lượt thích mới. File được gửi bằng multipart tới webhook đã cấu hình, loại `like`; không gửi email, tiền tệ hay nội dung vườn.
- Log chờ gửi được lưu bền vững. Nếu Discord lỗi, app giữ log để thử lại khi ghé thăm/lượt thích tiếp theo; việc gửi lại log không cộng thêm lượt thích. Việc Discord nhận log nhưng mất phản hồi mạng có thể làm log xuất hiện lặp khi thử lại.
- Đóng màn hình ghé thăm giữ nguyên danh sách, thứ tự, phân trang, tab, tìm kiếm và vị trí cuộn. Like thành công cập nhật riêng thẻ tương ứng qua callback, không tải lại hoặc sắp xếp lại danh sách. Chỉ tạo nhóm ngẫu nhiên mới khi vào lại màn hình Khám phá hoặc chủ động tải lại; task xuất hiện lại dùng kết quả đã tải cho cùng request key.

Thay đổi này chưa chạy build/test và chưa gửi thử webhook theo yêu cầu làm trực tiếp của người dùng.
