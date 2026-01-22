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

# Configure
make O="$KERNEL_OUT" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" "$CONFIG"

# Build
make -j$(nproc) \
  O="$KERNEL_OUT" \
  ARCH="$ARCH" \
  CROSS_COMPILE="$CROSS_COMPILE" \
  2>&1 | tee "$LOG_FILE"

# Modules
make O="$KERNEL_OUT" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" \
  INSTALL_MOD_PATH="$KERNEL_OUT/modules" \
  modules_install
