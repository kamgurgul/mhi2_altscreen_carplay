#!/usr/bin/env bash
# Build the Audi MHI2Q variant of the AltScreen GEN2 hook.
#
#   tools/build_altscreen111_mhi2q.sh [output.so]
#
# Same GEN2 source as MU1440, compiled with -DALT111_TARGET_MHI2Q (constructor-
# free, PLT interposition, 1440x540 defaults, stream 111 on 7111). Output is
# libaltscreen111_mhi2q.so, meant to be LD_PRELOADed into dio_manager on an Audi
# MHI2Q unit ALONGSIDE the mib2q-carplay-rgi hook.
#
# Two toolchains are supported so this matches whichever the sibling project
# already uses:
#   * TOOLCHAIN=docker (default): the qnx65-armv7-toolchain image that
#     mib2q-carplay-rgi builds with (GCC 8.5). Build it once from
#     https://github.com/luka-dev/qnx65-armv7-toolchain (./host-scripts/qnx-run.sh build).
#   * TOOLCHAIN=qcc: a host QNX 6.5 SDP (qcc on PATH), like build_altscreen111_gen2.sh.
#
# The result is intentionally unstripped (-O2 -g).
set -euo pipefail

SRC_ROOT="${SRC_ROOT:-src/native/altscreen111-gen2}"
OUT="${1:-build/libaltscreen111_mhi2q.so}"
TOOLCHAIN="${TOOLCHAIN:-docker}"
IMG="${IMG:-qnx65-armv7-toolchain:latest}"
SONAME="${SONAME:-libaltscreen111_mhi2q.so}"

SRCS=(
  "$SRC_ROOT/libaltscreen111_gen2.c"
  "$SRC_ROOT/src/alt111_profile.c"
  "$SRC_ROOT/src/alt111_control.c"
  "$SRC_ROOT/src/alt111_video.c"
  "$SRC_ROOT/src/alt111_resync.c"
)

mkdir -p "$(dirname "$OUT")"

case "$TOOLCHAIN" in
qcc)
  QCC="${QCC:-qcc}"
  "$QCC" -shared -fPIC -mfloat-abi=softfp -O2 -g -std=gnu99 -Wall -Wextra \
    -DALT111_TARGET_MHI2Q -I"$SRC_ROOT/include" \
    "${SRCS[@]}" -Wl,-soname,"$SONAME" -lsocket -o "$OUT"
  ;;
docker)
  if ! docker image inspect "$IMG" >/dev/null 2>&1; then
    echo "ERROR: docker image '$IMG' not found."
    echo "Build it once from https://github.com/luka-dev/qnx65-armv7-toolchain : ./host-scripts/qnx-run.sh build"
    exit 1
  fi
  PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
  REL_OUT="${OUT#"$PROJECT_DIR"/}"
  docker run --rm --platform=linux/amd64 -v "$PROJECT_DIR":/src "$IMG" bash -c '
    set -e
    export PATH=/opt/qnx650/host/linux/x86/usr/bin:$PATH
    export QNX_HOST=/opt/qnx650/host/linux/x86 QNX_TARGET=/opt/qnx650/target/qnx6
    CC=arm-unknown-nto-qnx6.5.0eabi-gcc
    cd /src
    "$CC" -shared -fPIC -O2 -g -std=gnu99 -Wall -Wextra \
      -DALT111_TARGET_MHI2Q -I'"$SRC_ROOT"'/include \
      '"${SRCS[*]}"' \
      -Wl,-soname,'"$SONAME"' -lsocket -o '"$REL_OUT"'
  '
  ;;
*)
  echo "ERROR: unknown TOOLCHAIN=$TOOLCHAIN (use docker or qcc)"; exit 2 ;;
esac

echo "built: $OUT (target=mhi2q, soname=$SONAME)"
test -s "$OUT"
# Deliberately no strip.
