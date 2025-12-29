#!/bin/bash
# Fix the defconfig to use a working toolchain configuration

set -e

echo "=========================================="
echo "Fixing Toolchain Configuration"
echo "=========================================="
echo ""
echo "Problem: External toolchain path is broken"
echo "Solution: Use Buildroot's internal toolchain (more reliable)"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create a corrected defconfig
cat > "$SCRIPT_DIR/rg353v-custom/configs/rg353v_defconfig" << 'EOF'
# Architecture
BR2_aarch64=y
BR2_cortex_a55=y

# System
BR2_SYSTEM_DHCP="eth0"

# Use INTERNAL toolchain (more reliable than external)
BR2_TOOLCHAIN_BUILDROOT=y
BR2_TOOLCHAIN_BUILDROOT_GLIBC=y
BR2_TOOLCHAIN_BUILDROOT_CXX=y

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

# Basic packages
BR2_PACKAGE_BUSYBOX=y
BR2_PACKAGE_BUSYBOX_SHOW_OTHERS=y
EOF

echo "✓ Created corrected defconfig with internal toolchain"

# Make sure the linux.config has minimal working content
cat > "$SCRIPT_DIR/rg353v-custom/board/rg353v/linux.config" << 'LINUX_EOF'
CONFIG_ARM64=y
CONFIG_ARCH_ROCKCHIP=y
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y
CONFIG_SERIAL_OF_PLATFORM=y
CONFIG_EXT4_FS=y
CONFIG_TMPFS=y
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
CONFIG_PROC_FS=y
CONFIG_SYSFS=y
LINUX_EOF

echo "✓ Updated linux.config"

echo ""
echo "=========================================="
echo "✓ Defconfig Fixed!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  - Switched from external to INTERNAL toolchain"
echo "  - Internal toolchain is built by Buildroot (more reliable)"
echo "  - Will take longer but should work"
echo ""
echo "Now clean and rebuild:"
echo "  1. Clean old build:"
echo "     rm -rf rg353v-custom/buildroot/output"
echo ""
echo "  2. Rebuild:"
echo "     docker-compose run --rm buildroot /home/builder/work/docker-build.sh"
echo ""