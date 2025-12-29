#!/bin/bash
set -e

echo "=========================================="
echo "Building RG353V Firmware"
echo "=========================================="

# GO TO THE ACTUAL BUILDROOT DIRECTORY
cd /home/builder/work/rg353v-custom/buildroot

if [ "$1" = "clean" ]; then
    echo "Performing distclean (complete clean)..."
    make BR2_EXTERNAL=/home/builder/work/rg353v-custom distclean || true
fi

# Apply defconfig with correct BR2_EXTERNAL path
echo "Applying rg353v_defconfig..."
make BR2_EXTERNAL=/home/builder/work/rg353v-custom rg353v_defconfig

echo ""
echo "Build configuration:"
echo "  Target: ARM64 (Cortex-A55)"
echo "  Toolchain: Bootlin external"
echo "  Kernel: 6.1.50"
echo "  U-Boot: 2023.07"
echo ""

NUM_CORES=$(nproc)
echo "Building with $NUM_CORES CPU cores..."
echo "This will take 30-45 minutes on first build."
echo ""

# Build
make BR2_EXTERNAL=/home/builder/work/rg353v-custom -j$NUM_CORES 2>&1 | tee /home/builder/work/build.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ Build Complete!"
    echo "=========================================="
    echo ""
    echo "Output images:"
    ls -lh output/images/
else
    echo ""
    echo "✗ Build Failed - check build.log"
    exit 1
fi
