#!/usr/bin/env bash
set -euo pipefail

VERSION_URL="${WOW_UI_VERSION_URL:-https://raw.githubusercontent.com/Gethe/wow-ui-source/live/version.txt}"

version_raw="$(curl -fsSL "${VERSION_URL}" | tr -d '\r\n')"
if [[ ! "${version_raw}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\.[0-9]+$ ]]; then
  echo "Unexpected version format from ${VERSION_URL}: ${version_raw}" >&2
  exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"
retail_version="${major}.${minor}.${patch}"
interface="$(printf '%d%02d%02d' "${major}" "${minor}" "${patch}")"

echo "version_raw=${version_raw}"
echo "retail_version=${retail_version}"
echo "interface=${interface}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "version_raw=${version_raw}"
    echo "retail_version=${retail_version}"
    echo "interface=${interface}"
  } >> "${GITHUB_OUTPUT}"
fi
