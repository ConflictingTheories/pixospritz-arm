#!/bin/bash
# Quick fix script - Run this inside the Docker container
# This switches to using a prebuilt external toolchain

set -e

echo "=========================================="
echo "Quick Fix: Switching to External Toolchain"
echo "=========================================="
echo ""
echo "This will:"
echo "1. Stop trying to build binutils/gcc from scratch"
echo "2. Use Bootlin's prebuilt ARM64 toolchain"
echo "3. Make the build MUCH faster and more reliable"
echo "4. Patch host-tar to work on macOS"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BR_DIR="$SCRIPT_DIR/rg353v-custom/buildroot/buildroot-2024.02.1"
EXTERNAL_DIR="$SCRIPT_DIR/rg353v-custom"

cd "$BR_DIR"

# Clean the failed build
echo "Cleaning failed build artifacts..."
make clean

# Remove failed tar build if it exists
rm -rf output/build/host-tar-1.34

# Backup old defconfig
if [ -f "$EXTERNAL_DIR/configs/rg353v_defconfig" ]; then
    cp "$EXTERNAL_DIR/configs/rg353v_defconfig" "$EXTERNAL_DIR/configs/rg353v_defconfig.backup"
    echo "Backed up old config to rg353v_defconfig.backup"
fi

# Create new defconfig with external toolchain
cat > "$EXTERNAL_DIR/configs/rg353v_defconfig" << 'DEFCONFIG_EOF'
# Architecture
BR2_aarch64=y
BR2_cortex_a55=y
BR2_ARM_FPU_NEON_FP_ARMV8=y

# Use external ARM toolchain (MUCH FASTER!)
BR2_TOOLCHAIN_EXTERNAL=y
BR2_TOOLCHAIN_EXTERNAL_BOOTLIN=y
BR2_TOOLCHAIN_EXTERNAL_BOOTLIN_AARCH64_GLIBC_STABLE=y

# System
BR2_TARGET_GENERIC_HOSTNAME="rg353v"
BR2_TARGET_GENERIC_ISSUE="Welcome to RG353V PixoSpritz Game Console"
BR2_SYSTEM_DHCP="eth0"
BR2_ROOTFS_DEVICE_CREATION_DYNAMIC_MDEV=y
BR2_TARGET_GENERIC_ROOT_PASSWD="root"
BR2_SYSTEM_BIN_SH_BASH=y

# Kernel
BR2_LINUX_KERNEL=y
BR2_LINUX_KERNEL_CUSTOM_VERSION=y
BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="6.1.50"
BR2_LINUX_KERNEL_DEFCONFIG="defconfig"
BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES="$(BR2_EXTERNAL_RG353V_PATH)/board/rg353v/linux-extras.config"
BR2_LINUX_KERNEL_DTS_SUPPORT=y
BR2_LINUX_KERNEL_INTREE_DTS_NAME="rockchip/rk3566-anbernic-rg353v"
BR2_LINUX_KERNEL_NEEDS_HOST_OPENSSL=y

# Bootloader
BR2_TARGET_UBOOT=y
BR2_TARGET_UBOOT_BUILD_SYSTEM_KCONFIG=y
BR2_TARGET_UBOOT_CUSTOM_VERSION=y
BR2_TARGET_UBOOT_CUSTOM_VERSION_VALUE="2023.07"
BR2_TARGET_UBOOT_BOARD_DEFCONFIG="evb-rk3566"
BR2_TARGET_UBOOT_NEEDS_DTC=y
BR2_TARGET_UBOOT_NEEDS_PYTHON3=y
BR2_TARGET_UBOOT_NEEDS_PYLIBFDT=y
BR2_TARGET_UBOOT_NEEDS_OPENSSL=y
BR2_TARGET_UBOOT_FORMAT_CUSTOM=y
BR2_TARGET_UBOOT_FORMAT_CUSTOM_NAME="u-boot.itb"

# Filesystem
BR2_TARGET_ROOTFS_EXT2=y
BR2_TARGET_ROOTFS_EXT2_4=y
BR2_TARGET_ROOTFS_EXT2_SIZE="512M"
BR2_ROOTFS_OVERLAY="$(BR2_EXTERNAL_RG353V_PATH)/board/rg353v/rootfs-overlay"
BR2_ROOTFS_POST_BUILD_SCRIPT="$(BR2_EXTERNAL_RG353V_PATH)/board/rg353v/post-build.sh"
BR2_ROOTFS_POST_IMAGE_SCRIPT="$(BR2_EXTERNAL_RG353V_PATH)/board/rg353v/post-image.sh"

# Graphics
BR2_PACKAGE_MESA3D=y
BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_PANFROST=y
BR2_PACKAGE_MESA3D_OPENGL_ES=y
BR2_PACKAGE_MESA3D_GBM=y
BR2_PACKAGE_HAS_LIBGL=y
BR2_PACKAGE_HAS_LIBEGL=y
BR2_PACKAGE_HAS_LIBGLES=y

BR2_PACKAGE_LIBDRM=y
BR2_PACKAGE_LIBDRM_INSTALL_TESTS=y

# SDL2
BR2_PACKAGE_SDL2=y
BR2_PACKAGE_SDL2_KMSDRM=y
BR2_PACKAGE_SDL2_OPENGL=y
BR2_PACKAGE_SDL2_OPENGLES=y

# Input
BR2_PACKAGE_LIBEVDEV=y
BR2_PACKAGE_LIBINPUT=y

