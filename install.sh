#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# SPanel 1.0 — 1-Click Installer (Ubuntu 20.04+ / Debian 11+, x86_64 & aarch64)
# Repo: https://github.com/lucaslong24/spanel-rust
# Usage: curl -fsSL https://raw.githubusercontent.com/lucaslong24/spanel-rust/release/install.sh | sudo bash
# ==============================================================================

BOLD_CYAN="\033[1;36m"
BOLD_GREEN="\033[1;32m"
BOLD_YELLOW="\033[1;33m"
BOLD_RED="\033[1;31m"
RESET="\033[0m"

INSTALL_BIN="/usr/local/bin/spanel"
SYMLINK_SP="/usr/local/bin/sp"
DATA_DIR="${SPANEL_DATA_DIR:-/var/lib/spanel}"
SERVICE_PATH="/etc/systemd/system/spanel.service"
RELEASE_TAG="${SPANEL_RELEASE_TAG:-v1.0.0}"
GITHUB_REPO="lucaslong24/spanel-rust"
DEFAULT_RELEASE_BASE="https://github.com/${GITHUB_REPO}/releases/latest/download"
TAG_RELEASE_BASE="https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}"

if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "${SCRIPT_DIR}/.." 2>/dev/null && pwd || pwd)"
else
    SCRIPT_DIR="$(pwd)"
    REPO_ROOT="${SCRIPT_DIR}"
fi

TMP_WORK_DIR=""
cleanup_tmp() {
    if [[ -n "${TMP_WORK_DIR}" && -d "${TMP_WORK_DIR}" ]]; then
        rm -rf "${TMP_WORK_DIR}"
    fi
}
trap cleanup_tmp EXIT

log_info() { echo -e "${BOLD_CYAN}[SPanel]${RESET} $*"; }
log_ok()   { echo -e "${BOLD_GREEN}[OK]${RESET} $*"; }
log_warn() { echo -e "${BOLD_YELLOW}[WARN]${RESET} $*"; }
log_err()  { echo -e "${BOLD_RED}[ERROR]${RESET} $*" >&2; }

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    log_err "Vui lòng chạy kịch bản cài đặt dưới quyền root (sudo bash install.sh)."
    exit 1
fi

if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_LIKE="${ID_LIKE:-}"
    if [[ "${OS_ID}" != "ubuntu" && "${OS_ID}" != "debian" && "${OS_LIKE}" != *"debian"* && "${OS_LIKE}" != *"ubuntu"* ]]; then
        log_err "Hệ điều hành '${PRETTY_NAME:-$OS_ID}' chưa được hỗ trợ chính thức (yêu cầu Ubuntu 20.04+ hoặc Debian 11+)."
        exit 1
    fi
    log_info "Hệ điều hành phát hiện: ${PRETTY_NAME:-$OS_ID}"
else
    log_err "Không tìm thấy /etc/os-release. Yêu cầu Ubuntu 20.04+ hoặc Debian 11+."
    exit 1
fi

RAW_ARCH="$(uname -m)"
case "${RAW_ARCH}" in
    x86_64|amd64)
        TARGET_ARCH="x86_64"
        ;;
    aarch64|arm64)
        TARGET_ARCH="aarch64"
        ;;
    *)
        log_err "Kiến trúc vi xử lý '${RAW_ARCH}' không được hỗ trợ (chỉ hỗ trợ x86_64 và aarch64)."
        exit 1
        ;;
esac
BINARY_FILENAME="spanel-linux-${TARGET_ARCH}"
log_info "Kiến trúc phần cứng: ${TARGET_ARCH} (${BINARY_FILENAME})"

verify_checksum_if_available() {
    local bin_dir="$1"
    local bin_name="$2"
    local sum_file="$3"
    if [[ -f "${sum_file}" ]]; then
        log_info "Đang kiểm tra mã băm toàn vẹn SHA-256 cho ${bin_name}..." >&2
        local expected_line
        expected_line="$(grep -E "[[:space:]]${bin_name}\$" "${sum_file}" || true)"
        if [[ -z "${expected_line}" ]]; then
            log_err "Không tìm thấy mục '${bin_name}' trong tệp SHA256SUMS."
            return 1
        fi
        (cd "${bin_dir}" && echo "${expected_line}" | sha256sum -c - >/dev/null)
        log_ok "Xác thực SHA-256 hợp lệ cho ${bin_name}." >&2
    fi
    return 0
}

