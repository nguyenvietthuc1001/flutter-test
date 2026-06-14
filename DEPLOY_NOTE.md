# 🚀 Deploy Note — GitHub Pages

## Link chơi game online

👉 **https://nguyenvietthuc1001.github.io/flutter-test/**

---

## Những gì đã làm

### 1. File đã tạo / chỉnh sửa

| File | Hành động | Mô tả |
|------|-----------|-------|
| `.github/workflows/deploy.yml` | **Tạo mới** | Workflow GitHub Actions: tự động build Flutter Web và deploy lên GitHub Pages mỗi khi push code vào branch `main` |

### 2. Lệnh GitHub đã dùng

```bash
# Kiểm tra đăng nhập GitHub CLI
gh auth status

# Xem thông tin repo
gh repo view --json name,owner,defaultBranchRef,url

# Chuyển repo sang public (GitHub Free không hỗ trợ Pages cho repo private)
gh repo edit nguyenvietthuc1001/flutter-test --visibility public --accept-visibility-change-consequences

# Bật GitHub Pages với source = GitHub Actions
gh api repos/nguyenvietthuc1001/flutter-test/pages -X POST \
  -f build_type=workflow -f source.branch=main -f source.path=/

# Theo dõi workflow
gh run list --json databaseId,displayTitle,status,conclusion
gh run view <run_id> --log-failed
```

### 3. Cách hoạt động

- Mỗi khi bạn **push code lên branch `main`**, GitHub Actions sẽ tự động:
  1. Checkout code
  2. Cài Flutter SDK (latest stable)
  3. Chạy `flutter pub get`
  4. Build web với `flutter build web --release --base-href "/flutter-test/"`
  5. Upload và deploy lên GitHub Pages

- Bạn cũng có thể **chạy thủ công** từ tab Actions trên GitHub (nút "Run workflow").

### 4. Lưu ý quan trọng

> ⚠️ **Repo đã được chuyển sang PUBLIC** để dùng GitHub Pages miễn phí.
> Nếu bạn muốn giữ repo private, cần nâng cấp lên GitHub Pro/Team.

> ⚠️ **Supabase Auth**: Nếu app dùng Supabase Auth với redirect URL, bạn cần vào
> [Supabase Dashboard → Authentication → URL Configuration](https://supabase.com/dashboard)
> và thêm `https://nguyenvietthuc1001.github.io/flutter-test/` vào **Redirect URLs**.

### 5. Xem trạng thái deploy

- Vào tab **Actions** trên GitHub repo: https://github.com/nguyenvietthuc1001/flutter-test/actions
- Hoặc chạy lệnh: `gh run list`

---

*Ngày thiết lập: 2026-06-14*
