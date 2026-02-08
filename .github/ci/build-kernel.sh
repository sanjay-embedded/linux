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
#   MAKE_FLAGS="W=1 C=1"
    MAKE_FLAGS="W=1"
    ;;
esac

# Configure
make O="$KERNEL_OUT" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" "$CONFIG"

FILTER_REGEX="error:|fatal error|undefined reference|warning:|objtool:|VMLINUX:"

# Build Kernel
make -j$(nproc) \
  O="$KERNEL_OUT" \
  ARCH="$ARCH" \
  CROSS_COMPILE="$CROSS_COMPILE" \
  $MAKE_FLAGS >> "$LOG_FILE"

# Optional: post-build highlight (does not affect exit code)
if [[ -n "$FILTER_REGEX" ]]; then
  echo "== Highlighted lines =="
  grep -Ei --color=always "$FILTER_REGEX" "$LOG_FILE" || true
fi

# Skip modules if CONFIG_MODULES is not set to y in the actual .config
if grep -qE '^CONFIG_MODULES=y' "$KERNEL_OUT/.config"; then
  # Build Modules
  make -j$(nproc) \
    O="$KERNEL_OUT" \
    ARCH="$ARCH" \
    CROSS_COMPILE="$CROSS_COMPILE" \
    modules >> "$LOG_FILE"

  # Install Modules
  make -j$(nproc) \
    O="$KERNEL_OUT" \
    ARCH="$ARCH" \
    CROSS_COMPILE="$CROSS_COMPILE" \
    INSTALL_MOD_PATH="$KERNEL_OUT/modules" \
    INSTALL_MOD_STRIP=1 \
    modules_install >> "$LOG_FILE"
else
  echo "== Skipping modules: CONFIG_MODULES is not enabled =="
fi

# Pruning Build Output
find "$KERNEL_OUT" -type f \
  \( -name "*.o" \
     -o -name "*.cmd" \
     -o -name "*.a" \
     -o -name "*.symversions" \
     -o -name "vmlinux" \
  \) -delete
