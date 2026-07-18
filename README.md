# Tài liệu dự án Hotel System Management

## 1. Tổng quan

**Hotel System Management** là hệ thống quản lý khách sạn gồm:

- Ứng dụng Flutter cho khách hàng, nhân viên và quản trị viên.
- REST API Node.js/Express xử lý nghiệp vụ và truy cập dữ liệu.
- PostgreSQL lưu người dùng, phòng, booking, dịch vụ, thanh toán, hóa đơn, khuyến mãi và đánh giá.
- PayOS cung cấp thanh toán QR.
- Google Sign-In cung cấp đăng nhập Google.
- Docker Compose, Nginx và GitHub Actions hỗ trợ chạy và triển khai backend.

Thông tin phiên bản Flutter:

| Thuộc tính | Giá trị |
| --- | --- |
| Package | `hotel_system_management` |
| Phiên bản | `0.1.0+1` |
| Dart SDK | `^3.11.5` |
| Giao diện | Material Design |
| Nền tảng có cấu hình trong repo | Android |
| Ngôn ngữ giao diện | Tiếng Anh, Tiếng Việt |

Thông tin backend:

| Thuộc tính | Giá trị |
| --- | --- |
| Package | `hotel-api` |
| Phiên bản | `1.0.0` |
| Runtime | Node.js `>=18.0.0` |
| Framework | Express `4.x` |
| Database | PostgreSQL 15 |
| Cổng mặc định | `5000` |

## 2. Mục tiêu hệ thống

Hệ thống phục vụ ba nhóm người dùng:

1. **Khách hàng** tìm phòng, xem lịch trống, đặt phòng, chọn dịch vụ, áp dụng khuyến mãi, thanh toán, quản lý booking và đánh giá.
2. **Nhân viên** theo dõi phòng, dịch vụ, khuyến mãi, doanh thu ngày và đánh giá.
3. **Quản trị viên** quản lý toàn bộ dữ liệu vận hành của khách sạn.

## 3. Vai trò và phân quyền hiện tại

### 3.1. Khách hàng

Khách hàng đăng nhập bằng email/mật khẩu hoặc Google. Sau khi đăng nhập, ứng dụng mở `MainShell` gồm ba tab:

- Trang chủ.
- Booking của tôi.
- Hồ sơ.

### 3.2. Nhân viên

Tài khoản backend có `is_staff = true` được chuyển đến `StaffHomeScreen`. Nhân viên có các tác vụ:

- Xem thông tin và trạng thái phòng.
- Quản lý dịch vụ.
- Quản lý mã giảm giá.
- Xem doanh thu theo ngày.
- Xem và chỉnh sửa đánh giá.

### 3.3. Quản trị viên

Quản trị viên hiện là tài khoản cục bộ, không truy vấn database:

```text
Tài khoản: admin
Mật khẩu: 12345678
```

Sau đăng nhập, ứng dụng mở `AdminScreen` với các chức năng:

- Quản lý nhân viên.
- Quản lý khách hàng.
- Quản lý phòng.
- Quản lý loại phòng.
- Quản lý booking.
- Quản lý dịch vụ.
- Quản lý khuyến mãi.
- Xem doanh thu và hóa đơn.

> Tài khoản trên chỉ phù hợp cho demo/phát triển vì thông tin đăng nhập được viết trực tiếp trong mã nguồn Flutter.

## 4. Chức năng chính

### 4.1. Xác thực và tài khoản

- Đăng ký khách hàng.
- Đăng nhập khách hàng bằng email và mật khẩu.
- Đăng nhập nhân viên bằng email và mật khẩu.
- Đăng nhập khách hàng bằng Google ID token.
- Ghi nhớ phiên bằng `SharedPreferences`.
- Xác thực OTP sau đăng nhập bằng mật khẩu.
- Quên mật khẩu, tìm tài khoản theo email và đặt mật khẩu mới.
- Đăng xuất và xóa phiên cục bộ.
- Tự động khôi phục màn hình theo vai trò khi mở lại ứng dụng.

