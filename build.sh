#!/bin/bash
set -euo pipefail

echo -e "\n[INFO]: BUILD STARTED..!\n"

KERNEL_ROOT="$(pwd)"
OUT_DIR="${KERNEL_ROOT}/out"
BUILD_DIR="${KERNEL_ROOT}/build"

mkdir -p "$OUT_DIR" "$BUILD_DIR"

export ARCH=arm64
export KBUILD_BUILD_USER="github-actions"
export PATH="$HOME/toolchains/llvm-21/bin:$PATH"
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export CC=clang
export LD=ld.lld

# Defconfig
echo -e "\n[INFO] Running defconfig...\n"
make O="$OUT_DIR" ARCH=arm64 gki_defconfig

# Build kernel
echo -e "\n[INFO] Building kernel...\n"
make -j"$(nproc)" O="$OUT_DIR" ARCH=arm64 LLVM=1 LLVM_IAS=1 Image 2>&1 | tee build.log

# Copy output
if [ -f "$OUT_DIR/arch/arm64/boot/Image" ]; then
    cp "$OUT_DIR/arch/arm64/boot/Image" "$BUILD_DIR/"
    echo -e "\n[INFO]: BUILD FINISHED! Kernel Image available.\n"
else
    echo -e "\n[ERROR]: Kernel Image not found. Check build.log\n"
    exit 1
fi
