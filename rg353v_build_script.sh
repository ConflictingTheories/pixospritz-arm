#!/bin/bash
# RG353V Custom Game Engine Distro - Build Script
# This script sets up and builds a minimal Linux distro for the Anbernic RG353V
# that boots directly into your SDL2 + OpenGL game engine

set -e

PROJECT_DIR="$(pwd)/rg353v-custom"
BUILDROOT_VERSION="2024.02.1"

echo "=========================================="
echo "RG353V Custom Distro Builder"
echo "=========================================="

# Create project structure
mkdir -p "$PROJECT_DIR"/{buildroot,overlay,boot,game-engine}
cd "$PROJECT_DIR"

# Download Buildroot if not present
if [ ! -d "buildroot" ]; then
    echo "Downloading Buildroot ${BUILDROOT_VERSION}..."
    wget "https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.gz"
    tar xzf "buildroot-${BUILDROOT_VERSION}.tar.gz"
    mv "buildroot-${BUILDROOT_VERSION}" buildroot
    rm "buildroot-${BUILDROOT_VERSION}.tar.gz"
fi

cd "$PROJECT_DIR"

# Create external.desc first (needed for BR2_EXTERNAL)
cat > external.desc << 'EOF'
name: RG353V
desc: Custom Game Engine Distro for RG353V
EOF

# Create external.mk
touch external.mk

# Create Config.in
cat > Config.in << 'EOF'
source "$BR2_EXTERNAL_RG353V_PATH/package/Config.in"
EOF

mkdir -p package
touch package/Config.in

# Now create the defconfig in the external tree
mkdir -p configs
cat > configs/rg353v_defconfig << 'EOF'
# Architecture
BR2_aarch64=y
BR2_cortex_a55=y
BR2_ARM_FPU_NEON_FP_ARMV8=y

# Toolchain
BR2_TOOLCHAIN_BUILDROOT_GLIBC=y
BR2_TOOLCHAIN_BUILDROOT_CXX=y
BR2_GCC_VERSION_12_X=y
BR2_TOOLCHAIN_BUILDROOT_FORTRAN=y

# Kernel
BR2_LINUX_KERNEL=y
BR2_LINUX_KERNEL_CUSTOM_VERSION=y
BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="6.6.20"
BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y
BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE="$(BR2_EXTERNAL_RG353V_PATH)/board/rg353v/linux.config"
BR2_LINUX_KERNEL_DTS_SUPPORT=y
BR2_LINUX_KERNEL_INTREE_DTS_NAME="rockchip/rk3566-anbernic-rg353v"
BR2_LINUX_KERNEL_NEEDS_HOST_OPENSSL=y

# Bootloader
BR2_TARGET_UBOOT=y
BR2_TARGET_UBOOT_BUILD_SYSTEM_KCONFIG=y
BR2_TARGET_UBOOT_CUSTOM_VERSION=y
BR2_TARGET_UBOOT_CUSTOM_VERSION_VALUE="2024.01"
BR2_TARGET_UBOOT_BOARD_DEFCONFIG="anbernic-rg353v-rk3566"
BR2_TARGET_UBOOT_NEEDS_DTC=y
BR2_TARGET_UBOOT_NEEDS_PYTHON3=y
BR2_TARGET_UBOOT_NEEDS_PYLIBFDT=y
BR2_TARGET_UBOOT_NEEDS_OPENSSL=y
BR2_TARGET_UBOOT_SPL=y
BR2_TARGET_UBOOT_SPL_NAME="u-boot-rockchip.bin"

# Filesystem
BR2_TARGET_ROOTFS_EXT2=y
BR2_TARGET_ROOTFS_EXT2_4=y
BR2_TARGET_ROOTFS_EXT2_SIZE="512M"
BR2_ROOTFS_OVERLAY="$(BR2_EXTERNAL_RG353V_PATH)/board/rg353v/rootfs-overlay"
BR2_ROOTFS_POST_BUILD_SCRIPT="$(BR2_EXTERNAL_RG353V_PATH)/board/rg353v/post-build.sh"
BR2_ROOTFS_POST_IMAGE_SCRIPT="$(BR2_EXTERNAL_RG353V_PATH)/board/rg353v/post-image.sh"

