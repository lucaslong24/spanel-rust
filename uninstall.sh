#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# SPanel 1.0 — Clean Uninstaller
# Usage: sudo bash uninstall.sh [--purge]
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
PURGE_DATA="false"

for arg in "$@"; do
    case "${arg}" in
        --purge)
            PURGE_DATA="true"
            ;;
    esac
done

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo -e "${BOLD_RED}[ERROR]${RESET} Vui lòng chạy kịch bản gỡ cài đặt dưới quyền root (sudo bash uninstall.sh)." >&2
    exit 1
fi

echo -e "${BOLD_CYAN}[SPanel]${RESET} Đang dừng và gỡ bỏ dịch vụ spanel.service..."
if systemctl list-unit-files 2>/dev/null | grep -q "^spanel\.service"; then
    systemctl stop spanel.service 2>/dev/null || true
    systemctl disable spanel.service 2>/dev/null || true
fi

if [[ -f "${SERVICE_PATH}" ]]; then
    rm -f "${SERVICE_PATH}"
    systemctl daemon-reload 2>/dev/null || true
    echo -e "${BOLD_GREEN}[OK]${RESET} Đã xóa ${SERVICE_PATH}"
fi

if [[ -L "${SYMLINK_SP}" || -f "${SYMLINK_SP}" ]]; then
    rm -f "${SYMLINK_SP}"
    echo -e "${BOLD_GREEN}[OK]${RESET} Đã xóa symlink ${SYMLINK_SP}"
fi

if [[ -f "${INSTALL_BIN}" ]]; then
    rm -f "${INSTALL_BIN}"
    echo -e "${BOLD_GREEN}[OK]${RESET} Đã xóa binary ${INSTALL_BIN}"
fi

if [[ "${PURGE_DATA}" == "true" ]]; then
    if [[ -d "${DATA_DIR}" ]]; then
        rm -rf "${DATA_DIR}"
        echo -e "${BOLD_YELLOW}[PURGED]${RESET} Đã xóa hoàn toàn thư mục dữ liệu ${DATA_DIR}"
    fi
else
    echo -e "${BOLD_YELLOW}[INFO]${RESET} Thư mục dữ liệu '${DATA_DIR}' vẫn được giữ an toàn (dùng '--purge' nếu muốn xóa toàn bộ dữ liệu)."
fi

echo -e "${BOLD_GREEN}✅ Đã gỡ cài đặt SPanel hoàn tất.${RESET}"
