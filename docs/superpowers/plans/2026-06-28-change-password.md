# Đổi mật khẩu (Change Password) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm tính năng đổi mật khẩu an toàn (yêu cầu mật khẩu hiện tại) trong màn hình hồ sơ cá nhân (Profile) mới cho ứng dụng game Caro King.

**Architecture:** 
- Thêm nút Profile (`Icons.manage_accounts`) vào thanh Header của màn hình chơi game (`CaroGameScreen`).
- Tạo mới lớp `ProfileScreen` (StatefulWidget) ở cuối file [main.dart](file:///d:/flutter-test/lib/main.dart).
- Luồng đổi mật khẩu: Xác thực lại mật khẩu hiện tại bằng cách gọi `supabase.auth.signInWithPassword` trước khi cập nhật mật khẩu mới bằng `supabase.auth.updateUser`.

**Tech Stack:** Flutter, Supabase Auth.

## Global Constraints
- Code sạch, không chứa các dòng debug/print dư thừa.
- Đảm bảo xử lý lỗi đầy đủ và hiển thị thông báo rõ ràng cho người dùng qua SnackBar.
- Đảm bảo app biên dịch thành công sau mỗi task (`flutter analyze` không có lỗi).

---

### Task 1: Thêm Entry Point điều hướng và lớp ProfileScreen khung xương (Stub)

**Files:**
- Modify: [lib/main.dart](file:///d:/flutter-test/lib/main.dart)

**Interfaces:**
- Consumes: `widget.userEmail` từ `CaroGameScreen`.
- Produces: Màn hình `ProfileScreen` cơ bản để điều hướng tới.

- [ ] **Step 1: Khai báo lớp `ProfileScreen` khung xương ở cuối file `lib/main.dart`**

```dart
class ProfileScreen extends StatefulWidget {
  final String userEmail;
  const ProfileScreen({super.key, required this.userEmail});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: Center(child: Text('Hồ sơ của: ${widget.userEmail}')),
    );
  }
}
```

- [ ] **Step 2: Thêm nút Profile vào Header trong `_CaroGameScreenState`**

Tìm đến hàm `_buildHeader` hoặc đoạn code vẽ thông tin email (khoảng dòng 2375-2397) và thêm nút `IconButton` điều hướng sang `ProfileScreen` trước nút Đăng xuất:

```dart
IconButton(
  visualDensity: VisualDensity.compact,
  iconSize: 18,
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
  tooltip: 'Hồ sơ cá nhân',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userEmail: widget.userEmail),
      ),
    );
  },
  icon: const Icon(Icons.manage_accounts, color: Color(0xFF00E5FF)),
),
```

- [ ] **Step 3: Chạy phân tích mã nguồn để đảm bảo không có lỗi biên dịch**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: add profile entry point and stub ProfileScreen"
```

---

### Task 2: Thiết kế giao diện đầy đủ cho ProfileScreen

**Files:**
- Modify: [lib/main.dart](file:///d:/flutter-test/lib/main.dart)

**Interfaces:**
- Consumes: `ProfileScreen` từ Task 1.
- Produces: Giao diện Form đổi mật khẩu hoàn chỉnh với validation.

- [ ] **Step 1: Cập nhật giao diện `_ProfileScreenState` hoàn chỉnh**

Thay thế nội dung lớp `_ProfileScreenState` bằng giao diện Form đổi mật khẩu chứa:
- Email (chỉ đọc).
- 3 trường nhập mật khẩu: Mật khẩu hiện tại, Mật khẩu mới, Xác nhận mật khẩu mới.
- Nút cập nhật mật khẩu kèm hiệu ứng loading.

```dart
class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    // Sẽ được hiện thực ở Task 3
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'HỒ SƠ CÁ NHÂN',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email Info
                    Row(
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 20, color: Color(0xFF00E5FF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.userEmail,
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 24),

                    // Current Password
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu hiện tại',
                        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
                    ),
                    const SizedBox(height: 16),

                    // New Password
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_open_outlined, color: Colors.white38, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                        if (val.length < 6) return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm New Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_reset_outlined, color: Colors.white38, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Vui lòng xác nhận mật khẩu mới';
                        if (val != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'CẬP NHẬT MẬT KHẨU',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Chạy phân tích mã nguồn để kiểm tra lỗi cú pháp**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: implement ProfileScreen UI and form validation"
```

---

### Task 3: Hiện thực hóa logic đổi mật khẩu với Supabase Auth

**Files:**
- Modify: [lib/main.dart](file:///d:/flutter-test/lib/main.dart)

**Interfaces:**
- Consumes: Form đổi mật khẩu từ Task 2.
- Produces: Logic đổi mật khẩu an toàn kết nối tới Supabase.

- [ ] **Step 1: Viết logic cho hàm `_updatePassword`**

Cập nhật hàm `_updatePassword` trong `_ProfileScreenState`:

```dart
  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Xác thực lại bằng mật khẩu hiện tại
      await supabase.auth.signInWithPassword(
        email: widget.userEmail,
        password: _currentPasswordController.text.trim(),
      );

      // 2. Nếu đăng nhập thành công, cập nhật mật khẩu mới
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Quay lại màn hình trước đó sau 1.5 giây
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMsg = e.message;
        if (e.message.contains('Invalid login credentials')) {
          errorMsg = 'Mật khẩu hiện tại không chính xác.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
```

- [ ] **Step 2: Chạy phân tích mã nguồn lần cuối**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: implement change password logic using Supabase Auth"
```

---

## Verification Plan

### Automated Tests
- `flutter analyze` để đảm bảo code sạch lỗi lints/warnings.

### Manual Verification
1. Chạy ứng dụng web locally hoặc deploy lên GitHub Pages.
2. Đăng nhập vào một tài khoản có sẵn.
3. Bấm vào nút Profile ở Header để chuyển sang màn hình Profile.
4. Kiểm tra các trường hợp validation:
   - Để trống ô mật khẩu hiện tại -> Báo lỗi.
   - Nhập mật khẩu mới < 6 ký tự -> Báo lỗi.
   - Xác nhận mật khẩu không khớp -> Báo lỗi.
5. Thử nhập sai mật khẩu hiện tại -> Báo lỗi "Mật khẩu hiện tại không chính xác".
6. Thử nhập đúng mật khẩu hiện tại và mật khẩu mới hợp lệ -> Báo thành công, tự động đóng màn hình.
7. Đăng xuất và đăng nhập lại bằng mật khẩu mới để xác nhận mật khẩu đã thực sự thay đổi trên Supabase.
