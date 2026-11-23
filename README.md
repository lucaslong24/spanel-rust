# 🦀 SPanel — Ultra-Lightweight Single-Binary Linux Server Control Panel

**SPanel** is a high-performance, single-binary Linux Web Server Control Panel written in **Rust**, featuring an embedded reactive Web UI, async 64 KB streaming I/O, and adaptive hardware scaling from **1 vCPU / 1 GB RAM** VPS instances up to multi-core production servers.

- **Supported OS:** Ubuntu 20.04+ / Debian 11+ (`systemd`)
- **Supported Architectures:** `x86_64` (Intel / AMD) & `aarch64` (ARM64 / Ampere / Graviton)
- **100% Standalone:** Zero external runtime dependencies, zero telemetry, embedded SQLite WAL & Web UI.

---

## 🚀 1-Click Installation

Run the following single command as `root` (or with `sudo`):

```bash
curl -fsSL https://raw.githubusercontent.com/lucaslong24/spanel-rust/release/install.sh | sudo bash
```

The installer automatically:
1. Detects your OS (Ubuntu/Debian) and CPU architecture (`x86_64` or `aarch64`).
2. Downloads the pre-built release binary and verifies its `SHA256SUMS` integrity.
3. Installs `/usr/local/bin/spanel` and creates the `/usr/local/bin/sp` shortcut command.
4. Configures `/var/lib/spanel` and starts the auto-healing `spanel.service` systemd daemon.
5. Opens the panel port safely on UFW (if active) and displays your initial login credentials.

---

## 🛠️ Quick CLI Management (`sp`)

Type `sudo sp` (or `sudo spanel`) with no arguments from any directory to launch the interactive management menu:

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
  [0] Thoát
----------------------------------------------------------
```

You can also execute non-interactive CLI commands directly for automation:

```bash
sudo sp info
sudo sp status
sudo sp restart
sudo sp set-port 8888
sudo sp set-entrance /my_secret_path
sudo sp reset-password
sudo sp disable-2fa
```

---

## 🗑️ Uninstallation

To stop and remove the `spanel.service` daemon, `/usr/local/bin/spanel`, and the `/usr/local/bin/sp` shortcut (while keeping `/var/lib/spanel` data safe):

```bash
curl -fsSL https://raw.githubusercontent.com/lucaslong24/spanel-rust/release/uninstall.sh | sudo bash
```

To completely remove SPanel **and** purge `/var/lib/spanel`:

```bash
curl -fsSL https://raw.githubusercontent.com/lucaslong24/spanel-rust/release/uninstall.sh | sudo bash -s -- --purge
```

---

## 🔐 Release Checksums (`v1.0.0`)

Verify downloaded binaries with `sha256sum -c SHA256SUMS`:

```text
7c43c0d5c8d697a8c6744de67a6787da2e24590c1fdcc3a6071aed63e8568727  spanel-linux-x86_64
2cbda742a3adeb2821154262569c048273758d3a8db60c964194675b49ae0f7e  spanel-linux-aarch64
```
