#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# SPanel 1.0 — Clean Uninstaller
# Usage: sudo bash uninstall.sh [--purge] [--purge-sites] [--yes]
# ==============================================================================

BOLD_CYAN="\033[1;36m"
BOLD_GREEN="\033[1;32m"
BOLD_YELLOW="\033[1;33m"
BOLD_RED="\033[1;31m"
RESET="\033[0m"

INSTALL_BIN="/usr/local/bin/spanel"
SYMLINK_SP="/usr/local/bin/sp"
DATA_DIR="${SPANEL_DATA_DIR:-/var/lib/spanel}"
WWW_ROOT="/www"
WWW_WWWROOT="/www/wwwroot"
WWW_BACKUP="/www/backup"
WWW_RECYCLE="/www/.Recycle_bin"
SERVICE_PATH="/etc/systemd/system/spanel.service"
PURGE_DATA="false"
PURGE_SITES="false"
ASSUME_YES="false"

for arg in "$@"; do
    case "${arg}" in
        --purge)
            PURGE_DATA="true"
            ;;
        --purge-sites)
            PURGE_DATA="true"
            PURGE_SITES="true"
            ;;
        --yes|-y)
            ASSUME_YES="true"
            ;;
    esac
done

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo -e "${BOLD_RED}[ERROR]${RESET} Vui lòng chạy kịch bản gỡ cài đặt dưới quyền root (sudo bash uninstall.sh)." >&2
    exit 1
fi

is_dir_empty() {
    local d="$1"
    [[ -d "${d}" ]] && [[ -z "$(ls -A "${d}" 2>/dev/null || true)" ]]
}

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
        echo -e "${BOLD_YELLOW}[PURGED]${RESET} Đã xóa thư mục dữ liệu ${DATA_DIR}"
    fi
    if [[ -d "${WWW_RECYCLE}" ]]; then
        rm -rf "${WWW_RECYCLE}"
        echo -e "${BOLD_YELLOW}[PURGED]${RESET} Đã xóa thùng rác ${WWW_RECYCLE}"
    fi
    if [[ -d "${WWW_BACKUP}" ]] && (is_dir_empty "${WWW_BACKUP}" || [[ "${PURGE_SITES}" == "true" ]]); then
        rm -rf "${WWW_BACKUP}"
        echo -e "${BOLD_YELLOW}[PURGED]${RESET} Đã xóa ${WWW_BACKUP}"
    fi
    if [[ -d "${WWW_WWWROOT}" ]]; then
        if is_dir_empty "${WWW_WWWROOT}" || [[ "${PURGE_SITES}" == "true" ]]; then
            rm -rf "${WWW_WWWROOT}"
            echo -e "${BOLD_YELLOW}[PURGED]${RESET} Đã xóa ${WWW_WWWROOT}"
        elif [[ "${ASSUME_YES}" != "true" && -t 0 ]]; then
            echo -e "${BOLD_RED}[CẢNH BÁO]${RESET} Thư mục ${WWW_WWWROOT} đang chứa dữ liệu website của bạn!"
            read -r -p "Bạn có CHẮC CHẮN muốn xóa vĩnh viễn toàn bộ mã nguồn trong ${WWW_WWWROOT}? [y/N]: " CONFIRM_SITES
            if [[ "${CONFIRM_SITES,,}" == "y" || "${CONFIRM_SITES,,}" == "yes" ]]; then
                rm -rf "${WWW_WWWROOT}"
                echo -e "${BOLD_RED}[PURGED]${RESET} Đã xóa toàn bộ ${WWW_WWWROOT}"
            else
                echo -e "${BOLD_GREEN}[PROTECTED]${RESET} Đã giữ an toàn mã nguồn tại ${WWW_WWWROOT}"
            fi
        else
            echo -e "${BOLD_YELLOW}[PROTECTED]${RESET} Thư mục ${WWW_WWWROOT} đang có dữ liệu nên được giữ an toàn (thêm '--purge-sites' nếu muốn xóa)."
        fi
    fi
    if is_dir_empty "${WWW_ROOT}"; then
        rmdir "${WWW_ROOT}" 2>/dev/null || true
    fi
else
    echo -e "${BOLD_YELLOW}[INFO]${RESET} Thư mục dữ liệu '${DATA_DIR}' và '${WWW_ROOT}' vẫn được giữ an toàn (dùng '--purge' để dọn dữ liệu SPanel)."
fi

echo -e "${BOLD_GREEN}✅ Đã gỡ cài đặt SPanel hoàn tất.${RESET}"
