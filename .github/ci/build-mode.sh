#!/usr/bin/env bash
set -euo pipefail

# Inputs (from CI)
: "${ARCH:?}"
: "${CONFIG:?}"

source .github/ci/common.sh

echo "==> Building kernel"
echo "ARCH=$ARCH"
echo "CONFIG=$CONFIG"
echo "CROSS_COMPILE=$CROSS_COMPILE"
echo "OUT=$KERNEL_OUT"

case "${MODE}" in
  static)
    echo "Running Static Discovery Mode"

    # -------------------------------------------------
    # 1. HTML Documentation
    # -------------------------------------------------
    echo "===== htmldocs =====" | tee -a "$LOG_FILE"
    make O="$KERNEL_OUT/htmldocs" htmldocs -j$(nproc) >> "$LOG_FILE"

    # -------------------------------------------------
    # 2. Clang Build (defconfig)
    # -------------------------------------------------
    echo "===== clang defconfig =====" | tee -a "$LOG_FILE"
    make O="$KERNEL_OUT/$CONFIG" "$CONFIG"
    make O="$KERNEL_OUT/$CONFIG" CC=clang -j$(nproc) >> "$LOG_FILE"

    # -------------------------------------------------
    # 3. Coccicheck (Report Mode Only)
    # -------------------------------------------------
    echo "===== coccicheck report =====" | tee -a "$LOG_FILE"
    make O="$KERNEL_OUT/coccicheck" coccicheck MODE=report >> "$LOG_FILE"

    # -------------------------------------------------
    # 4. kselftest Build Only
    # -------------------------------------------------
    echo "===== kselftest build =====" | tee -a "$LOG_FILE"
    make O="$KERNEL_OUT/kselftest" kselftest >> "$LOG_FILE"

    echo "Static discovery completed"
    ;;
esac