# Audio
BR2_PACKAGE_ALSA_LIB=y
BR2_PACKAGE_ALSA_LIB_MIXER=y
BR2_PACKAGE_ALSA_LIB_PCM=y
BR2_PACKAGE_ALSA_UTILS=y
BR2_PACKAGE_ALSA_UTILS_ALSAMIXER=y
BR2_PACKAGE_ALSA_UTILS_AMIXER=y
BR2_PACKAGE_ALSA_UTILS_APLAY=y

# Networking
BR2_PACKAGE_DHCPCD=y
BR2_PACKAGE_WIRELESS_TOOLS=y
BR2_PACKAGE_WPA_SUPPLICANT=y
BR2_PACKAGE_WPA_SUPPLICANT_CLI=y
BR2_PACKAGE_WPA_SUPPLICANT_NL80211=y

# Utilities
BR2_PACKAGE_NANO=y
BR2_PACKAGE_BASH=y
BR2_PACKAGE_HTOP=y
BR2_PACKAGE_LESS=y

# Compression
BR2_PACKAGE_ZLIB=y
BR2_PACKAGE_LIBPNG=y
BR2_PACKAGE_JPEG=y

# OpenSSL
BR2_PACKAGE_OPENSSL=y
BR2_PACKAGE_LIBOPENSSL=y

# Development
BR2_PACKAGE_GDB=y
BR2_PACKAGE_STRACE=y

# Host tools
BR2_PACKAGE_HOST_GENIMAGE=y
BR2_PACKAGE_HOST_DOSFSTOOLS=y
BR2_PACKAGE_HOST_MTOOLS=y
DEFCONFIG_EOF

echo ""
echo "Updated defconfig created!"
echo ""

# Fix tar issue on macOS - create symlink to system tar FIRST
echo "Setting up system tar for Buildroot..."
mkdir -p "$BR_DIR/output/host/bin"

if command -v gtar >/dev/null 2>&1; then
    echo "Using GNU tar (gtar) from Homebrew"
    ln -sf $(which gtar) "$BR_DIR/output/host/bin/tar"
elif command -v tar >/dev/null 2>&1; then
    echo "Using system tar"
    ln -sf $(which tar) "$BR_DIR/output/host/bin/tar"
else
    echo "ERROR: No tar found! Installing via Homebrew..."
    brew install gnu-tar
    ln -sf $(which gtar) "$BR_DIR/output/host/bin/tar"
fi

# Override tar package to skip building it entirely
mkdir -p "$BR_DIR/package/tar"
cat > "$BR_DIR/package/tar/tar.mk" << 'TAR_MK_EOF'
################################################################################
#
# tar (using system tar - skip building)
#
################################################################################

# Make this a virtual package that does nothing
TAR_VERSION = 1.34

# Don't download anything
HOST_TAR_SOURCE =

# Mark all stamps as done immediately
define HOST_TAR_EXTRACT_CMDS
	@echo "Using system tar"
endef

define HOST_TAR_CONFIGURE_CMDS
	@echo "Skipping tar configure (using system tar)"
endef

define HOST_TAR_BUILD_CMDS
	@echo "Skipping tar build (using system tar)"
endef

define HOST_TAR_INSTALL_CMDS
	@echo "tar already available in output/host/bin"
endef

define HOST_TAR_PATCH_CMDS
	@echo "Skipping tar patching (using system tar)"
endef

$(eval $(host-generic-package))
TAR_MK_EOF

echo "✓ tar setup complete (using system tar)"
echo ""
echo "Now reconfiguring Buildroot..."

# Set up proper PATH for macOS with Homebrew
export PATH="/opt/homebrew/bin:/opt/homebrew/opt/gpatch/libexec/gnubin:/opt/homebrew/opt/findutils/libexec/gnubin:/opt/homebrew/opt/gnu-sed/libexec/gnubin:/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/opt/util-linux/bin:/opt/homebrew/opt/util-linux/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Make sure we have GNU sed
if ! command -v gsed >/dev/null 2>&1; then
    echo "Installing gnu-sed via homebrew..."
    brew install gnu-sed
fi

# Try to find and use brew gcc (14 or 13 are most stable on macOS)
if command -v gcc-14 >/dev/null 2>&1; then
    export HOSTCC="gcc-14"
    export HOSTCXX="g++-14"
    echo "Using gcc-14 from Homebrew"
elif command -v gcc-13 >/dev/null 2>&1; then
    export HOSTCC="gcc-13"
    export HOSTCXX="g++-13"
    echo "Using gcc-13 from Homebrew"
elif command -v gcc-15 >/dev/null 2>&1; then
    export HOSTCC="gcc-15"
    export HOSTCXX="g++-15"
    echo "Using gcc-15 from Homebrew (may have compatibility issues)"
else
    echo "Warning: No brew gcc found, using system gcc (may be clang)"
    export HOSTCC="gcc"
    export HOSTCXX="g++"
fi

# Apply defconfig
make BR2_EXTERNAL="$EXTERNAL_DIR" rg353v_defconfig

echo ""
echo "=========================================="
echo "Configuration Complete!"
echo "=========================================="
echo ""
echo "The external toolchain will be downloaded (about 100MB)"
echo "This is MUCH faster than building binutils/gcc from scratch"
echo ""
echo "Ready to build. Running make..."

# Build with proper flags
make -j$(sysctl -n hw.ncpu) 2>&1 | tee build.log

echo ""
echo "=========================================="
echo "Build Process Complete!"
echo "=========================================="
echo "Check build.log for any issues."