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
NGINX_AVAIL="${SPANEL_NGINX_AVAIL:-/etc/nginx/sites-available}"
NGINX_ENABLED="${SPANEL_NGINX_ENABLED:-/etc/nginx/sites-enabled}"
NGINX_LOGS="${SPANEL_NGINX_LOGS:-/var/log/nginx}"
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

purge_spanel_nginx_artifacts() {
    local removed=0
    local site_names=()
    local conf fname site target ht

    shopt -s nullglob
    for conf in "${NGINX_AVAIL}"/*.conf "${NGINX_ENABLED}"/*.conf; do
        [[ -f "${conf}" ]] || continue
        if grep -qE '^# (Managed|Generated) by SPanel' "${conf}" 2>/dev/null; then
            fname="$(basename "${conf}")"
            site="${fname%.conf}"
            site_names+=("${site}")
            rm -f "${NGINX_ENABLED}/${fname}" "${NGINX_AVAIL}/${fname}"
            removed=$((removed + 1))
        fi
    done

    for ht in "${NGINX_AVAIL}"/*.htpasswd; do
        [[ -f "${ht}" ]] || continue
        fname="$(basename "${ht}")"
        site="${fname%.htpasswd}"
        if [[ ! -f "${NGINX_AVAIL}/${site}.conf" ]] && ! grep -RqsF "${fname}" "${NGINX_AVAIL}" "${NGINX_ENABLED}" /etc/nginx/conf.d 2>/dev/null; then
            site_names+=("${site}")
            rm -f "${ht}"
            removed=$((removed + 1))
        fi
    done

    for site in "${site_names[@]}"; do
        rm -f "${NGINX_AVAIL}/${site}.htpasswd" "${NGINX_LOGS}/${site}.access.log" "${NGINX_LOGS}/${site}.error.log"
    done

    for target in "${NGINX_ENABLED}"/*; do
        if [[ -L "${target}" && ! -e "${target}" ]]; then
            rm -f "${target}"
            removed=$((removed + 1))
        fi
    done
    shopt -u nullglob

    if [[ "${removed}" -gt 0 ]]; then
        echo -e "${BOLD_YELLOW}[PURGED]${RESET} Đã dọn ${removed} cấu hình Nginx (vhost/log) do SPanel quản lý"
        systemctl reload nginx 2>/dev/null || true
    fi
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
    purge_spanel_nginx_artifacts
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
