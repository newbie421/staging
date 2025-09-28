#!/usr/bin/env bash
set -euo pipefail

# ---------- minimal config / fallback ----------
# TARGET = device name (marble / cupid / ...)
TARGET="${1:-${TARGET:-}}"

# SRC_ROOT: optional, provided via workflow env. If empty -> use repo root (GITHUB_WORKSPACE)
SRC_ROOT="${SRC_ROOT:-${GITHUB_WORKSPACE:-$(pwd)}}"

# KP_ROOT: kernel project root (repo root by default)
KP_ROOT="${KP_ROOT:-${SRC_ROOT}}"

# Where workflow extracts LLVM (toolchain)
TC_DIR="${TC_DIR:-${HOME}/toolchains/llvm-21}"

# prebuilt kernel build-tools (optional; some repos provide these)
PREBUILTS_DIR="${PREBUILTS_DIR:-${KP_ROOT}/prebuilts/kernel-build-tools/linux-x86}"

# number of parallel jobs (default small to avoid OOM on runners)
JOBS="${JOBS:-${JOBS:-2}}"

LOG_FILE="${OUT_LOG:-out/build.log}"
mkdir -p "$(dirname "${LOG_FILE}")"
: > "${LOG_FILE}"

echo
echo "[INFO] build.sh starting"
echo "[INFO] TARGET=${TARGET:-'(none)'}"
echo "[INFO] SRC_ROOT=${SRC_ROOT}"
echo "[INFO] KP_ROOT=${KP_ROOT}"
echo "[INFO] TC_DIR=${TC_DIR}"
echo "[INFO] JOBS=${JOBS}"
echo

# export PATH so clang/ld.lld from downloaded LLVM is visible
export PATH="${TC_DIR}/bin:${PATH}"

export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="github-actions"
export KBUILD_BUILD_HOST="github"

export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export CC="${CC:-clang}"
export LD="${LD:-ld.lld}"
export AR="${AR:-llvm-ar}"
export NM="${NM:-llvm-nm}"
export OBJCOPY="${OBJCOPY:-llvm-objcopy}"
export OBJDUMP="${OBJDUMP:-llvm-objdump}"
export READELF="${READELF:-llvm-readelf}"
export STRIP="${STRIP:-llvm-strip}"

# helper for make (log capture)
m() {
  make -j"${JOBS}" O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 \
    DTC_EXT="${PREBUILTS_DIR}/bin/dtc" \
    DTC_OVERLAY_TEST_EXT="${PREBUILTS_DIR}/bin/ufdt_apply_overlay" \
    "$@" 2>&1 | tee -a "${LOG_FILE}" || { echo "[ERROR] make failed ($?)"; tail -n 200 "${LOG_FILE}"; exit 1; }
}

# If user did not pass TARGET, exit with message
if [ -z "${TARGET}" ]; then
  echo "[ERROR] No target device specified. Usage: ./build.sh <device>"
  exit 1
fi

# check SRC_ROOT exists
if [ ! -d "${SRC_ROOT}" ]; then
  echo "[ERROR]
