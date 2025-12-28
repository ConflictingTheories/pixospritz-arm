#!/bin/bash
# This script runs INSIDE the Docker container
# It's designed to be run multiple times without issues

set -e

echo "=========================================="
echo "Building RG353V Firmware"
echo "=========================================="

# Navigate to buildroot directory
cd /home/builder/work/rg353v-custom/buildroot/buildroot-2024.02.1

# Only clean if explicitly requested
if [ "$1" = "clean" ]; then
    echo "Performing clean build..."
    make clean
fi

# Apply configuration
echo "Applying rg353v_defconfig..."
make BR2_EXTERNAL=/home/builder/work/rg353v-custom rg353v_defconfig

# Show configuration summary
echo ""
echo "Build configuration:"
echo "  Target: ARM64 (Cortex-A55)"
echo "  Toolchain: External (Bootlin)"
echo "  Kernel: 6.1.50"
echo "  U-Boot: 2023.07"
echo ""

# Build with all available cores
NUM_CORES=$(nproc)
echo "Building with $NUM_CORES CPU cores..."
echo "This will take 30-45 minutes on first build."
echo "Subsequent builds will be much faster (incremental)."
echo ""

# Run the build and capture output
make -j$NUM_CORES 2>&1 | tee /home/builder/work/build.log

# Check if build succeeded
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ Build Complete!"
    echo "=========================================="
    echo ""
    echo "Output images:"
    ls -lh output/images/ 2>/dev/null || echo "No images found in output/images/"
    echo ""
    echo "Files are in: rg353v-custom/buildroot/buildroot-2024.02.1/output/images/"
else
    echo ""
    echo "=========================================="
    echo "✗ Build Failed!"
    echo "=========================================="
    echo ""
    echo "Check the build log at: build.log"
    exit 1
fi
