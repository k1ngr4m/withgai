#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF_ROOT="$ROOT_DIR/DataTables"
CODE_OUT="$ROOT_DIR/Scripts/Generated/Config"
DATA_OUT="$ROOT_DIR/Data/Generated/Config"

if [[ -z "${LUBAN_DLL:-}" ]]; then
  echo "LUBAN_DLL is not set. Install Luban 4.x and run:"
  echo "  LUBAN_DLL=/path/to/Luban.dll DataTables/gen_client.sh"
  echo "Refreshing generated prototype JSON with Tools/build_config.mjs instead."
  node "$ROOT_DIR/Tools/build_config.mjs"
  exit 0
fi

mkdir -p "$CODE_OUT" "$DATA_OUT"
dotnet "$LUBAN_DLL" \
  -t client \
  -c gdscript-json \
  -d json \
  --conf "$CONF_ROOT/luban.conf" \
  -x outputCodeDir="$CODE_OUT" \
  -x outputDataDir="$DATA_OUT"
