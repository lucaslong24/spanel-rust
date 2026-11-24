# 🦀 SPanel v1.0 — Bảng Điều Khiển Máy Chủ Linux Siêu Nhẹ Viết Bằng Rust

**SPanel** là bảng điều khiển quản trị máy chủ Linux (Web Server Control Panel) thế hệ mới được đóng gói trong **1 file thực thi Rust duy nhất (Single-Binary)**, nhúng sẵn giao diện Web Preact phản hồi tức thì, truyền tải dữ liệu theo luồng bất đồng bộ 64 KB (Zero Full-File RAM Buffering) và tự động thích ứng phần cứng từ **VPS 1 vCPU / 1 GB RAM** đến máy chủ đa nhân cấu hình cao.

---

## ✨ Tính Năng Nổi Bật

- **Kiến trúc Single-Binary & Tối ưu Bộ nhớ:** Nhúng toàn bộ giao diện Web tĩnh, cơ sở dữ liệu cấu hình nội bộ SQLite WAL (`/var/lib/spanel/spanel.db`) và bộ cấp phát bộ nhớ `mimalloc` trong 1 tệp thực thi duy nhất (~14–15 MB), không cần cài đặt Python/Node.js runtime trên máy chủ.
- **Giao diện Multi-Green Tương phản cao & Đa ngôn ngữ (`VI | EN`):** Hỗ trợ chuyển đổi tức thời giữa **Dark Mode / Light Mode** và **Tiếng Việt / Tiếng Anh (`VI | EN`)** cho cả giao diện Web lẫn dòng lệnh CLI (`sp`).
- **Giám sát Hệ thống Thời gian thực (0 Subprocess):** Theo dõi trực tiếp CPU, RAM, Swap, Phân vùng ổ đĩa, Lưu lượng mạng, Disk I/O và bảng **Tiến trình tiêu thụ cao nhất (kèm thời gian hoạt động `Uptime`)** qua WebSocket mỗi 2 giây.
- **Quản lý Website Nginx & Auto-SSL (ACMEv2):** Hỗ trợ Static HTML, PHP-FPM đa phiên bản, Reverse Proxy (WebSocket), URL Rewrite, Redirect 301/302, BasicAuth và tự động cấp phát/gia hạn chứng chỉ **Let's Encrypt** (tự động kiểm tra `nginx -t` và hoàn tác khi lỗi).
- **Quản trị Cơ sở dữ liệu, Lập lịch Cron & Cloud Backup S3/R2 Streaming:** Quản lý **MariaDB/MySQL** và **PostgreSQL** qua Unix Domain Socket; sao lưu/khôi phục `.tar.zst` / `.sql.zst` theo luồng 64 KB cục bộ hoặc truyền thẳng lên **Cloudflare R2, AWS S3, Backblaze B2, MinIO** không tạo tệp tạm trên VPS.
- **Trình quản lý Tệp, Web Terminal Đa Tab (Local PTY + Remote SSH TOFU) & Tường lửa UFW / SSH Security:** Duyệt/sửa code trực tiếp bằng CodeMirror 6, mở Local PTY & Remote SSH thuần Rust (`russh` + TOFU SHA-256 chống MITM), quản lý cổng UFW (có khóa chống tự khóa cổng quản trị) và gia cố `/etc/ssh/sshd_config`.
- **Tường lửa Web Nhẹ (`Lightweight Nginx WAF`):** Bảo vệ từng website chống SQL Injection, XSS/Path Traversal, Bad Bot/Scanner, lộ tệp nhạy cảm (`.env`, `.git`) và Rate/Conn Limit thuần Nginx Native kèm nút chặn IP UFW 1 chạm.
- **Chống Giả Mạo Tệp & Cách Ly Webshell (`InotifyFileGuard`):** Giám sát thay đổi tệp thời gian thực bằng Linux Kernel `inotify` (`0` polling), quét chữ ký Webshell giới hạn bộ nhớ `64 KB`, tự cách ly tệp đáng ngờ (`chmod 0000`, hỗ trợ Khôi phục / Xóa 1 chạm và tạm dừng 15/30/60 phút khi deploy).
- **Cảnh báo Bảo mật & Hạ tầng Tức thời (`Telegram` & `Webhook HMAC`):** Thông báo thời gian thực qua `EventBus` khi đăng nhập bất thường, quá tải tài nguyên, chứng chỉ SSL sắp hết hạn, bùng phát tấn công WAF hoặc phát hiện Webshell/thay đổi tệp.

---

## 🖥️ Nền Tảng Hỗ Trợ

