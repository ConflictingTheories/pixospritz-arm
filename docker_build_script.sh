#!/bin/bash
# ACTUAL FIX - Creates the missing BR2_EXTERNAL structure and defconfig

set -e

echo "=========================================="
echo "RG353V Build Structure Diagnostic & Fix"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check what actually exists
echo "Checking your directory structure..."
echo ""

if [ -d "$SCRIPT_DIR/rg353v-custom" ]; then
    echo "✓ rg353v-custom directory exists"
    
    if [ -d "$SCRIPT_DIR/rg353v-custom/buildroot" ]; then
        echo "✓ buildroot directory exists"
        
        if [ -d "$SCRIPT_DIR/rg353v-custom/buildroot/buildroot-2024.02.1" ]; then
            echo "✓ buildroot-2024.02.1 exists"
        else
            echo "✗ buildroot-2024.02.1 NOT FOUND"
            echo "  You need to download and extract Buildroot 2024.02.1"
            exit 1
        fi
    else
        echo "✗ buildroot directory NOT FOUND"
        exit 1
    fi
else
    echo "Creating rg353v-custom directory structure..."
    mkdir -p "$SCRIPT_DIR/rg353v-custom"
fi

echo ""
echo "Checking BR2_EXTERNAL structure..."

# Create the proper BR2_EXTERNAL tree structure
BR2_EXT="$SCRIPT_DIR/rg353v-custom"

# Check/create configs directory
if [ ! -d "$BR2_EXT/configs" ]; then
    echo "Creating configs/ directory..."
    mkdir -p "$BR2_EXT/configs"
fi

# Check/create board directory
if [ ! -d "$BR2_EXT/board/rg353v" ]; then
    echo "Creating board/rg353v/ directory..."
    mkdir -p "$BR2_EXT/board/rg353v"
fi

# Create external.desc if missing
if [ ! -f "$BR2_EXT/external.desc" ]; then
    echo "Creating external.desc..."
    cat > "$BR2_EXT/external.desc" << 'EOF'
name: RG353V
desc: Custom firmware for Anbernic RG353V handheld
EOF
fi

# Create external.mk if missing
if [ ! -f "$BR2_EXT/external.mk" ]; then
    echo "Creating external.mk..."
    cat > "$BR2_EXT/external.mk" << 'EOF'
