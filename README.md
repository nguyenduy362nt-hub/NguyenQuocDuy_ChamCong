# APP CHẤM CÔNG NHÂN VIÊN
**Sinh viên:** Nguyễn Quốc Duy – **Lớp:** 23DTHC4

| Thành phần | Tên (có tên cá nhân) |
|---|---|
| Project Web API (.NET 8) | `NguyenQuocDuy_ChamCong_API` |
| Cơ sở dữ liệu SQL Server | `NguyenQuocDuy_ChamCong_DB` |
| Project Flutter | `nguyenquocduy_chamcong` (applicationId `com.nguyenquocduy.nguyenquocduy_chamcong`) |

> ⚠️ Code được viết trong môi trường không có .NET/Flutter nên **chưa được biên dịch thử**. Hãy build theo các bước dưới; nếu có lỗi biên dịch, gửi nguyên văn lỗi để sửa.

---
## 1. Chạy Web API (Visual Studio 2022)
1. Mở thư mục `NguyenQuocDuy_ChamCong_API`, mở file `.csproj` (hoặc tạo Solution và Add Existing Project).
2. Kiểm tra chuỗi kết nối trong `appsettings.json` (mặc định dùng LocalDB: `(localdb)\MSSQLLocalDB`). Nếu dùng SQL Server khác, đổi `Server=...`, **giữ nguyên tên DB `NguyenQuocDuy_ChamCong_DB`**.
3. Chọn profile **http** (không phải IIS/https) → nhấn F5. API chạy tại `http://localhost:5245`, Swagger mở sẵn.
4. Lần đầu chạy, hệ thống **tự tạo database + dữ liệu mẫu** (không cần Add-Migration).
5. Nếu Windows Firewall hỏi quyền → Allow.

### Tài khoản mẫu
| Vai trò | Tên đăng nhập | Mật khẩu |
|---|---|---|
| Admin | `admin` | `Admin@123` |
| Nhân viên | `nvan` | `Nv@123456` |
| Nhân viên | `nvbinh` | `Nv@123456` |
| Khách hàng | `khach1` | `Kh@123456` |

### OTP
Đăng nhập = tên đăng nhập + mật khẩu → hệ thống gửi **OTP 6 số qua email**.
- Chưa cấu hình SMTP: OTP được **in ra cửa sổ Output/Console của API** (dòng `[OTP] ...`) và app hiện thêm khung vàng "Chế độ demo" kèm nút **Điền**.
- Muốn gửi email thật: điền `Smtp:Host/Port/User/Password/From` trong `appsettings.json` (ví dụ Gmail: `smtp.gmail.com`, 587, App Password) và đặt `Otp:ExposeInResponse` = `false`.

---
## 2. Chạy ứng dụng Flutter (Android Studio, máy ảo Pixel 7)
```powershell
cd NguyenQuocDuy_ChamCong
.\setup_flutter.ps1        # tạo android/, cấp quyền, minSdk 23, flutter pub get
```
Rồi mở thư mục `nguyenquocduy_chamcong` bằng Android Studio → chọn máy ảo → Run.
- `.env` có `BASE_URL=http://10.0.2.2:5245/api/` (10.0.2.2 = máy tính từ trong máy ảo). **API phải đang chạy.**
- Máy thật cùng Wi-Fi: đổi thành `http://<IP-máy-tính>:5245/api/`.

---
## 3. Đối chiếu yêu cầu đề
| # | Yêu cầu | Nơi thực hiện |
|---|---|---|
| 1 | Đăng ký qua email | `RegisterScreen` → `POST /api/auth/register` (kiểm tra email hợp lệ & duy nhất, gửi email chào) |
| 2 | Đăng nhập: user + mật khẩu + OTP | `LoginScreen` → `POST /api/auth/login` → `OtpScreen` → `POST /api/auth/verify-otp` (JWT) |
| 3 | Phân quyền | `AuthGate` (main.dart): Admin → `AdminHome`; NhanVien → `EmployeeHome`; còn lại (KhachHang) → `CustomerHome`. API dùng `[Authorize(Roles=...)]` |
| 4 | CRUD (4.5đ) | Admin: Nhân viên, Phòng ban, Ca làm, Điểm làm việc (geofence), Chấm công (thủ công), Duyệt nghỉ phép, Xóa đánh giá. Nhân viên: Đơn nghỉ phép (thêm/sửa/xóa khi chờ duyệt). Khách hàng: Đánh giá nhân viên |
| 5 | 3 chức năng thuyết trình | (b) Chia sẻ vị trí, (e) Quét QR, (d) Đo chuyển động – xem mục 4 |
| 6 | Tính năng mới | **QR động xoay vòng 30s + Điểm chuyên cần & Bảng xếp hạng** + chống chấm công hộ (lắc xác thực) – xem mục 5 |
| 7 | Giao diện | Material 3, tông teal, NavigationBar, thẻ bo góc, form động, thông báo lỗi tiếng Việt |

