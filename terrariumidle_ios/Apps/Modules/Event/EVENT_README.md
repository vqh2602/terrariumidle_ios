# Event WebView

`EventView` tải feed dữ liệu từ xa `event_terrarium.json`. Các thẻ sự kiện ưu tiên hiển thị theo ngôn ngữ thiết bị, mặc định fallback về tiếng Anh và hiển thị feed theo thứ tự đảo ngược (mới nhất lên đầu). Ngày bắt đầu/kết thúc được tính bao gồm cả hai đầu ngày. Các sự kiện đã kết thúc, sắp diễn ra hoặc không tương thích phiên bản vẫn được hiển thị nhưng sẽ không thể mở.

Ba liên kết legacy được ánh xạ tới các trang web đang lưu trữ:

| Feed link | Trang web | JavaScript handler |
| --- | --- | --- |
| `clam-level-up` | `event_level_terrarium/index.html` | `event_get_bag_level` |
| `clam-floor` | `events_floors/index.html` | `event_get_bag_floor` |
| `clam-lavender-plant` | `lucky-wheel/index.html` | `clam-lavender-plant` |

Các liên kết HTTPS thông thường mở trong WKWebView không gắn handler nhận thưởng. Các liên kết dẫn đến host khác sẽ được mở bằng trình duyệt ngoài (Safari).

Ứng dụng cung cấp đối tượng `window.TerrariumBridge`. Trang web phải sử dụng API này:

```javascript
await window.TerrariumBridge.callHandler('event_get_bag_level', 'true');
await window.TerrariumBridge.callHandler('event_get_bag_floor', 'true');
await window.TerrariumBridge.callHandler('clam-lavender-plant', {code: 'ticket'});
```

Ứng dụng phát sự kiện `TerrariumBridgeReady` khi bridge được cài đặt sẵn sàng vào trang. API cũ `window.flutter_inappwebview` không còn được cung cấp; các trang web được lưu trữ cần chuyển sang API mới để các callback nhận thưởng hoạt động trên iOS.

Bridge trả về một Promise và chỉ chấp nhận các cuộc gọi từ đúng host HTTPS của main-frame, đường dẫn trang và event handler tương ứng. Mã nguồn native thực hiện kiểm tra nghiêm ngặt về ngày diễn ra, phiên bản ứng dụng, trạng thái đăng nhập, điều kiện cấp độ/số tầng, quyền sở hữu hiện tại và số dư oxy. Số lượng phần thưởng và các mã hỗ trợ được định nghĩa trong `EventReward`, khớp với giá trị thưởng hiện tại của vòng quay may mắn. Mọi số lượng tuỳ ý gửi lên từ JavaScript đều bị bỏ qua. Vòng quay tiêu tốn 100 oxy cho mỗi callback nhận thưởng được chấp thuận.

Firestore phải xác nhận việc ghi dữ liệu thành công trước khi Promise được giải quyết (resolve) và cập nhật state cục bộ. Nếu thất bại, Promise sẽ bị từ chối (reject) và hiển thị thông báo trạng thái native. Nhận thưởng thành công sẽ cập nhật lại query parameters của trang và giá trị oxy của vòng quay. Việc nhận huy hiệu được chống trùng lặp dựa trên quyền sở hữu; các yêu cầu nhận thưởng đồng thời hoặc callback vòng quay trong vòng 2 giây kể từ lần nhận gần nhất sẽ bị từ chối.

Trang web hiện tại tự chọn kết quả vòng quay ở phía client. Bridge này duy trì nguyên vẹn quy ước đó; bridge không cung cấp cơ chế chọn phần thưởng kiểm soát từ server (server-authoritative) hay giao dịch nhận thưởng liên thiết bị. Khi có thay đổi trong danh mục giải thưởng trên web, chính sách phần thưởng native cũng phải được cập nhật đồng thời.
