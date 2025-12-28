#!/bin/bash

set -e

# Ensure we're in the right directory
cd /build

# Create output directory (in case it wasn't created by Docker)
mkdir -p /build/compiled/pixospritz

# Ensure toolchain is in PATH
echo "Configuring toolchain..."
export XTOOL=$(realpath aarch64-buildroot-linux-gnu_sdk-buildroot)
export XHOST=aarch64-buildroot-linux-gnu
export PATH=$PATH:$XTOOL/bin
export SYSROOT=$XTOOL/$XHOST/sysroot
export PKG_CONFIG_PATH=$SYSROOT/usr/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=$SYSROOT

# Build Pixospritz
echo "Building Pixospritz..."
cd /workspace
mkdir -p build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=/workspace/toolchain-rg353v.cmake -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE ..
make -j$(nproc)
if [ $? -ne 0 ]; then
  echo "m8c build failed"
  exit 1
fi

# Build kernel modules
echo "Building kernel modules..."
cd /build/linux-$LINUX_KERNEL_VERSION

echo "Configuring kernel..."
cp /build/linux-sunxi64-legacy.config .config
sed -i 's/# CONFIG_SND_USB_AUDIO is not set/CONFIG_SND_USB_AUDIO=m/g' .config
sed -i 's/# CONFIG_USB_ACM is not set/CONFIG_USB_ACM=m/g' .config

sed -i 's/^YYLTYPE yylloc;$/extern YYLTYPE yylloc;/g' scripts/dtc/dtc-lexer.lex.c_shipped
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules_prepare

echo "Building kernel modules..."
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- M=drivers/usb/class
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- M=sound/core
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- M=sound/usb

# Collect files
echo "Collecting files..."

# Copy kernel modules
for module in cdc-acm.ko snd-hwdep.ko snd-usbmidi-lib.ko snd-usb-audio.ko; do
  find /build/linux-$LINUX_KERNEL_VERSION -name "$module" -exec cp -v {} /build/compiled/pixospritz \; || echo "Warning: $module not found"
done

# Copy Pixospritz executable
if [ -f "/workspace/build/pixospritz" ]; then
  cp -v /workspace/build/pixospritz /build/compiled/pixospritz
  echo "Copied Pixospritz executable"
else
  echo "Error: Pixospritz executable not found"
  exit 1
fi

# Create pixospritz.sh script
sed "s/\$LINUX_KERNEL_VERSION/$LINUX_KERNEL_VERSION/" <<'EOF' >/build/compiled/pixospritz.sh
#!/bin/sh

export HOME=$(dirname $(realpath $0))/pixospritz
cd $HOME

# Ensure pixospritz is executable
chmod +x ./pixospritz

cp *.ko /lib/modules/$LINUX_KERNEL_VERSION
depmod
modprobe -a cdc-acm snd-hwdep snd-usbmidi-lib snd-usb-audio

pw-loopback -C alsa_input.usb-DirtyWave_M8_14900360-02.analog-stereo -P alsa_output._sys_devices_platform_soc_soc_03000000_codec_mach_sound_card0.stereo-fallback &

SDL_GAMECONTROLLERCONFIG="19000000010000000100000000010000,Deeplay-keys,a:b3,b:b4,x:b6,y:b5,leftshoulder:b7,rightshoulder:b8,lefttrigger:b13,righttrigger:b14,guide:b11,start:b10,back:b9,dpup:h0.1,dpleft:h0.8,dpright:h0.2,dpdown:h0.4,volumedown:b1,volumeup:b2,leftx:a0,lefty:a1,leftstick:b12,rightx:a2,righty:a3,rightstick:b15,platform:Linux," ./pixospritz

kill $(jobs -p)
EOF

chmod +x /build/compiled/pixospritz.sh

#
# Final checks and summary
#
check_build_output() {
  local error_count=0
  local warning_count=0

    # Check Pixospritz executable
    if [ -f "/build/compiled/pixospritz/pixospritz" ]; then
        file_type=$(file /build/compiled/pixospritz/pixospritz)
        if [[ $file_type == *"ELF 64-bit LSB executable, ARM aarch64"* ]]; then
            echo "✓ Pixospritz executable present and valid"
        else
            echo "✗ Pixospritz executable present but may be invalid: $file_type"
            ((error_count++))
        fi
    else
        echo "✗ Pixospritz executable missing"
        ((error_count++))
    fi

  # Check kernel modules
  modules=("cdc-acm.ko" "snd-hwdep.ko" "snd-usbmidi-lib.ko" "snd-usb-audio.ko")
  for module in "${modules[@]}"; do
    if [ -f "/build/compiled/m8c/$module" ]; then
      echo "✓ Kernel module $module present"
    else
      echo "✗ Kernel module $module missing"
      ((warning_count++))
    fi
  done

    # Check pixospritz.sh script
    if [ -f "/build/compiled/pixospritz.sh" ]; then
        if grep -q "SDL_GAMECONTROLLERCONFIG" "/build/compiled/pixospritz.sh"; then
            echo "✓ pixospritz.sh script present and contains expected content"
        else
            echo "✗ pixospritz.sh script present but may be invalid"
            ((warning_count++))
        fi
    else
        echo "✗ pixospritz.sh script missing"
        ((error_count++))
    fi

  # Print summary
  echo "-------------------"
  echo "Build Check Summary"
  echo "-------------------"
  echo "Errors: $error_count"
  echo "Warnings: $warning_count"

  if [ $error_count -eq 0 ] && [ $warning_count -eq 0 ]; then
    echo "Build completed successfully with no issues."
  elif [ $error_count -eq 0 ]; then
    echo "Build completed with warnings. Please review the output."
  else
    echo "Build completed with errors. Please review the output and correct the issues."
    exit 1
  fi
}

# Run the checks
check_build_output

echo "Build and check process complete. All compiled files are in /build/compiled/pixospritz"
