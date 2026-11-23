# 🦀 SPanel v1.0 — Bảng Điều Khiển Máy Chủ Linux Siêu Nhẹ Viết Bằng Rust

**SPanel** là bảng điều khiển quản trị máy chủ Linux (Web Server Control Panel) thế hệ mới được đóng gói trong **1 file thực thi Rust duy nhất (Single-Binary)**, nhúng sẵn giao diện Web Preact phản hồi tức thì, truyền tải dữ liệu theo luồng bất đồng bộ 64 KB (Zero Full-File RAM Buffering) và tự động thích ứng phần cứng từ **VPS 1 vCPU / 1 GB RAM** đến máy chủ đa nhân cấu hình cao.

---

## ✨ Tính Năng Nổi Bật

- **Kiến trúc Single-Binary & Tối ưu Bộ nhớ:** Nhúng toàn bộ giao diện Web tĩnh, cơ sở dữ liệu cấu hình nội bộ SQLite WAL (`/var/lib/spanel/spanel.db`) và bộ cấp phát bộ nhớ `mimalloc` trong 1 tệp thực thi duy nhất (~11–12 MB), không cần cài đặt Python/Node.js runtime trên máy chủ.
- **Giao diện Multi-Green Tương phản cao & Đa ngôn ngữ (`VI | EN`):** Hỗ trợ chuyển đổi tức thời giữa **Dark Mode / Light Mode** và **Tiếng Việt / Tiếng Anh (`VI | EN`)** cho cả giao diện Web lẫn dòng lệnh CLI (`sp`).
- **Giám sát Hệ thống Thời gian thực (0 Subprocess):** Theo dõi trực tiếp CPU, RAM, Swap, Phân vùng ổ đĩa, Lưu lượng mạng, Disk I/O và bảng **Tiến trình tiêu thụ cao nhất (kèm thời gian hoạt động `Uptime`)** qua WebSocket mỗi 2 giây.
- **Quản lý Website Nginx & Auto-SSL (ACMEv2):** Hỗ trợ Static HTML, PHP-FPM đa phiên bản, Reverse Proxy (WebSocket), URL Rewrite, Redirect 301/302, BasicAuth và tự động cấp phát/gia hạn chứng chỉ **Let's Encrypt** (tự động kiểm tra `nginx -t` và hoàn tác khi lỗi).
- **Quản trị Cơ sở dữ liệu, Lập lịch Cron & Sao lưu Luồng 64 KB:** Quản lý **MariaDB/MySQL** và **PostgreSQL** qua Unix Domain Socket, sao lưu/khôi phục nén `.tar.zst` / `.sql.zst` theo luồng 64 KB, tự động xoay vòng log và dọn bản sao lưu cũ theo `retention_count`.
- **Trình quản lý Tệp, Web Terminal (Local PTY) & Tường lửa UFW / SSH Security:** Duyệt/sửa code trực tiếp bằng CodeMirror 6, mở Local PTY Terminal (`xterm.js`), quản lý cổng UFW (có khóa chống tự khóa cổng quản trị) và gia cố `/etc/ssh/sshd_config` (kiểm tra `sshd -t` bắt buộc trước khi áp dụng).

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

## 🔐 Mã Băm Kiểm Tra Toàn Vẹn (`SHA256SUMS` — `v1.0.0`)

```text
8616a532cd23e6a2801a97aa666eb102be491be91a50be461c4f9d5fa43ed4c1  spanel-linux-x86_64
ac09edc59b6b76eca76e416c57fa82a565a21cb1310c5de4e269f14249a13fa4  spanel-linux-aarch64
```
