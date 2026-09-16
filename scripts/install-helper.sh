#!/usr/bin/env bash
set -euo pipefail

repo="${STRICT_IME_REPO:-vvinnpy/strict-ime.nvim}"
case "$(uname -m)" in
  x86_64|amd64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

target="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/strict-ime/strict-ime-helper-linux-$arch"
mkdir -p "$(dirname "$target")"
curl -fL "https://github.com/$repo/releases/latest/download/strict-ime-helper-linux-$arch" -o "$target"
chmod +x "$target"
echo "$target"