---
## 4. Ba chức năng thuyết trình chạy được trên MÁY ẢO
Lý do chọn: không cần điện thoại thật, không cần phần cứng đặc biệt (khuôn mặt, vân tay, NFC, video nhóm đều khó/không ổn định trên emulator).

### (b) Chia sẻ vị trí
- Nhân viên: tab **Chấm công** → bật công tắc **Chia sẻ vị trí** (gửi mỗi 10 giây).
- Admin: **Tổng quan → Bản đồ nhân viên**: thấy ghim nhân viên, vòng tròn geofence văn phòng, khoảng cách tới văn phòng.
- Giả lập vị trí: máy ảo → nút `...` (Extended controls) → **Location** → nhập toạ độ → *Send*; hoặc chọn *Set location*. Điểm làm việc mặc định `37.4219983, -122.084` (đúng vị trí mặc định của emulator) bán kính 300 m, nên chạy ngay. Đổi trong Admin → Quản lý → Điểm làm việc.
- Demo "ngoài vùng": đổi vị trí sang xa văn phòng → chấm công bị từ chối kèm khoảng cách.
- Cần internet để tải nền bản đồ OpenStreetMap.

### (e) Nhận diện QR
- Admin: **Hiển thị QR chấm công** – mã đổi mỗi 30 giây (HMAC-SHA256, server kiểm tra chữ ký + thời hạn).
- Nhân viên: **Quét QR động** (camera) – xác thực rồi chấm công.
- Camera ảo: AVD Manager → Edit AVD → Show Advanced Settings → Camera: *Webcam0* (quét QR hiển thị trên màn hình máy tính) hoặc *VirtualScene*. Nếu không quét được: dùng ô **dán mã dạng chữ** (Admin → màn QR → *Sao chép*).
- Chạy 2 máy ảo (Admin + nhân viên) hoặc dùng Swagger/Chrome để hiển thị mã.

### (d) Đo chuyển động (gia tốc kế)
- Chấm công bằng GPS yêu cầu **thử thách lắc 4 lần** (đồ thị gia tốc thời gian thực).
- Máy ảo: Extended controls → **Virtual sensors → Device pose** (kéo thanh Move/Rotate) hoặc tab Accelerometer. Có nút *Giả lập một cú lắc* phòng khi sensor ảo không phát dữ liệu.

---
## 5. Tính năng mới (điểm 6)
Các app chấm công thông thường chỉ có GPS hoặc QR tĩnh. App này thêm:
1. **QR động 30 giây** – không thể chụp màn hình gửi người khác chấm công hộ.
2. **Xác thực chuyển động trước khi chấm công GPS** – chặn app giả lập vị trí chạy tự động.
3. **Điểm chuyên cần & Bảng xếp hạng 30 ngày** (đúng giờ +10, trễ +6, +1/giờ làm tối đa +9/ngày) – tạo động lực, hiển thị cho cả khách hàng ("Bảng vàng").

---
## 6. Kịch bản demo nhanh (5 phút)
1. Đăng ký tài khoản nhân viên mới bằng email → đăng nhập → nhập OTP.
2. Đăng nhập `admin` → Dashboard thống kê → CRUD nhân viên/phòng ban/ca → mở QR.
3. Đăng nhập `nvan` → chấm công QR → bật chia sẻ vị trí → xin nghỉ phép.
4. Quay lại `admin`: xem bản đồ, duyệt nghỉ phép, xem xếp hạng.
5. Đăng nhập `khach1` → xem nhân viên, đánh giá 5 sao, xem bảng xếp hạng.

## 7. Lỗi thường gặp
| Lỗi | Cách xử lý |
|---|---|
| `Không kết nối được máy chủ` | API chưa chạy / chọn nhầm profile IIS; dùng profile **http**, port 5245 |
| Không thấy OTP | Xem Output → "ASP.NET Core Web Server" (VS), tìm `[OTP]`; hoặc dùng nút Điền trong app |
| Chấm công báo ngoài vùng | Emulator → Location → đặt lại `37.4219983, -122.084` hoặc đổi điểm làm việc |
| Lỗi Gradle/minSdk | Chạy lại `setup_flutter.ps1`; đảm bảo `minSdk = 23` |
| `Hôm nay bạn đã chấm công vào rồi` | Mỗi ngày 1 bản ghi; Admin xóa bản ghi trong tab Chấm công để thử lại |
| Đổi tên DB | Chỉ giữ tên chứa họ tên; xóa DB cũ để seed lại |
