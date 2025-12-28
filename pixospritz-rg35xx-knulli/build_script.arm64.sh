#!/bin/bash

set -e

cd /build

# Create output directory (in case it wasn't created by Docker)
mkdir -p /build/compiled/pixospritz

# Build Pixospritz game engine
echo "Building Pixospritz game engine..."
cd /workspace
mkdir -p build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=/workspace/toolchain-rg353v.cmake -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE ..
make -j$(nproc)
if [ $? -ne 0 ]; then
  echo "Pixospritz build failed"
  exit 1
fi

# Build kernel modules (if needed for Pixospritz)
echo "Building kernel modules..."
cd /build/linux-$LINUX_KERNEL_VERSION

echo "Configuring kernel..."
cp /build/linux-sunxi64-legacy.config .config
sed -i 's/# CONFIG_SND_USB_AUDIO is not set/CONFIG_SND_USB_AUDIO=m/g' .config
sed -i 's/# CONFIG_USB_ACM is not set/CONFIG_USB_ACM=m/g' .config

sed -i 's/^YYLTYPE yylloc;$/extern YYLTYPE yylloc;/g' scripts/dtc/dtc-lexer.lex.c_shipped
make ARCH=arm64 CROSS_COMPILE=aarch64-linux- olddefconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux- modules_prepare

echo "Building kernel modules..."
make ARCH=arm64 CROSS_COMPILE=aarch64-linux- M=drivers/usb/class
make ARCH=arm64 CROSS_COMPILE=aarch64-linux- M=sound/core
make ARCH=arm64 CROSS_COMPILE=aarch64-linux- M=sound/usb

# Collect files
echo "Collecting files..."

# Copy kernel modules
for module in cdc-acm.ko snd-hwdep.ko snd-usbmidi-lib.ko snd-usb-audio.ko; do
  find /build/linux-$LINUX_KERNEL_VERSION -name "$module" -exec cp -v {} /build/compiled/pixospritz \; || echo "Warning: $module not found"
done

# Copy Pixospritz executable
if [ -f "/workspace/src/build/pixospritz" ]; then
  cp -v /workspace/src/build/pixospritz /build/compiled/pixospritz
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

# Add any necessary setup for Pixospritz, e.g., SDL_GAMECONTROLLERCONFIG for RG353V

./pixospritz

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
        if [[ $file_type == *"ARM aarch64"* && $file_type == *"LSB"* && $file_type == *"executable"* ]]; then
            echo "✓ Pixospritz executable present and valid ($(basename "$file_type"))"
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
        if [ -f "/build/compiled/pixospritz/$module" ]; then
            echo "✓ Kernel module $module present"
        else
            echo "✗ Kernel module $module missing"
            ((warning_count++))
        fi
    done

    # Check pixospritz.sh script
    if [ -f "/build/compiled/pixospritz.sh" ]; then
        if grep -q "pixospritz" "/build/compiled/pixospritz.sh"; then
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
