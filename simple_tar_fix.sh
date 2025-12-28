#!/bin/bash
# Complete fix: Remove tar from build and use system tar

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BR_DIR="$SCRIPT_DIR/rg353v-custom/buildroot/buildroot-2024.02.1"

cd "$BR_DIR"

echo "==========================================="
echo "Complete cleanup and tar fix..."
echo "==========================================="

# Stop any running builds
pkill -f "make.*buildroot" || true
sleep 1

# Clean up ALL tar-related files
echo "Cleaning up tar artifacts..."
rm -rf output/build/host-tar-1.34
rm -rf output/build/.host-tar*
rm -rf dl/tar/
rm -rf package/tar/

# Remove any existing patches that were created
rm -f package/tar/0001-fix-argp-macos.patch
rm -f package/tar/patches/*

echo "✓ Cleaned up"

# Set up system tar in host/bin
echo "Setting up system tar..."
mkdir -p output/host/bin

if command -v gtar >/dev/null 2>&1; then
    echo "Using GNU tar (gtar)"
    ln -sf $(which gtar) output/host/bin/tar
elif command -v tar >/dev/null 2>&1; then
    echo "Using system tar"
    ln -sf $(which tar) output/host/bin/tar
else
    echo "ERROR: No tar found! Installing..."
    brew install gnu-tar
    ln -sf $(which gtar) output/host/bin/tar
fi

# Verify tar works
if ! output/host/bin/tar --version >/dev/null 2>&1; then
    echo "ERROR: tar is not working!"
    exit 1
fi

echo "✓ System tar linked successfully"

# Create package/tar directory with virtual package
echo "Creating virtual tar package..."
mkdir -p package/tar

# Empty Config.in
cat > package/tar/Config.in << 'EOF'
# tar is provided by host system
EOF

# tar.hash (needed by buildroot)
cat > package/tar/tar.hash << 'EOF'
# Not used - system tar
EOF

# tar.mk - virtual package that does nothing
cat > package/tar/tar.mk << 'EOF'
################################################################################
#
# tar - provided by host system
#
################################################################################

TAR_VERSION = system

$(eval $(host-virtual-package))
EOF

echo "✓ Virtual tar package created"

# Clean the buildroot configuration
echo "Reconfiguring buildroot..."
make clean

echo ""
echo "==========================================="
echo "✓ Fix complete!"
echo "==========================================="
echo ""
echo "Now run your build with:"
echo "  make -j$(sysctl -n hw.ncpu)"
echo ""