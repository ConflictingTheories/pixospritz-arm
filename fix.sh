#!/bin/bash
# Complete fix for macOS binary issue

set -e

echo "=========================================="
echo "Fixing macOS Binary Issue"
echo "=========================================="
echo ""
echo "Problem: Buildroot has macOS binaries that can't run in Linux Docker"
echo "Solution: Clean output directory and rebuild in Docker"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Clean the output directory on the host
echo "Step 1: Cleaning buildroot output directory..."
if [ -d "$SCRIPT_DIR/rg353v-custom/buildroot/output" ]; then
    rm -rf "$SCRIPT_DIR/rg353v-custom/buildroot/output"
    echo "  ✓ Removed output/"
fi

if [ -f "$SCRIPT_DIR/rg353v-custom/buildroot/.config" ]; then
    rm -f "$SCRIPT_DIR/rg353v-custom/buildroot/.config"
    rm -f "$SCRIPT_DIR/rg353v-custom/buildroot/.config.old"
    rm -f "$SCRIPT_DIR/rg353v-custom/buildroot/..config.tmp"
    rm -f "$SCRIPT_DIR/rg353v-custom/buildroot/.defconfig"
    echo "  ✓ Removed config files"
fi

# Step 2: Update docker-build.sh
echo ""
echo "Step 2: Updating docker-build.sh..."
cat > "$SCRIPT_DIR/docker-build.sh" << 'BUILD_SCRIPT_EOF'
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
BUILD_SCRIPT_EOF

chmod +x "$SCRIPT_DIR/docker-build.sh"
echo "  ✓ docker-build.sh updated"

echo ""
echo "=========================================="
echo "✓ Fix Complete!"
echo "=========================================="
echo ""
echo "The macOS artifacts have been cleaned."
echo "Now build INSIDE Docker (not on your Mac!):"
echo ""
echo "  docker-compose run --rm buildroot /home/builder/work/docker-build.sh"
echo ""
echo "IMPORTANT: Don't run 'make' directly on your Mac!"
echo "Always build inside the Docker container."
echo ""