### 4.2. Trang chủ khách hàng

- Tải danh sách phòng đang hoạt động từ backend.
- Tải ảnh minh họa phòng từ Unsplash.
- Tìm kiếm theo số phòng, loại phòng hoặc trạng thái.
- Lọc theo loại phòng, giá và tình trạng phòng.
- Xem thông tin phòng, giá, sức chứa, số giường và mô tả.
- Chuyển đến màn hình chi tiết phòng.

### 4.3. Chi tiết và lịch phòng

- Tải chi tiết phòng, loại phòng, dịch vụ và đánh giá.
- Tải các khoảng ngày đã được đặt.
- Hiển thị lịch chọn ngày với ngày bận được đánh dấu.
- Không cho chọn khoảng ngày giao với booking đang giữ chỗ hoặc còn hiệu lực.
- Cho phép ngày check-out của booking trước trùng ngày check-in của booking sau.
- Chọn số khách theo sức chứa phòng.
- Chọn các dịch vụ đi kèm.
- Kiểm tra điều kiện đánh giá dựa trên booking của khách hàng.

### 4.4. Hồ sơ và căn cước công dân

- Xem và cập nhật email, họ tên, số điện thoại, địa chỉ, ngày sinh.
- Tải ảnh mặt trước và mặt sau căn cước công dân.
- Xem, thay thế hoặc xóa từng ảnh.
- Chọn ảnh bằng `image_picker`.
- Backend chỉ cho tạo booking khi khách hàng đã tải đủ hai mặt.

### 4.5. Booking

- Tạo booking một hoặc nhiều phòng ở tầng backend.
- Lưu ngày nhận phòng, trả phòng, số khách và số đêm.
- Gắn dịch vụ và số lượng dịch vụ.
- Áp dụng mã khuyến mãi còn hiệu lực.
- Kiểm tra sức chứa.
- Kiểm tra trạng thái vận hành của phòng.
- Khóa bản ghi phòng và kiểm tra xung đột trong transaction.
- Trả HTTP `409` khi khoảng ngày bị trùng.
- Tạo trạng thái `pending_payment` trong thời gian chờ thanh toán.
- Xem danh sách booking của tài khoản hiện tại.

### 4.6. Giá và khuyến mãi

Backend tính giá theo công thức:

```text
roomTotal = tổng giá phòng theo số đêm
serviceTotal = tổng giá dịch vụ theo số lượng
subtotal = roomTotal + serviceTotal
discountAmount = phần trăm giảm trên room, service hoặc toàn invoice
taxableAmount = subtotal - discountAmount
vatAmount = taxableAmount * 10%
finalAmount = taxableAmount + vatAmount
```

Phạm vi khuyến mãi:

- `room`: chỉ giảm tiền phòng.
- `service`: chỉ giảm tiền dịch vụ.
- `invoice`: giảm toàn bộ giá trị trước VAT.

### 4.7. Thanh toán PayOS

Luồng thanh toán:

1. Flutter gửi yêu cầu tạo booking.
2. Backend kiểm tra khách hàng, CCCD, phòng, ngày, khách, dịch vụ và khuyến mãi.
3. Backend tạo booking `pending_payment` và payment `pending`.
4. Backend yêu cầu PayOS tạo payment link và QR.
5. Flutter hiển thị QR và kiểm tra trạng thái thanh toán định kỳ.
6. Webhook hoặc tác vụ đồng bộ xác nhận thanh toán.
7. Backend đổi payment thành `paid`, booking thành `confirmed`.
8. Backend tạo hóa đơn.
9. Nếu hết thời gian, payment và booking được chuyển thành `cancelled`.

Backend đồng bộ tối đa 100 payment đang chờ trong mỗi lượt. Chu kỳ lấy từ `PAYMENT_CHECK_INTERVAL_SECONDS`.

### 4.8. Hóa đơn

- Hóa đơn được tạo tự động sau khi thanh toán thành công.
- Lưu tiền phòng, dịch vụ, giảm giá, VAT, tổng tiền và phương thức thanh toán.
- Khách hàng có thể tạo và tải file PDF hóa đơn.
- Font Unicode của PDF được tải từ kho Google Fonts khi cần.

