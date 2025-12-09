# 📢 Bảng Thông Báo 8A4 (8A4 Notification Board)

Chào mừng bạn đến với dự án **Bảng Thông Báo 8A4**! Đây là một hệ thống toàn diện giúp học sinh lớp 8A4 theo dõi bài tập về nhà (BTVN), thời khóa biểu (TKB), tin tức và nhận thông báo quan trọng.

Dự án bao gồm 3 thành phần chính: **Ứng dụng Web (PWA)**, **Ứng dụng Mobile (Flutter)**, và **Trang Admin (Flutter)**.

---

## ✨ Tính Năng Nổi Bật

*   **📰 Bảng Tin & Thông Báo:** Cập nhật tin tức và thông báo mới nhất của lớp.
*   **📚 Bài Tập Về Nhà (BTVN):** Theo dõi danh sách bài tập cần làm, hạn nộp.
*   **📅 Thời Khóa Biểu (TKB):** Xem lịch học trong ngày và cả tuần.
*   **🔔 Thông Báo Realtime:** Nhận thông báo ngay lập tức khi có cập nhật mới (sử dụng Supabase Realtime).
*   **🎨 Giao Diện Đẹp Mắt:**
    *   Thiết kế "Liquid OS" hiện đại.
    *   Chế độ Sáng/Tối (Light/Dark Mode).
    *   Hiệu ứng nền sống động (Particles, 3D).
*   **📱 Đa Nền Tảng:** Hỗ trợ Android, iOS (qua WebClip/Config Profile) và Web.

---

## 📂 Cấu Trúc Dự Án

Dự án được tổ chức thành các thư mục chính:

*   **`/` (Root Web)**: Mã nguồn cho phiên bản Web App (PWA).
    *   `index.html`: Trang chính của ứng dụng web.
    *   `admin.html`: Trang quản trị web (nếu có sử dụng phiên bản web admin).
    *   `style.css`, `admin.css`: Các file định kiểu giao diện.
    *   `script.js`, `admin.js`: Logic xử lý chính cho web.
    *   `TB8A4.mobileconfig`: Hồ sơ cấu hình để cài đặt Web App lên màn hình chính iOS.
*   **`/flutter_app`**: Mã nguồn ứng dụng di động dành cho học sinh (Flutter).
*   **`/flutter_admin`**: Mã nguồn ứng dụng quản trị dành cho ban cán sự/giáo viên (Flutter).
*   **`/supabase`**: Các cấu hình liên quan đến backend Supabase.

---

## 🚀 Hướng Dẫn Cài Đặt & Sử Dụng

### 1. Phiên Bản Web (PWA)
Truy cập trực tiếp vào đường dẫn trang web (nếu đã deploy).
*   **Android:** Nhấn vào banner cài đặt hoặc menu trình duyệt -> "Thêm vào màn hình chính".
*   **iOS:**
    1.  Truy cập web, popup hướng dẫn sẽ hiện ra.
    2.  Tải hồ sơ `TB8A4.mobileconfig`.
    3.  Vào **Cài đặt** -> **Đã tải về hồ sơ** -> Cài đặt Profile.

### 2. Ứng dụng Flutter (Mobile App)
Yêu cầu: Đã cài đặt [Flutter SDK](https://flutter.dev/docs/get-started/install).

```bash
cd flutter_app
flutter pub get
flutter run
```

### 3. Ứng dụng Quản Trị (Admin Panel)
Dành cho người quản lý để thêm/sửa/xóa thông báo và bài tập.

```bash
cd flutter_admin
flutter pub get
flutter run
```

---

## 🛠️ Công Nghệ Sử Dụng

*   **Frontend Mobile:** Flutter (Dart).
*   **Frontend Web:** HTML5, CSS3, JavaScript (Vanilla).
*   **Backend:** Supabase (Database, Auth, Realtime).
*   **Thư viện Web:**
    *   `supabase-js`: Kết nối backend.
    *   `fontawesome`: Icon.
    *   `particles.js`: Hiệu ứng nền.

---

## 📝 Lưu Ý
*   Mã nguồn này chứa các cấu hình kết nối đến Supabase trong `config.js` hoặc `env.dart`. Đảm bảo bảo mật các key này nếu public dự án.
*   Dự án được tối ưu cho trải nghiệm người dùng với các hiệu ứng mượt mà và giao diện thân thiện.
