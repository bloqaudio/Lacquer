#!/usr/bin/env bash
set -euo pipefail

TOC_FILE="${TOC_FILE:-Lacquer.toc}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "${TOC_FILE}" ]]; then
  echo "TOC file not found: ${TOC_FILE}" >&2
  exit 1
fi

while IFS='=' read -r key value; do
  case "${key}" in
    version_raw) version_raw="${value}" ;;
    interface) new_interface="${value}" ;;
  esac
done < <("${SCRIPT_DIR}/retail-release-metadata.sh")

current_interface="$(awk -F': *' '/^## Interface:/{gsub(/\r/, "", $2); print $2; exit}' "${TOC_FILE}")"
if [[ -z "${current_interface}" ]]; then
  echo "Could not read current interface value from ${TOC_FILE}" >&2
  exit 1
fi

changed=false
if [[ "${current_interface}" != "${new_interface}" ]]; then
  sed -i -E "s/^## Interface:[[:space:]]*[0-9]+/## Interface: ${new_interface}/" "${TOC_FILE}"
  changed=true
fi

echo "version_raw=${version_raw}"
echo "current_interface=${current_interface}"
echo "new_interface=${new_interface}"
echo "changed=${changed}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "version_raw=${version_raw}"
    echo "current_interface=${current_interface}"
    echo "new_interface=${new_interface}"
    echo "changed=${changed}"
  } >> "${GITHUB_OUTPUT}"
fi
