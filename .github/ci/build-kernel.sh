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

# config seed to have re-producible build
if [ "$CONFIG" = "randconfig" ]; then
  export KCONFIG_SEED=${KCONFIG_SEED:-0x$(date +%Y%m%d)}
  echo "SEED=$KCONFIG_SEED"
fi

case "${CI_PROFILE}" in
  stable)
    MAKE_FLAGS=""
    ;;
  stress)
    MAKE_FLAGS="W=1 C=1"
    ;;
esac

# Configure
make O="$KERNEL_OUT" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" "$CONFIG"

FILTER_REGEX="error:|fatal error|undefined reference|warning:|objtool:|VMLINUX:"

# Build
make -j$(nproc) \
  O="$KERNEL_OUT" \
  ARCH="$ARCH" \
  CROSS_COMPILE="$CROSS_COMPILE" \
  $MAKE_FLAGS \
  2>&1 | tee "$LOG_FILE" | \
  grep -Ei --color=always "$FILTER_REGEX" \
  || true

# Optional: remove headers and scripts
rm -rf "$KERNEL_OUT"/{scripts,tools,include}
# Modules
make O="$KERNEL_OUT" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" \
  INSTALL_MOD_PATH="$KERNEL_OUT/modules" \
  modules_install

# Pruning Build Output
find "$KERNEL_OUT" -type f \
  \( -name "*.o" \
     -o -name "*.cmd" \
     -o -name "*.a" \
     -o -name "*.symversions" \
     -o -name "vmlinux" \
  \) -delete