### 4.9. Đánh giá

- Lấy đánh giá theo phòng.
- Kiểm tra khách hàng có booking phù hợp hay không.
- Chỉ booking `confirmed` hoặc `completed` mới đủ điều kiện theo API hiện tại.
- Thêm, sửa và xóa đánh giá.
- Rating được giới hạn từ 1 đến 5 tại database.

### 4.10. Báo cáo

- Báo cáo doanh thu tổng hợp.
- Doanh thu theo ngày.
- Doanh thu theo tháng.
- Doanh thu theo năm.
- Thống kê số booking theo trạng thái.
- Dashboard quản trị hiển thị chi tiết hóa đơn và cơ cấu chi phí.

### 4.11. Đa ngôn ngữ

- Hỗ trợ locale `en` và `vi`.
- Locale được lưu bằng `SharedPreferences`.
- Phần khách hàng đã dùng lớp `AppLocalizations`.
- Một số màn hình quản trị và nhân viên vẫn dùng chuỗi tiếng Việt trực tiếp.

## 5. Kiến trúc hệ thống

```text
+---------------------------+
| Flutter Application       |
| Customer / Staff / Admin  |
+-------------+-------------+
              |
              | HTTP/JSON
              v
+---------------------------+
| Node.js + Express API     |
| Controllers / Services    |
+------+------+-------------+
       |      |
       |      +--------------------+
       |                           |
       v                           v
+-------------+             +-------------+
| PostgreSQL  |             | PayOS       |
| Port 5432   |             | Payment API |
+-------------+             +-------------+
       ^
       |
+------+--------------------+
| Scheduler / Webhook       |
+---------------------------+

Flutter còn kết nối trực tiếp đến:
- Google Sign-In để lấy ID token.
- Unsplash để lấy ảnh phòng.
- Dịch vụ OTP riêng để gửi và xác thực OTP.
- Google Fonts GitHub để tải font tạo PDF.
```

### 5.1. Kiến trúc Flutter

Flutter đang dùng cấu trúc kết hợp theo feature và theo tầng:

```text
lib/
|-- main.dart
|-- core/
|   |-- const/          # Endpoint dùng chung
|   |-- localization/   # Đa ngôn ngữ
|   |-- models/         # Model cho luồng khách hàng
|   |-- network/        # HTTP client
|   `-- theme/          # Theme và màu
|-- features/
|   |-- bookings/
|   |-- detail_rooms/
|   |-- forgot_password/
|   |-- home/
|   |-- login/
|   |-- navigation/
|   |-- otp/
|   |-- payment/
|   |-- profile/
|   `-- signup/
|-- models/             # Model cho admin/staff
|-- screens/            # Màn hình admin/staff
|-- services/           # CRUD service admin/staff
`-- utils/
```

Luồng khách hàng chủ yếu dùng `features/*/controller`. Luồng quản trị và nhân viên chủ yếu dùng `services/*` và `screens/*`.

### 5.2. Kiến trúc backend

```text
backend/
|-- .github/workflows/  # CI
|-- config/             # PostgreSQL pool
|-- controllers/        # Xử lý HTTP và nghiệp vụ
|-- deploy/             # Migration, Nginx, systemd auto-deploy
|-- docs/               # Thiết kế và kế hoạch kỹ thuật
|-- models/             # Model hỗ trợ
|-- routes/             # Khai báo REST route
|-- services/           # Availability, Google auth, payment
|-- test/               # Node test
|-- uploads/id-cards/   # Ảnh CCCD cục bộ
|-- utils/              # PayOS, pricing, scheduler, email
|-- hotel_management.sql
|-- server.js
|-- Dockerfile
|-- docker-compose.yml
`-- docker-compose.prod.yml
```

Thư mục `backend/` có Git repository riêng và đang bị bỏ qua bởi `.gitignore` của repository Flutter gốc.

## 6. Công nghệ và thư viện

### 6.1. Flutter

| Thư viện | Mục đích |
| --- | --- |
| `http` | Gọi REST API |
| `shared_preferences` | Lưu phiên và locale |
| `provider` | Quản lý/phân phối trạng thái |
| `qr_flutter` | Hiển thị QR thanh toán |
| `fl_chart` | Biểu đồ doanh thu |
| `google_sign_in` | Đăng nhập Google native |
| `google_sign_in_web` | Đăng nhập Google web |
| `pdf` | Sinh hóa đơn PDF |
| `file_saver` | Lưu file PDF |
| `image_picker` | Chọn ảnh CCCD |
| `flutter_localizations` | Đa ngôn ngữ Material |

### 6.2. Backend

| Thư viện | Mục đích |
| --- | --- |
| `express` | REST API |
| `pg` | Kết nối PostgreSQL |
| `cors` | Cho phép request khác origin |
| `dotenv` | Đọc biến môi trường |
| `google-auth-library` | Xác minh Google ID token |
| `multer` | Upload ảnh CCCD |
| `jsonwebtoken` | Có trong dependency, chưa được gắn vào route hiện tại |

PayOS được gọi bằng module HTTPS tự viết trong `backend/utils/payos.js`.

## 7. Cơ sở dữ liệu

Schema chính nằm tại `backend/hotel_management.sql`.

| Bảng | Vai trò |
| --- | --- |
| `Users` | Khách hàng và nhân viên, phân biệt bằng `is_staff` |
| `Room_Types` | Loại phòng |
| `Rooms` | Phòng, giá, sức chứa và trạng thái vận hành |
| `Services` | Dịch vụ khách sạn |
| `Promotions` | Mã giảm giá và phạm vi áp dụng |
| `Bookings` | Thông tin đặt phòng |
| `Booked_Rooms` | Quan hệ nhiều-nhiều giữa booking và phòng |
| `Payments` | Payment PayOS và thời hạn giữ chỗ |
| `Used_Services` | Dịch vụ được dùng trong booking |
| `Invoices` | Hóa đơn của booking |
| `Reviews` | Đánh giá phòng |
| `Room_Status_History` | Lịch sử đổi trạng thái phòng |

Quan hệ chính:

```text
Users 1 ----- n Bookings
Users 1 ----- n Reviews
Room_Types 1 ----- n Rooms
Bookings n ----- n Rooms         qua Booked_Rooms
Bookings n ----- n Services      qua Used_Services
Bookings 1 ----- 1 Payments
Bookings 1 ----- 1 Invoices
Bookings 1 ----- n Reviews
Rooms 1 ----- n Reviews
Rooms 1 ----- n Room_Status_History
Promotions 1 ----- n Bookings
Promotions 1 ----- n Invoices
```

Ràng buộc đáng chú ý:

- Email và username là duy nhất.
- Email có index duy nhất không phân biệt hoa thường.
- `check_out > check_in`.
- Rating từ 1 đến 5.
- Mỗi booking không được gắn trùng một phòng.
- Mỗi booking chỉ có một payment và một invoice.
- Số tiền payment phải lớn hơn 0.

File schema có dữ liệu mẫu để chạy thử. Các migration nâng cấp nằm trong `backend/deploy/`.

## 8. REST API

Base URL mặc định của Flutter:

```text
https://nationally-amused-horse.ngrok-free.app/api
```

Có thể ghi đè khi build:

```powershell
flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api
```

### 8.1. Staff

| Method | Endpoint | Chức năng |
| --- | --- | --- |
| `GET` | `/api/staff` | Danh sách nhân viên |
| `POST` | `/api/staff/login` | Đăng nhập nhân viên |
| `GET` | `/api/staff/:id` | Chi tiết nhân viên |
| `POST` | `/api/staff` | Tạo nhân viên |
| `PUT` | `/api/staff/:id` | Cập nhật nhân viên |
| `DELETE` | `/api/staff/:id` | Xóa nhân viên |

### 8.2. Customer

| Method | Endpoint | Chức năng |
| --- | --- | --- |
| `GET` | `/api/customers` | Danh sách khách hàng |
| `POST` | `/api/customers` | Đăng ký/tạo khách hàng |
| `POST` | `/api/customers/login` | Đăng nhập khách hàng |
| `POST` | `/api/customers/google` | Đăng nhập Google |
| `PUT` | `/api/customers/update-password` | Đặt mật khẩu mới |
| `GET` | `/api/customers/email/:email` | Tìm khách theo email |
| `GET` | `/api/customers/:id` | Chi tiết khách hàng |
| `PUT` | `/api/customers/:id` | Cập nhật khách hàng |
| `DELETE` | `/api/customers/:id` | Xóa khách hàng |
| `PUT` | `/api/customers/:id/id-card` | Upload ảnh CCCD |
| `GET` | `/api/customers/:id/id-card/:side` | Lấy ảnh CCCD |
| `DELETE` | `/api/customers/:id/id-card/:side` | Xóa một mặt CCCD |

### 8.3. Room và room type

| Method | Endpoint | Chức năng |
| --- | --- | --- |
| `GET` | `/api/rooms` | Danh sách phòng |
| `GET` | `/api/rooms/:id` | Chi tiết phòng |
| `GET` | `/api/rooms/:id/booked-ranges` | Khoảng ngày đã đặt |
| `POST` | `/api/rooms` | Tạo phòng |
| `PUT` | `/api/rooms/:id` | Cập nhật phòng |
| `PUT` | `/api/rooms/:id/status` | Đổi trạng thái phòng |
| `DELETE` | `/api/rooms/:id` | Xóa phòng |
| `GET` | `/api/room-types` | Danh sách loại phòng |
| `GET` | `/api/room-types/:id` | Chi tiết loại phòng |
| `POST` | `/api/room-types` | Tạo loại phòng |
| `PUT` | `/api/room-types/:id` | Cập nhật loại phòng |
| `DELETE` | `/api/room-types/:id` | Xóa loại phòng |

Query lịch phòng:

```http
GET /api/rooms/:id/booked-ranges?from=2026-08-01&to=2026-10-31
```

Khoảng lưu trú dùng quy ước nửa mở `[check_in, check_out)`.

### 8.4. Booking

| Method | Endpoint | Chức năng |
| --- | --- | --- |
| `GET` | `/api/bookings` | Danh sách booking |
| `GET` | `/api/bookings/user/:userId` | Booking của khách hàng |
| `GET` | `/api/bookings/:id` | Chi tiết booking |
| `POST` | `/api/bookings` | Tạo booking và payment hold |
| `PUT` | `/api/bookings/:id` | Cập nhật trạng thái/ngày |
| `DELETE` | `/api/bookings/:id` | Xóa booking và dữ liệu liên quan |

### 8.5. Dịch vụ, khuyến mãi và đánh giá

| Nhóm | Endpoint chính |
| --- | --- |
| Dịch vụ | CRUD `/api/services` |
| Khuyến mãi | CRUD `/api/promotions` |
| Kiểm tra mã | `GET /api/promotions/code/:code` |
| Đánh giá | CRUD `/api/reviews` |
| Đánh giá theo phòng | `GET /api/reviews/room/:roomId` |
| Quyền đánh giá | `GET /api/reviews/eligibility` |

### 8.6. Hóa đơn, báo cáo và thanh toán

| Method | Endpoint | Chức năng |
| --- | --- | --- |
| `GET` | `/api/invoices` | Danh sách hóa đơn |
| `GET` | `/api/invoices/:id` | Chi tiết hóa đơn |
| `POST` | `/api/invoices` | Tạo hóa đơn |
| `PUT` | `/api/invoices/:id` | Cập nhật hóa đơn |
| `DELETE` | `/api/invoices/:id` | Xóa hóa đơn |
| `GET` | `/api/reports/revenue` | Báo cáo doanh thu |
| `GET` | `/api/reports/revenue/day` | Doanh thu ngày |
| `GET` | `/api/reports/revenue/month` | Doanh thu tháng |
| `GET` | `/api/reports/revenue/year` | Doanh thu năm |
| `GET` | `/api/reports/stats` | Thống kê booking |
| `POST` | `/api/payments/payos/webhook` | Webhook PayOS |
| `GET` | `/api/payments/payos/return` | PayOS return URL |
| `GET` | `/api/payments/payos/cancel` | PayOS cancel URL |
| `GET` | `/api/payments/booking/:bookingId` | Trạng thái payment |

## 9. Cấu hình

### 9.1. Flutter dart-define

| Biến | Mục đích |
| --- | --- |
| `API_BASE_URL` | Base URL REST API |
| `GOOGLE_SERVER_CLIENT_ID` | OAuth server client ID |

Các endpoint khác đang được khai báo trực tiếp trong `ApiEndpoints`:

- Unsplash API.
- OTP service.
- Base URL mặc định.

`ApiClient` tự thêm header `ngrok-skip-browser-warning: true` cho domain Ngrok.

### 9.2. Backend environment

Tạo `backend/.env` từ `backend/.env.example`.

| Biến | Mục đích |
| --- | --- |
| `PORT` | Cổng API |
| `DB_USER` | PostgreSQL user |
| `DB_HOST` | PostgreSQL host |
| `DB_NAME` | Tên database |
| `DB_PASSWORD` | PostgreSQL password |
| `DB_PORT` | PostgreSQL port |
| `JWT_SECRET` | Secret dự kiến cho JWT |
| `GOOGLE_CLIENT_ID` | Audience dùng xác minh Google ID token |
| `EMAIL_USER` | Tài khoản email |
| `EMAIL_PASS` | Mật khẩu/app password email |
| `PAYOS_CLIENT_ID` | PayOS client ID |
| `PAYOS_API_KEY` | PayOS API key |
| `PAYOS_CHECKSUM_KEY` | Khóa xác minh chữ ký PayOS |
| `PAYOS_RETURN_URL` | URL trả về khi thanh toán |
| `PAYOS_CANCEL_URL` | URL trả về khi hủy |
| `PAYMENT_TIMEOUT_MINUTES` | Thời gian giữ booking |
| `PAYMENT_CHECK_INTERVAL_SECONDS` | Chu kỳ đồng bộ payment |

Không commit `.env`, khóa PayOS, mật khẩu database hoặc thông tin triển khai thật.

## 10. Cài đặt và chạy

### 10.1. Yêu cầu

- Flutter SDK tương thích Dart `3.11.5`.
- Android SDK và Java 17.
- Node.js 18 trở lên.
- PostgreSQL 15 hoặc Docker Desktop.
- Tài khoản/cấu hình Google OAuth nếu dùng Google Sign-In.
- Tài khoản PayOS nếu chạy luồng thanh toán thật.

### 10.2. Chạy backend bằng Docker

```powershell
cd backend
Copy-Item .env.example .env
docker compose up --build
```

Kết quả:

- API: `http://localhost:5000`
- PostgreSQL: chỉ truy cập trong Docker network qua host `db`
- Schema và dữ liệu mẫu được import khi volume database được tạo lần đầu

Chạy nền:

```powershell
docker compose up -d --build
```

Dừng:

```powershell
docker compose down
```

Không thêm `-v` nếu cần giữ dữ liệu PostgreSQL.

### 10.3. Chạy backend thủ công

```powershell
cd backend
npm install
Copy-Item .env.example .env
```

Đổi `DB_HOST=localhost`, tạo database `hotel_management`, sau đó import:

```powershell
$env:PGPASSWORD="your_password"
psql -h localhost -U postgres -d hotel_management -f hotel_management.sql
npm start
```

### 10.4. Chạy Flutter

Từ thư mục gốc:

```powershell
flutter pub get
flutter run
```

Dùng backend local:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:5000/api
```

Khi chạy Android Emulator, `localhost` trỏ đến emulator. Thường cần:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

### 10.5. Google Sign-In

- Cấu hình OAuth client đúng package/application.
- Truyền `GOOGLE_SERVER_CLIENT_ID` nếu không dùng giá trị mặc định.
- Backend `GOOGLE_CLIENT_ID` phải khớp audience của ID token.
- Với web, origin chạy ứng dụng phải có trong Authorized JavaScript origins.

### 10.6. Build Android

```powershell
flutter build apk --debug
```

APK debug:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## 11. Kiểm thử và chất lượng

### 11.1. Flutter

Repo có:

- 22 file test Dart.
- 47 test/test widget được khai báo.

Phạm vi test gồm:

- Khởi động ứng dụng.
- Điều hướng theo vai trò.
- Đăng nhập local, staff, customer và Google.
- OTP.
- API endpoint và Ngrok client.
- Đa ngôn ngữ.
- Hồ sơ.
- Model booking, payment, invoice và review.
- Lịch ngày đã đặt.
- Luồng QR payment.
- Dashboard và workflow quản trị.

Chạy:

```powershell
flutter analyze --no-fatal-infos
flutter test --no-pub
```

### 11.2. Backend

Repo có:

- 9 file test Node.js.
- 38 test được khai báo.

Phạm vi test gồm:

- Kiểm tra giao ngày và xung đột booking.
- Chuẩn hóa danh sách room ID.
- Công thức giá, khuyến mãi và VAT.
- Upload CCCD.
- Trường dữ liệu public của customer/staff.
- Staff login.
- Google token verification và Google login.
- Schema Google identity.

Chạy:

```powershell
cd backend
npm test
```

## 12. Docker, CI/CD và triển khai

### 12.1. Docker

- `docker-compose.yml`: môi trường local, public cổng `5000`.
- `docker-compose.prod.yml`: bind API vào `127.0.0.1`, phù hợp reverse proxy.
- Volume `pgdata`: lưu dữ liệu PostgreSQL.
- Volume `uploads`: giữ ảnh CCCD ngoài container.
- Healthcheck kiểm tra PostgreSQL và endpoint `/`.

### 12.2. GitHub Actions

Workflow backend chạy khi:

- Push vào nhánh `main`.
- Tạo/cập nhật pull request.

Các bước:

1. Cài Node.js 18.
2. Chạy `npm ci`.
3. Khởi tạo PostgreSQL 15.
4. Import schema.
5. Build Docker image.
6. Khởi động API.
7. Smoke test `/`.
8. Smoke test `/api/rooms`.

### 12.3. VPS

Thư mục `backend/deploy/` cung cấp:

- Script kiểm tra commit và tự cập nhật.
- `systemd` service.
- `systemd` timer chạy mỗi phút.
- Script cài auto-deploy.
- Cấu hình Nginx reverse proxy.
- Các migration database.

Luồng dự kiến:

```text
Push main
  -> GitHub Actions kiểm tra
  -> VPS phát hiện commit mới
  -> git pull
  -> docker-compose -f docker-compose.prod.yml up -d --build
  -> Nginx chuyển request đến 127.0.0.1:5000
```

## 13. Quy tắc nghiệp vụ quan trọng

- Khách hàng phải đang hoạt động và không phải staff để tạo booking.
- Phải có đủ ảnh CCCD mặt trước và sau.
- Phải chọn ít nhất một phòng.
- ID phòng phải là số nguyên dương và không trùng.
- Ngày trả phòng phải sau ngày nhận phòng.
- Số khách phải từ 1 đến tổng sức chứa phòng.
- Phòng phải đang hoạt động.
- Trạng thái vận hành phòng phải là `available` hoặc `booked`.
- Khoảng ngày không được giao với booking đang giữ chỗ hoặc còn hiệu lực.
- Booking `cancelled`, `completed`, `checked_out` và `payment_conflict` không chặn lịch.
- Khuyến mãi phải đang hoạt động và trong thời gian hiệu lực.
- Payment hold đang `pending` vẫn chặn phòng.
- Payment hết hạn giải phóng phòng bằng cách hủy payment và booking.
- Hóa đơn chỉ được tạo một lần cho mỗi booking.