# System
BR2_TARGET_GENERIC_HOSTNAME="rg353v"
BR2_TARGET_GENERIC_ISSUE="Welcome to RG353V Custom Game Engine"
BR2_SYSTEM_DHCP="eth0"
BR2_ROOTFS_DEVICE_CREATION_DYNAMIC_MDEV=y
BR2_TARGET_GENERIC_ROOT_PASSWD="root"
BR2_SYSTEM_BIN_SH_BASH=y

# Graphics - Mesa with Panfrost
BR2_PACKAGE_MESA3D=y
BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_PANFROST=y
BR2_PACKAGE_MESA3D_OPENGL_ES=y
BR2_PACKAGE_MESA3D_GBM=y
BR2_PACKAGE_HAS_LIBGL=y
BR2_PACKAGE_HAS_LIBEGL=y
BR2_PACKAGE_HAS_LIBGLES=y

# DRM/KMS
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

# Useful utilities
BR2_PACKAGE_NANO=y
BR2_PACKAGE_BASH=y
BR2_PACKAGE_HTOP=y
BR2_PACKAGE_LESS=y

# Compression
BR2_PACKAGE_ZLIB=y
BR2_PACKAGE_LIBPNG=y
BR2_PACKAGE_JPEG=y

# OpenSSL for networking
BR2_PACKAGE_OPENSSL=y
BR2_PACKAGE_LIBOPENSSL=y

# Target packages for development
BR2_PACKAGE_GDB=y
BR2_PACKAGE_STRACE=y
EOF

echo "Buildroot defconfig created in external tree."

# Create board directory structure
mkdir -p board/rg353v/{rootfs-overlay/{etc,opt,sbin},patches}

# Create init script that launches game engine
cat > board/rg353v/rootfs-overlay/sbin/game_init << 'EOF'
#!/bin/bash

# Mount essential filesystems
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs dev /dev
mkdir -p /dev/pts /dev/shm
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs /dev/shm

# Create necessary directories
mkdir -p /tmp /run /var/log

# Set hostname
hostname rg353v

# Configure GPU permissions
chmod 666 /dev/dri/card0 /dev/dri/renderD128 2>/dev/null || true

# Unblank framebuffer
echo 0 > /sys/class/graphics/fb0/blank 2>/dev/null || true

# Set CPU governor to performance
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor 2>/dev/null || true
echo performance > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor 2>/dev/null || true
echo performance > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor 2>/dev/null || true

# Initialize audio
alsactl init 2>/dev/null || true
amixer sset 'Headphone' 80% unmute 2>/dev/null || true
amixer sset 'Playback' 80% unmute 2>/dev/null || true

# Set environment variables for SDL2
export SDL_VIDEODRIVER=kmsdrm
export SDL_AUDIODRIVER=alsa
export MESA_GL_VERSION_OVERRIDE=3.2
export MESA_GLSL_VERSION_OVERRIDE=320

# Start networking in background
ifconfig lo up
dhcpcd eth0 &

# Log boot time
echo "System booted at $(date)" > /var/log/boot.log

# Launch game engine
cd /opt/game
if [ -f ./game_engine ]; then
    echo "Launching game engine..." >> /var/log/boot.log
    ./game_engine 2>&1 | tee /var/log/game.log
else
    echo "Game engine not found at /opt/game/game_engine" >> /var/log/boot.log
    echo "Game engine not found!"
    echo "Please copy your compiled engine to /opt/game/game_engine"
    echo "Press any key to get a shell..."
    read
    /bin/bash
fi

# If game engine exits, provide shell
echo "Game engine exited. Starting shell..."
/bin/bash
EOF

chmod +x board/rg353v/rootfs-overlay/sbin/game_init

# Create inittab to use custom init
cat > board/rg353v/rootfs-overlay/etc/inittab << 'EOF'
::sysinit:/sbin/game_init
::restart:/sbin/game_init
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
EOF

# Create fstab
cat > board/rg353v/rootfs-overlay/etc/fstab << 'EOF'
/dev/root    /              ext4    defaults,noatime           0 1
proc         /proc          proc    defaults                   0 0
devpts       /dev/pts       devpts  defaults,gid=5,mode=620    0 0
tmpfs        /dev/shm       tmpfs   mode=0777                  0 0
tmpfs        /tmp           tmpfs   mode=1777                  0 0
tmpfs        /run           tmpfs   mode=0755,nosuid,nodev     0 0
sysfs        /sys           sysfs   defaults                   0 0
EOF

