#!/usr/bin/env bash
set -euo pipefail

files=("$@")
if [[ "${#files[@]}" -eq 0 ]]; then
  while IFS= read -r -d '' file; do
    files+=("${file}")
  done < <(find . -type f -name '*.lua' -not -path './.git/*' -print0)
fi

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "No Lua files to check."
  exit 0
fi

for file in "${files[@]}"; do
  if [[ ! -f "${file}" ]]; then
    continue
  fi

  LUA_FILE="${file}" lua <<'LUA'
local path = os.getenv("LUA_FILE")
local fh, err = io.open(path, "rb")
if not fh then
  error(string.format("cannot open %s: %s", path, err or "unknown"))
end

local src = fh:read("*a") or ""
fh:close()

-- Strip UTF-8 BOM if present for Lua 5.1 parser compatibility.
if src:sub(1, 3) == "\239\187\191" then
  src = src:sub(4)
end

local loader = loadstring or load
local chunk, parseErr = loader(src, "@" .. path)
if not chunk then
  error(parseErr)
end
LUA
done

echo "Lua syntax check passed for ${#files[@]} file(s)."