- **Hệ điều hành:** Ubuntu 20.04+ / Debian 11+ (`systemd`)
- **Kiến trúc vi xử lý:** `x86_64` (Intel / AMD) và `aarch64` (ARM64 / Oracle Ampere / AWS Graviton)

---

## 🚀 Cài Đặt Nhanh 1-Click

Chạy duy nhất câu lệnh dưới đây với quyền `root` (hoặc qua `sudo`):

```bash
curl -fsSL https://raw.githubusercontent.com/lucaslong24/spanel-rust/release/install.sh | sudo bash
```

Kịch bản cài đặt sẽ tự động:
1. Kiểm tra hệ điều hành Ubuntu/Debian và nhận diện kiến trúc (`x86_64` hoặc `aarch64`).
2. Tải bản thực thi tương ứng từ GitHub Releases và đối chiếu mã băm toàn vẹn `SHA256SUMS`.
3. Cài đặt vào `/usr/local/bin/spanel` và tạo lệnh tắt `/usr/local/bin/sp`.
4. Khởi tạo thư mục dữ liệu `/var/lib/spanel` và kích hoạt dịch vụ tự phục hồi `spanel.service`.
5. Mở cổng an toàn trên tường lửa UFW (nếu đang bật) và in ngay thông tin đăng nhập ban đầu.

---

## 🛠️ Bảng Điều Khiển Dòng Lệnh (`sudo sp`)

Từ bất kỳ thư mục nào trên SSH, chỉ cần gõ lệnh ngắn `sudo sp` (hoặc `sudo spanel`) không kèm tham số để mở bảng điều khiển tương tác:

```text
==========================================================
      🦀 SPanel 1.0 — Bảng Điều Khiển Quản Trị Nhanh      
==========================================================
  [1] Xem thông tin truy cập (info: URL, port, entrance)
  [2] Xem trạng thái dịch vụ & RAM (status)
  [3] Khởi động / Dừng / Khởi động lại SPanel (systemctl)
  [4] Đổi mật khẩu quản trị (reset-password)
  [5] Tắt xác thực 2 lớp 2FA (reset-password --disable-2fa)
  [6] Đổi cổng Panel (set-port)
  [7] Đổi đường dẫn bí mật (set-entrance)
  [8] Đổi ngôn ngữ (VI / EN — set-lang)
  [9] Gỡ cài đặt SPanel (uninstall)
  [0] Thoát
----------------------------------------------------------
```

### Các lệnh CLI trực tiếp (phục vụ tự động hóa)

```bash
sudo sp info                      # Xem URL truy cập, cổng, đường dẫn bí mật & trạng thái 2FA
sudo sp status                    # Xem trạng thái dịch vụ, PID, mức tiêu thụ RAM (RSS) & WorkerPool
sudo sp restart                   # Khởi động lại nhanh dịch vụ spanel.service
sudo sp set-port 8888             # Đổi cổng lắng nghe của Panel (1024-65535)
sudo sp set-entrance /secret_path # Đổi đường dẫn lối vào bí mật
sudo sp reset-password            # Đặt lại mật khẩu quản trị viên
sudo sp disable-2fa               # Tắt khẩn cấp xác thực 2 lớp (2FA)
sudo sp set-lang en               # Chuyển ngôn ngữ CLI sang Tiếng Anh (EN)
sudo sp set-lang vi               # Chuyển ngôn ngữ CLI sang Tiếng Việt (VI)
sudo sp uninstall                 # Gỡ cài đặt SPanel có hỏi xác nhận an toàn
```

---

## 🗑️ Gỡ Cài Đặt

Bạn có thể gỡ cài đặt trực tiếp bằng lệnh tích hợp sẵn (hoặc chọn mục `[9]` trong menu `sudo sp`):

```bash
sudo sp uninstall
```

Hoặc chạy qua kịch bản gỡ cài đặt từ xa (mặc định giữ an toàn dữ liệu trong `/var/lib/spanel` và `/www/wwwroot`; thêm `--purge` để dọn dữ liệu SPanel — sẽ giữ nguyên `/www/wwwroot` nếu có mã nguồn trừ khi xác nhận lần 2 hoặc thêm `--purge-sites`):

```bash
curl -fsSL https://raw.githubusercontent.com/lucaslong24/spanel-rust/release/uninstall.sh | sudo bash
```

---

## 🔐 Mã Băm Kiểm Tra Toàn Vẹn (`SHA256SUMS`)

```text
44d67fa29669eacb676e7a75ba8917148966c2b97c09844e1511c75d11cdbdf8  spanel-linux-x86_64
a6054f68972df34aaf6fc92e46d9eadc07575c28689cbdcc000a3c601bf32b53  spanel-linux-aarch64
```
