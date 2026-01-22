#!/usr/bin/env bash
set -euo pipefail

DATE=$(date +%Y%m%d)
OUTDIR="out/${ARCH}/${CONFIG}/${DATE}"

mkdir -p "$OUTDIR"

export KERNEL_OUT="$OUTDIR"
export LOG_FILE="$OUTDIR/build.log"

# --------------------------------------------------
# Toolchain selection (single source of truth)
# --------------------------------------------------
case "${ARCH}" in
  x86_64)
    export ARCH=x86_64
    export CROSS_COMPILE=""
    ;;
  arm)
    export ARCH=arm
    export CROSS_COMPILE=arm-linux-gnueabihf-
    ;;
  arm64)
    export ARCH=arm64
    export CROSS_COMPILE=aarch64-linux-gnu-
    ;;
  riscv64)
    export ARCH=riscv
    export CROSS_COMPILE=riscv64-linux-gnu-
    ;;
  *)
    echo "Unsupported ARCH=$ARCH"
    exit 1
    ;;
esac