include $(sort $(wildcard $(BR2_EXTERNAL_RG353V_PATH)/package/*/*.mk))
EOF
fi

# Create Config.in if missing
if [ ! -f "$BR2_EXT/Config.in" ]; then
    echo "Creating Config.in..."
    cat > "$BR2_EXT/Config.in" << 'EOF'
source "$BR2_EXTERNAL_RG353V_PATH/package/Config.in"
EOF
fi

# Create the defconfig file
echo "Creating rg353v_defconfig..."
cat > "$BR2_EXT/configs/rg353v_defconfig" << 'EOF'
# Architecture
BR2_aarch64=y
BR2_cortex_a55=y

# System
BR2_SYSTEM_DHCP="eth0"

# Toolchain
BR2_TOOLCHAIN_EXTERNAL=y
BR2_TOOLCHAIN_EXTERNAL_BOOTLIN=y
BR2_TOOLCHAIN_EXTERNAL_BOOTLIN_AARCH64_GLIBC_STABLE=y

# Kernel
BR2_LINUX_KERNEL=y
BR2_LINUX_KERNEL_CUSTOM_VERSION=y
BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="6.1.50"
BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y
BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE="$(BR2_EXTERNAL_RG353V_PATH)/board/rg353v/linux.config"
BR2_LINUX_KERNEL_DTS_SUPPORT=y
BR2_LINUX_KERNEL_INTREE_DTS_NAME="rockchip/rk3566-anbernic-rg353v"
BR2_LINUX_KERNEL_NEEDS_HOST_OPENSSL=y

# U-Boot
BR2_TARGET_UBOOT=y
BR2_TARGET_UBOOT_BUILD_SYSTEM_KCONFIG=y
BR2_TARGET_UBOOT_CUSTOM_VERSION=y
BR2_TARGET_UBOOT_CUSTOM_VERSION_VALUE="2023.07"
BR2_TARGET_UBOOT_BOARD_DEFCONFIG="anbernic-rg353v-rk3566"
BR2_TARGET_UBOOT_NEEDS_DTC=y
BR2_TARGET_UBOOT_NEEDS_PYTHON3=y
BR2_TARGET_UBOOT_NEEDS_PYLIBFDT=y
BR2_TARGET_UBOOT_NEEDS_OPENSSL=y
BR2_TARGET_UBOOT_FORMAT_BIN=y
BR2_TARGET_UBOOT_SPL=y
BR2_TARGET_UBOOT_SPL_NAME="u-boot-spl.bin"

# Rockchip tools
BR2_PACKAGE_HOST_UBOOT_TOOLS=y

# Filesystem
BR2_TARGET_ROOTFS_EXT2=y
BR2_TARGET_ROOTFS_EXT2_4=y
BR2_TARGET_ROOTFS_EXT2_SIZE="512M"

# Target packages
BR2_PACKAGE_BUSYBOX_SHOW_OTHERS=y
EOF

echo "✓ defconfig created"

# Create a minimal kernel config
if [ ! -f "$BR2_EXT/board/rg353v/linux.config" ]; then
    echo "Creating minimal linux.config..."
    cat > "$BR2_EXT/board/rg353v/linux.config" << 'EOF'
CONFIG_ARM64=y
CONFIG_ARCH_ROCKCHIP=y
CONFIG_ROCKCHIP_RK3566=y
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y
CONFIG_SERIAL_OF_PLATFORM=y
CONFIG_EXT4_FS=y
CONFIG_TMPFS=y
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
EOF
    echo "✓ linux.config created"
fi

echo ""
echo "=========================================="
echo "Structure Created!"
echo "=========================================="
echo ""
echo "Directory structure:"
echo "  rg353v-custom/"
echo "  ├── external.desc"
echo "  ├── external.mk"
echo "  ├── Config.in"
echo "  ├── configs/"
echo "  │   └── rg353v_defconfig  ← YOUR DEFCONFIG"
echo "  └── board/"
echo "      └── rg353v/"
echo "          └── linux.config"
echo ""

# Now update the docker-build.sh script with correct paths
cat > "$SCRIPT_DIR/docker-build.sh" << 'BUILD_SCRIPT_EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "Building RG353V Firmware"
echo "=========================================="

cd /home/builder/work/rg353v-custom/buildroot/buildroot-2024.02.1

if [ "$1" = "clean" ]; then
    echo "Performing clean build..."
    make clean
fi

# Set BR2_EXTERNAL to the parent directory (rg353v-custom)
echo "Setting BR2_EXTERNAL=/home/builder/work/rg353v-custom"
export BR2_EXTERNAL=/home/builder/work/rg353v-custom

echo "Applying rg353v_defconfig..."
make rg353v_defconfig

echo ""
echo "Build configuration:"
echo "  Target: ARM64 (Cortex-A55)"
echo "  Toolchain: Bootlin external"
echo "  Kernel: 6.1.50"
echo "  U-Boot: 2023.07"
echo ""

NUM_CORES=$(nproc)
echo "Building with $NUM_CORES CPU cores..."
echo ""

make -j$NUM_CORES 2>&1 | tee /home/builder/work/build.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ Build Complete!"
    echo "=========================================="
    echo ""
    ls -lh output/images/
else
    echo ""
    echo "✗ Build Failed - check build.log"
    exit 1
fi
BUILD_SCRIPT_EOF

chmod +x "$SCRIPT_DIR/docker-build.sh"
echo "✓ Updated docker-build.sh with correct BR2_EXTERNAL path"

echo ""
echo "=========================================="
echo "NOW you can build:"
echo "=========================================="
echo ""
echo "  docker-compose run --rm buildroot /home/builder/work/docker-build.sh"
echo ""