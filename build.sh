#!/usr/bin/env bash
# Build ZMK firmware locally in a container (no host toolchain needed).
#
# Usage: ./build.sh <keyboard>        e.g. ./build.sh corne
#   Builds every build.yaml target whose artifact-name matches the keyboard
#   (e.g. corne -> corne_left, corne_right) and writes firmware/<name>.uf2.
#
# Env: ZMK_RUNTIME=docker|podman   (default: auto-detect, prefer docker)
#      ZMK_IMAGE=<image>           (default: zmkfirmware/zmk-build-arm:stable)
#      PRISTINE=1                  (force a clean rebuild)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="${ZMK_IMAGE:-zmkfirmware/zmk-build-arm:stable}"
VOLUME="zmk-config-west"

kb="${1:-}"
if [ -z "$kb" ]; then
  echo "usage: $(basename "$0") <keyboard>" >&2
  echo "keyboards in build.yaml:" >&2
  grep 'artifact-name:' "$REPO/build.yaml" | sed 's/.*artifact-name: *//; s/_.*//' \
    | sort -u | sed 's/^/  /' >&2
  exit 2
fi

RUNTIME="${ZMK_RUNTIME:-}"
if [ -z "$RUNTIME" ]; then
  if   command -v docker >/dev/null 2>&1; then RUNTIME=docker
  elif command -v podman >/dev/null 2>&1; then RUNTIME=podman
  else echo "error: need docker or podman on PATH" >&2; exit 1; fi
fi

mkdir -p "$REPO/firmware"
do_chown=0; [ "$RUNTIME" = docker ] && do_chown=1

"$RUNTIME" run --rm -i \
  --security-opt label=disable \
  -v "$VOLUME":/workspace \
  -v "$REPO/config":/workspace/config:ro \
  -v "$REPO/build.yaml":/build.yaml:ro \
  -v "$REPO/firmware":/firmware \
  -w /workspace \
  -e KEYBOARD="$kb" \
  -e PRISTINE="${PRISTINE:-0}" \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" -e DO_CHOWN="$do_chown" \
  "$IMAGE" bash -euo pipefail -s <<'CONTAINER'
[ -e /workspace/.west/config ] || west init -l config
west update
west zephyr-export

pristine=""; [ "$PRISTINE" = 1 ] && pristine="-p"

python3 - "$KEYBOARD" <<'PY' > /tmp/targets.tsv
import sys, yaml
kb = sys.argv[1]
data = yaml.safe_load(open("/build.yaml")) or {}
for e in data.get("include", []):
    art = e.get("artifact-name") or e["shield"].split()[0]
    if art == kb or art.startswith(kb + "_"):
        print("\t".join([art, e["board"], e.get("shield", ""),
                         e.get("snippet", ""), e.get("cmake-args", "")]))
PY

if [ ! -s /tmp/targets.tsv ]; then
  echo "no build.yaml targets match keyboard: $KEYBOARD" >&2; exit 1
fi

while IFS=$'\t' read -r art board shield snippet cargs; do
  echo "=== building $art (board=$board shield=$shield) ==="
  snip=""; [ -n "$snippet" ] && snip="-S $snippet"
  west build $pristine -s zmk/app -d "build/$art" -b "$board" $snip -- \
    -DSHIELD="$shield" -DZMK_CONFIG=/workspace/config $cargs
  cp "build/$art/zephyr/zmk.uf2" "/firmware/$art.uf2"
  [ "$DO_CHOWN" = 1 ] && chown "$HOST_UID:$HOST_GID" "/firmware/$art.uf2"
done < /tmp/targets.tsv
CONTAINER

echo
echo "done -> $REPO/firmware/"
ls -1 "$REPO/firmware/"