download_release_binary() {
    TMP_WORK_DIR="$(mktemp -d /tmp/spanel-install.XXXXXX)"
    local bin_url="${SPANEL_DOWNLOAD_URL:-${DEFAULT_RELEASE_BASE}/${BINARY_FILENAME}}"
    local sum_url="${SPANEL_CHECKSUMS_URL:-${DEFAULT_RELEASE_BASE}/SHA256SUMS}"
    local out_bin="${TMP_WORK_DIR}/${BINARY_FILENAME}"
    local out_sum="${TMP_WORK_DIR}/SHA256SUMS"

    log_info "Đang tải gói phát hành SPanel (${BINARY_FILENAME}) từ GitHub Releases..." >&2
    if ! curl -fsSL "${bin_url}" -o "${out_bin}" 2>/dev/null; then
        bin_url="${TAG_RELEASE_BASE}/${BINARY_FILENAME}"
        sum_url="${TAG_RELEASE_BASE}/SHA256SUMS"
        log_info "Chuyển sang đường dẫn tag ${RELEASE_TAG}: ${bin_url}" >&2
        curl -fsSL "${bin_url}" -o "${out_bin}"
    fi

    if curl -fsSL "${sum_url}" -o "${out_sum}" 2>/dev/null; then
        verify_checksum_if_available "${TMP_WORK_DIR}" "${BINARY_FILENAME}" "${out_sum}" || return 1
    elif [[ -f "${SCRIPT_DIR}/SHA256SUMS" ]]; then
        verify_checksum_if_available "${TMP_WORK_DIR}" "${BINARY_FILENAME}" "${SCRIPT_DIR}/SHA256SUMS" || return 1
    else
        log_warn "Không tải được tệp SHA256SUMS từ xa, bỏ qua bước đối chiếu checksum." >&2
    fi

    echo "${out_bin}"
    return 0
}

resolve_binary_source() {
    if [[ -n "${SPANEL_BINARY_SOURCE:-}" && -f "${SPANEL_BINARY_SOURCE}" ]]; then
        echo "${SPANEL_BINARY_SOURCE}"
        return 0
    fi
    local candidates=(
        "${SCRIPT_DIR}/${BINARY_FILENAME}"
        "${SCRIPT_DIR}/spanel"
        "${REPO_ROOT}/dist/${BINARY_FILENAME}"
        "${REPO_ROOT}/target/${TARGET_ARCH}-unknown-linux-gnu/release/spanel"
        "${REPO_ROOT}/target/release/spanel"
    )
    for candidate in "${candidates[@]}"; do
        if [[ -f "${candidate}" ]]; then
            local cand_dir
            cand_dir="$(cd "$(dirname "${candidate}")" && pwd)"
            if [[ "$(basename "${candidate}")" == "${BINARY_FILENAME}" && -f "${cand_dir}/SHA256SUMS" ]]; then
                verify_checksum_if_available "${cand_dir}" "${BINARY_FILENAME}" "${cand_dir}/SHA256SUMS" || return 1
            fi
            echo "${candidate}"
            return 0
        fi
    done

    download_release_binary
}

BIN_SRC="$(resolve_binary_source || true)"
if [[ -z "${BIN_SRC}" || ! -f "${BIN_SRC}" ]]; then
    log_err "Không thể tìm thấy hoặc tải về file binary SPanel cho kiến trúc ${TARGET_ARCH}."
    exit 1
fi

log_info "Đang cài đặt binary vào '${INSTALL_BIN}'..."
if systemctl is-active --quiet spanel.service 2>/dev/null; then
    log_info "Tạm dừng dịch vụ spanel.service để cập nhật binary..."
    systemctl stop spanel.service
fi

install -m 0755 "${BIN_SRC}" "${INSTALL_BIN}"
ln -sf "${INSTALL_BIN}" "${SYMLINK_SP}"
log_ok "Đã cài đặt ${INSTALL_BIN} và tạo lệnh tắt ${SYMLINK_SP} -> ${INSTALL_BIN}"

mkdir -p "${DATA_DIR}" "${DATA_DIR}/backups" "${DATA_DIR}/cron_logs"
chmod 0750 "${DATA_DIR}"
log_ok "Đã chuẩn bị thư mục dữ liệu: ${DATA_DIR}"

if [[ -f "${SCRIPT_DIR}/spanel.service" ]]; then
    install -m 0644 "${SCRIPT_DIR}/spanel.service" "${SERVICE_PATH}"
else
    cat > "${SERVICE_PATH}" <<'EOF'
[Unit]
Description=SPanel - High-Performance Single-Binary Server Control Panel
Documentation=https://github.com/lucaslong24/spanel-rust
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/var/lib/spanel
Environment="SPANEL_DATA_DIR=/var/lib/spanel"
Environment="SPANEL_HOST=0.0.0.0"
Environment="SPANEL_LOG=info"
ExecStart=/usr/local/bin/spanel start
Restart=on-failure
RestartSec=3
TimeoutStopSec=15
LimitNOFILE=65535
NoNewPrivileges=false

