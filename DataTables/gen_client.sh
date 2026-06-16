#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF_ROOT="$ROOT_DIR/DataTables"
CODE_OUT="$ROOT_DIR/Scripts/Generated/Config"
DATA_OUT="$ROOT_DIR/Data/Generated/Config"

node "$ROOT_DIR/Tools/build_config.mjs"

LOCAL_LUBAN_DLL="$ROOT_DIR/Tools/Luban/Luban.dll"
if [[ -z "${LUBAN_DLL:-}" && -f "$LOCAL_LUBAN_DLL" ]]; then
  LUBAN_DLL="$LOCAL_LUBAN_DLL"
fi

if [[ -z "${LUBAN_DLL:-}" ]]; then
  echo "LUBAN_DLL is not set. Install Luban 4.x and run:"
  echo "  LUBAN_DLL=/path/to/Luban.dll DataTables/gen_client.sh"
  echo "Refreshed generated prototype JSON with Tools/build_config.mjs instead."
  exit 0
fi

DOTNET_BIN="${DOTNET_BIN:-}"
if [[ -z "$DOTNET_BIN" ]]; then
  if [[ -x "$ROOT_DIR/Tools/dotnet/dotnet" ]]; then
    DOTNET_BIN="$ROOT_DIR/Tools/dotnet/dotnet"
  elif [[ -x "$HOME/.dotnet/dotnet" ]]; then
    DOTNET_BIN="$HOME/.dotnet/dotnet"
  else
    DOTNET_BIN="dotnet"
  fi
fi

mkdir -p "$CODE_OUT" "$DATA_OUT"
"$DOTNET_BIN" "$LUBAN_DLL" \
  -t client \
  -c gdscript-json \
  -d json \
  --conf "$CONF_ROOT/luban.conf" \
  -x outputCodeDir="$CODE_OUT" \
  -x outputDataDir="$DATA_OUT"

node "$ROOT_DIR/Tools/pack_luban_config.mjs"