# Create network configuration
mkdir -p board/rg353v/rootfs-overlay/etc/wpa_supplicant
cat > board/rg353v/rootfs-overlay/etc/wpa_supplicant/wpa_supplicant.conf << 'EOF'
ctrl_interface=/var/run/wpa_supplicant
update_config=1

# Add your WiFi networks here:
# network={
#     ssid="YourNetworkName"
#     psk="YourPassword"
# }
EOF

# Create ALSA configuration
cat > board/rg353v/rootfs-overlay/etc/asound.conf << 'EOF'
pcm.!default {
    type hw
    card 0
    device 0
}

ctl.!default {
    type hw
    card 0
}
EOF

# Create post-build script
cat > board/rg353v/post-build.sh << 'EOF'
#!/bin/bash
set -e

TARGET_DIR=$1

# Make init script executable
chmod +x ${TARGET_DIR}/sbin/game_init

# Create game directory
mkdir -p ${TARGET_DIR}/opt/game

echo "Post-build completed"
EOF

chmod +x board/rg353v/post-build.sh

# Create post-image script
cat > board/rg353v/post-image.sh << 'EOF'
#!/bin/bash
set -e

BOARD_DIR="$(dirname $0)"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

rm -rf "${GENIMAGE_TMP}"

genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

echo "SD card image created: ${BINARIES_DIR}/sdcard.img"
echo "Flash with: sudo dd if=${BINARIES_DIR}/sdcard.img of=/dev/sdX bs=4M status=progress"
EOF

chmod +x board/rg353v/post-image.sh

# Create genimage configuration
cat > board/rg353v/genimage.cfg << 'EOF'
image boot.vfat {
    vfat {
        files = {
            "Image",
            "rk3566-anbernic-rg353v.dtb"
        }
    }
    size = 64M
}

image sdcard.img {
    hdimage {
    }

    partition u-boot {
        in-partition-table = "no"
        image = "u-boot-rockchip.bin"
        offset = 32K
        size = 8M
    }

    partition boot {
        partition-type = 0xC
        bootable = "true"
        image = "boot.vfat"
    }

    partition rootfs {
        partition-type = 0x83
        image = "rootfs.ext4"
        size = 512M
    }
}
EOF

# Now move back and create remaining external tree files
cd "$PROJECT_DIR"

# Create external.desc
cat > external.desc << 'EOF'
name: RG353V
desc: Custom Game Engine Distro for RG353V
EOF

# Create external.mk
touch external.mk

# Create Config.in
cat > Config.in << 'EOF'
source "$BR2_EXTERNAL_RG353V_PATH/package/Config.in"
EOF

mkdir -p package
touch package/Config.in

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Build the system:"
echo "   cd $PROJECT_DIR/buildroot"
echo "   make BR2_EXTERNAL=$PROJECT_DIR rg353v_defconfig"
echo "   make -j\$(nproc)"
echo ""
echo "2. Cross-compile your game engine:"
echo "   Use the toolchain in buildroot/output/host/bin/"
echo "   Compiler: aarch64-buildroot-linux-gnu-g++"
echo ""
echo "3. Copy your game engine:"
echo "   cp your_game_engine $PROJECT_DIR/board/rg353v/rootfs-overlay/opt/game/game_engine"
echo "   chmod +x $PROJECT_DIR/board/rg353v/rootfs-overlay/opt/game/game_engine"
echo ""
echo "4. Rebuild and flash:"
echo "   make -j\$(nproc)"
echo "   sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M status=progress"
echo ""
echo "=========================================="
echo ""
echo "Your game engine should:"
echo "- Use SDL2 with KMSDRM video driver"
echo "- Use OpenGL ES 3.2"
echo "- Handle 640x480 resolution"
echo "- Be compiled for aarch64"
echo ""
echo "Example SDL2 setup in your code:"
echo "  SDL_SetHint(SDL_HINT_VIDEO_DRIVER, \"kmsdrm\");"
echo "  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);"
echo "  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);"
echo "  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);"
echo ""