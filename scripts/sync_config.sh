#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.."; pwd)"
SRC="$ROOT/config"
DST="$ROOT/app/tapcapsule/assets/config"

mkdir -p "$DST"
cp -v "$SRC/abi.json" "$DST/abi.json"
cp -v "$SRC/addresses.json" "$DST/addresses.json"

echo "Sincronizzati abi.json e addresses.json -> assets/config/"