[Install]
WantedBy=multi-user.target
EOF
    chmod 0644 "${SERVICE_PATH}"
fi

systemctl daemon-reload
systemctl enable spanel.service >/dev/null 2>&1 || true
systemctl restart spanel.service

sleep 1
if ! systemctl is-active --quiet spanel.service; then
    log_err "Dịch vụ spanel.service không thể khởi chạy. Kiểm tra 'journalctl -u spanel -n 50'."
    exit 1
fi
log_ok "Dịch vụ spanel.service đã khởi chạy thành công (active/running)."

PANEL_PORT="$(SPANEL_DATA_DIR="${DATA_DIR}" "${INSTALL_BIN}" status 2>/dev/null | awk -F'Cổng|Port' 'NF>1{print $2; exit}' | grep -oE '[0-9]+' | head -n1 || echo "8888")"
SSH_PORT="$(awk '/^[[:space:]]*Port[[:space:]]+[0-9]+/{print $2; exit}' /etc/ssh/sshd_config 2>/dev/null || echo "22")"
[[ -z "${PANEL_PORT}" ]] && PANEL_PORT="8888"
[[ -z "${SSH_PORT}" ]] && SSH_PORT="22"

# Mở cổng an toàn trên UFW và đồng bộ systemd ufw.service
if command -v ufw >/dev/null 2>&1; then
    if ufw status 2>/dev/null | grep -q "Status: active"; then
        ufw allow "${SSH_PORT}/tcp" >/dev/null 2>&1 || true
        ufw allow "${PANEL_PORT}/tcp" >/dev/null 2>&1 || true
        systemctl enable --now ufw >/dev/null 2>&1 || true
        log_ok "Đã đảm bảo cổng SSH (${SSH_PORT}/tcp), cổng SPanel (${PANEL_PORT}/tcp) trên UFW và đồng bộ systemd ufw.service."
    fi
fi

# Xử lý rule iptables chặn cứng (như Oracle Cloud iptables-persistent: -j REJECT --reject-with icmp-host-prohibited)
ensure_iptables_accept_before_reject() {
    local port="$1"
    local proto="${2:-tcp}"
    local reject_line
    reject_line="$(iptables -S INPUT 2>/dev/null | tail -n +2 | grep -nE '^-A INPUT (.* )?-j (REJECT|DROP)' | head -n1 | cut -d: -f1 || true)"
    [[ -z "${reject_line}" ]] && return 0

    if iptables -S INPUT 2>/dev/null | tail -n +2 | head -n "$((reject_line - 1))" | grep -qE -- "-p ${proto} .*--dport ${port}([[:space:]]|$).* -j ACCEPT"; then
        return 0
    fi
    iptables -I INPUT "${reject_line}" -p "${proto}" -m state --state NEW -m "${proto}" --dport "${port}" -j ACCEPT 2>/dev/null \
        || iptables -I INPUT "${reject_line}" -p "${proto}" --dport "${port}" -j ACCEPT 2>/dev/null \
        || true
}

if command -v iptables >/dev/null 2>&1; then
    if iptables -S INPUT 2>/dev/null | grep -qE '^-A INPUT (.* )?-j (REJECT|DROP)'; then
        log_warn "Phát hiện rule iptables INPUT chặn cứng (ví dụ Oracle Cloud). Đang chèn quy tắc mở cổng an toàn trước dòng REJECT..."
        for p in "${SSH_PORT}" "${PANEL_PORT}" 80 443; do
            ensure_iptables_accept_before_reject "${p}" "tcp"
        done
        if command -v netfilter-persistent >/dev/null 2>&1; then
            netfilter-persistent save >/dev/null 2>&1 || true
        fi
        log_ok "Đã thông cổng SSH (${SSH_PORT}), SPanel (${PANEL_PORT}), 80, 443 trên iptables INPUT."
    fi
fi

echo ""
echo -e "${BOLD_GREEN}==========================================================${RESET}"
echo -e "${BOLD_GREEN}      🎉 CÀI ĐẶT SPANEL 1.0 HOÀN TẤT THÀNH CÔNG!          ${RESET}"
echo -e "${BOLD_GREEN}==========================================================${RESET}"
SPANEL_DATA_DIR="${DATA_DIR}" "${INSTALL_BIN}" info
echo -e "${BOLD_CYAN}----------------------------------------------------------${RESET}"
echo -e "💡 Gõ lệnh ${BOLD_GREEN}sp${RESET} (hoặc ${BOLD_GREEN}spanel${RESET}) bất cứ lúc nào để mở Menu Quản Trị Nhanh!"
echo -e "${BOLD_GREEN}==========================================================${RESET}"
