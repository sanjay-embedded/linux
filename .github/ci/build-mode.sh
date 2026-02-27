#!/usr/bin/env bash
set -euo pipefail

# Inputs (from CI)
: "${CI_STAGE:?CI_STAGE not set}"

# Set default values
ARCH=${ARCH:-x86_64}
CONFIG=${CONFIG:-defconfig}

source .github/ci/common.sh

echo "=================================================="
echo " Kernel CI Stage Execution"
echo " ARCH          : $ARCH"
echo " CONFIG        : $CONFIG"
echo " CI_STAGE      : $CI_STAGE"
echo " CROSS_COMPILE : $CROSS_COMPILE"
echo " OUTDIR        : $KERNEL_OUT"
echo "=================================================="

BUILD_DIR="$KERNEL_OUT/$CI_STAGE"
mkdir -p "$BUILD_DIR"

case "$CI_STAGE" in

  # -----------------------------------------
  # 1️⃣ Documentation (htmldocs)
  # -----------------------------------------
  doc)
    make O="$BUILD_DIR" "$CONFIG"

    echo "==> Building HTML documentation"
    make -j$(nproc) O="$BUILD_DIR" htmldocs |& tee -a "$LOG_FILE"
    ;;

  # -----------------------------------------
  # 2️⃣ Coccicheck (semantic analysis)
  # -----------------------------------------
  cocci)
    make O="$BUILD_DIR" "$CONFIG"

    echo "==> Running coccicheck (MODE=report)"
    make -j$(nproc) O="$BUILD_DIR" coccicheck MODE=report |& tee -a "$LOG_FILE"
    ;;

  # -----------------------------------------
  # 3️⃣ Clang Build
  # -----------------------------------------
  clang)
    make O="$BUILD_DIR" "$CONFIG"

    echo "==> Building kernel with Clang"
    make -j$(nproc) O="$BUILD_DIR" CC=clang |& tee -a "$LOG_FILE"
    ;;

  # -----------------------------------------
  # 4️⃣ kselftest Build
  # -----------------------------------------
  kselftest)
    make O="$BUILD_DIR" "$CONFIG"

kselftest)
    make O="$BUILD_DIR" "$CONFIG"

    TESTS=(
        mm
        timers
        seccomp
        rseq
        size
        proc
        drivers
        iommu
    )

    for t in "${TESTS[@]}"; do
        echo "==> Building kselftest-$t"
        make -j"$(nproc)" O="$BUILD_DIR" kselftest-$t |& tee -a "$LOG_FILE

        # status=${PIPESTATUS[0]}
        # if [ $status -ne 0 ]; then
        #     echo "kselftest-$t failed"
        #     exit $status
        # fi
    done
    ;;
    
    echo "==> Building kselftest"
    make -j$(nproc) O="$BUILD_DIR" kselftest |& tee -a "$LOG_FILE"
    ;;

  *)
    echo "ERROR: Unknown CI_STAGE=$CI_STAGE"
    exit 1
    ;;
esac

echo "=================================================="
echo " CI Stage '$CI_STAGE' completed successfully"
echo "=================================================="
