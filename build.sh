#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-marble}"
SRC_ROOT="${SRC_ROOT:-$(pwd)}"
TC_DIR="${HOME}/toolchains/llvm-21"
JOBS="${JOBS:-2}"

export PATH="${TC_DIR}/bin:${PATH}"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="github-actions"
export KBUILD_BUILD_HOST="github"
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export CC=clang
export LD=ld.lld

echo "[INFO] TARGET=$TARGET"
echo "[INFO] SRC_ROOT=$SRC_ROOT"
echo "[INFO] TC_DIR=$TC_DIR"
echo "[INFO] JOBS=$JOBS"

cd "$SRC_ROOT"

mkdir -p out build

make O=out ARCH=arm64 gki_defconfig
make -j"$JOBS" O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 Image

if [ -f out/arch/arm64/boot/Image ]; then
  cp out/arch/arm64/boot/Image build/
  echo "[INFO] Build finished, Image in build/"
else
  echo "[ERROR] Kernel Image not found"
  exit 1
fi
