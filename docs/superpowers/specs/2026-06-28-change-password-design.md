# Thiết kế tính năng Đổi mật khẩu (Change Password Feature)

Tài liệu thiết kế chi tiết cho tính năng đổi mật khẩu của ứng dụng game Caro King.

## 1. Yêu cầu & Mục tiêu
- Cho phép người dùng đã đăng nhập thay đổi mật khẩu của họ một cách an toàn.
- Giao diện tối giản, đồng bộ với phong cách Dark Mode và Glassmorphic của ứng dụng.
- Đảm bảo tính bảo mật bằng cách yêu cầu người dùng xác thực mật khẩu hiện tại trước khi cập nhật mật khẩu mới.

## 2. Thiết kế Giao diện (UI) & Trải nghiệm (UX)
- **Điểm truy cập (Entry Point):**
  - Một nút `IconButton` với icon `Icons.manage_accounts` (màu xanh Cyan `#00E5FF` hoặc tương tự) được thêm vào góc trên bên phải của màn hình chơi game (`CaroGameScreen`), bên cạnh hiển thị email người dùng và nút Đăng xuất.
  - Khi click vào nút này, ứng dụng điều hướng sang màn hình `ProfileScreen`.
- **Màn hình Hồ sơ (`ProfileScreen`):**
  - Màn hình sử dụng `Scaffold` với nền tối (`Colors.black`).
  - Gồm một `AppBar` với nút back (`Icons.arrow_back_ios_new`) và tiêu đề "Hồ sơ cá nhân".
  - Một `Card` bo góc mượt mà (`BorderRadius.circular(20)`), nền mờ `white.withValues(alpha: 0.05)` hiển thị:
    - Email của người dùng hiện tại (chỉ đọc).
    - Trường nhập "Mật khẩu hiện tại" (ẩn ký tự).
    - Trường nhập "Mật khẩu mới" (ẩn ký tự).
    - Trường nhập "Xác nhận mật khẩu mới" (ẩn ký tự).
    - Các trường nhập có nút bật/tắt hiển thị mật khẩu (icon con mắt).
    - Nút "CẬP NHẬT MẬT KHẨU" (`ElevatedButton`) màu tím chủ đạo (`Color(0xFF6C63FF)`), hiển thị `CircularProgressIndicator` nhỏ khi đang xử lý.

## 3. Luồng Nghiệp vụ (Business Logic)
1. **Kiểm tra đầu vào (Client-side Validation):**
   - Mật khẩu hiện tại không được để trống.
   - Mật khẩu mới phải từ 6 ký tự trở lên.
   - Xác nhận mật khẩu mới phải trùng khớp với mật khẩu mới.
2. **Xác thực mật khẩu cũ:**
   - Lấy email người dùng hiện tại từ `supabase.auth.currentUser?.email`.
   - Gọi `await supabase.auth.signInWithPassword(email: email, password: currentPassword)` để kiểm tra mật khẩu cũ.
3. **Cập nhật mật khẩu mới:**
   - Nếu xác thực thành công, gọi `await supabase.auth.updateUser(UserAttributes(password: newPassword))`.
4. **Thông báo kết quả:**
   - Nếu thành công: Hiển thị SnackBar "Đổi mật khẩu thành công!" và tự động quay lại màn hình game chính sau 1.5 giây.
   - Nếu thất bại ở bước xác thực mật khẩu cũ: Hiển thị lỗi "Mật khẩu hiện tại không chính xác".
   - Nếu thất bại ở bước cập nhật: Hiển thị lỗi tương ứng từ Supabase.

## 4. Thay đổi mã nguồn dự kiến
- **[MODIFY] [lib/main.dart](file:///d:/flutter-test/lib/main.dart):**
  - Thêm lớp `ProfileScreen` mới (StatefulWidget) ở cuối file.
  - Sửa đổi widget Header trong `_CaroGameScreenState` để thêm nút `IconButton` dẫn sang `ProfileScreen`.

## 5. Kế hoạch xác minh (Verification Plan)
- **Kiểm tra thủ công:**
  - Đăng nhập vào game, bấm vào biểu tượng Profile để mở màn hình đổi mật khẩu.
  - Nhập sai mật khẩu hiện tại -> Hệ thống phải báo lỗi "Mật khẩu hiện tại không chính xác".
  - Nhập mật khẩu mới ngắn hơn 6 ký tự -> Hệ thống báo lỗi validation.
  - Nhập mật khẩu mới không khớp xác nhận -> Hệ thống báo lỗi validation.
  - Nhập đúng mật khẩu hiện tại, mật khẩu mới hợp lệ -> Hệ thống thông báo thành công và tự động quay lại màn hình game.
  - Thử đăng xuất và đăng nhập lại bằng mật khẩu mới để kiểm chứng.
