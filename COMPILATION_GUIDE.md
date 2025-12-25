# RG353V Game Engine Cross-Compilation Guide

## Prerequisites

After running the build script, you'll have a Buildroot toolchain in:
```
rg353v-custom/buildroot/output/host/bin/
```

## Project Structure

```
your-game-engine/
├── CMakeLists.txt
├── src/
│   └── main.cpp
├── build-rg353v.sh
└── toolchain-rg353v.cmake
```

## Step 1: Create CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.10)
project(GameEngine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find SDL2
find_package(SDL2 REQUIRED)
find_package(OpenGL REQUIRED)

# Create executable
add_executable(game_engine
    src/main.cpp
)

# Include directories
target_include_directories(game_engine PRIVATE
    ${SDL2_INCLUDE_DIRS}
    ${OPENGL_INCLUDE_DIR}
)

# Link libraries
target_link_libraries(game_engine
    ${SDL2_LIBRARIES}
    GLESv2
    EGL
    pthread
    dl
    m
)

# Strip binary for smaller size
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_custom_command(TARGET game_engine POST_BUILD
        COMMAND ${CMAKE_STRIP} game_engine
    )
endif()
```

## Step 2: Create Toolchain File (toolchain-rg353v.cmake)

```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Set the toolchain paths
# Adjust this path to match your buildroot location
set(TOOLCHAIN_PREFIX "$ENV{HOME}/rg353v-custom/buildroot/output/host")
set(CMAKE_SYSROOT "${TOOLCHAIN_PREFIX}/aarch64-buildroot-linux-gnu/sysroot")

# Specify the cross compilers
set(CMAKE_C_COMPILER "${TOOLCHAIN_PREFIX}/bin/aarch64-buildroot-linux-gnu-gcc")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_PREFIX}/bin/aarch64-buildroot-linux-gnu-g++")

# Set CMAKE_FIND_ROOT_PATH
set(CMAKE_FIND_ROOT_PATH "${CMAKE_SYSROOT}")

# Adjust the default behavior of the find commands
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# SDL2 and OpenGL paths
set(SDL2_INCLUDE_DIRS "${CMAKE_SYSROOT}/usr/include/SDL2")
set(SDL2_LIBRARIES "${CMAKE_SYSROOT}/usr/lib/libSDL2.so")
set(OPENGL_INCLUDE_DIR "${CMAKE_SYSROOT}/usr/include")
```

## Step 3: Create Build Script (build-rg353v.sh)

```bash
#!/bin/bash

# Exit on error
set -e

# Configuration
BUILDROOT_DIR="$HOME/rg353v-custom/buildroot"
TOOLCHAIN_FILE="$(pwd)/toolchain-rg353v.cmake"
BUILD_DIR="build-rg353v"

echo "=========================================="
echo "Building for RG353V (aarch64)"
echo "=========================================="

# Check if toolchain exists
if [ ! -d "$BUILDROOT_DIR/output/host" ]; then
    echo "Error: Buildroot toolchain not found!"
    echo "Please build the system first using the main build script."
    exit 1
fi

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Run CMake with toolchain
cmake \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DCMAKE_BUILD_TYPE=Release \
    ..

# Build
make -j$(nproc)

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo "Binary location: $BUILD_DIR/game_engine"
echo ""
echo "To test on RG353V:"
echo "1. Copy to overlay: cp game_engine ../rg353v-custom/board/rg353v/rootfs-overlay/opt/game/"
echo "2. Rebuild image: cd ../rg353v-custom/buildroot && make -j$(nproc)"
echo "3. Flash SD card: sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M status=progress"
echo ""
```

Make it executable:
```bash
chmod +x build-rg353v.sh
```

## Step 4: Cross-Compile Your Engine

```bash
# First, ensure Buildroot has finished building (this takes a while)
cd ~/rg353v-custom/buildroot
make BR2_EXTERNAL=.. rg353v_defconfig
make -j$(nproc)

# Then build your game engine
cd ~/your-game-engine
./build-rg353v.sh
```

## Step 5: Deploy to RG353V

### Method A: Rebuild entire image

```bash
# Copy your binary to the overlay
cp build-rg353v/game_engine ~/rg353v-custom/board/rg353v/rootfs-overlay/opt/game/

# Rebuild the system
cd ~/rg353v-custom/buildroot
make -j$(nproc)

# Flash to SD card (replace /dev/sdX with your SD card device)
sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M status=progress oflag=sync
```

### Method B: Update running system (faster iteration)

```bash
# Transfer via network (if you have SSH running)
scp build-rg353v/game_engine root@rg353v:/opt/game/

# Or mount the SD card rootfs partition
sudo mount /dev/sdX2 /mnt
sudo cp build-rg353v/game_engine /mnt/opt/game/
sudo umount /mnt
```

## Troubleshooting

### SDL2 not found during compilation

If CMake can't find SDL2, manually set the paths in your CMakeLists.txt:

```cmake
set(SDL2_INCLUDE_DIRS "${CMAKE_SYSROOT}/usr/include/SDL2")
set(SDL2_LIBRARIES "${CMAKE_SYSROOT}/usr/lib/libSDL2.so")
```

### OpenGL ES linking issues

Make sure you're linking against GLESv2, not desktop OpenGL:

```cmake
target_link_libraries(game_engine
    GLESv2  # OpenGL ES 3.2
    EGL     # EGL for context creation
)
```

### Runtime errors on device

1. Check logs:
```bash
cat /var/log/game.log
dmesg | tail
```

2. Verify library dependencies:
```bash
# On your dev machine, check the binary
aarch64-buildroot-linux-gnu-readelf -d build-rg353v/game_engine
```

3. Test manually on device:
```bash
# Get a shell instead of auto-launching
# (edit /sbin/game_init to drop to shell)
cd /opt/game
SDL_VIDEODRIVER=kmsdrm ./game_engine
```

## Performance Tips

1. **Optimize compilation flags** - Add to CMakeLists.txt:
```cmake
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -march=armv8-a -mtune=cortex-a55")
```

2. **Profile on device**:
```bash
# Install perf in buildroot config
BR2_PACKAGE_PERF=y

# Then on device
perf record -g ./game_engine
perf report
```

3. **GPU profiling**: Use ARM's tools or Mesa debug features

4. **Reduce binary size**:
```bash
# Strip symbols
aarch64-buildroot-linux-gnu-strip game_engine

# Use UPX compression (optional)
upx --best game_engine
```

## Next Steps

1. **Add your game logic** to the example code
2. **Implement asset loading** (textures, models, sounds)
3. **Add network features** (the WiFi stack is included)
4. **Create an update mechanism** for easier deployment
5. **Set up remote debugging** with gdbserver (included in buildroot)

## Controller Button Mapping

RG353V controls map to SDL_GameController:
- **D-Pad**: SDL_CONTROLLER_BUTTON_DPAD_*
- **A/B/X/Y**: SDL_CONTROLLER_BUTTON_A/B/X/Y
- **L1/R1**: SDL_CONTROLLER_BUTTON_LEFTSHOULDER/RIGHTSHOULDER
- **L2/R2**: SDL_CONTROLLER_AXIS_TRIGGERLEFT/TRIGGERRIGHT
- **L3/R3**: SDL_CONTROLLER_BUTTON_LEFTSTICK/RIGHTSTICK
- **Start/Select**: SDL_CONTROLLER_BUTTON_START/BACK
- **Analog Sticks**: SDL_CONTROLLER_AXIS_LEFTX/Y and RIGHTX/Y

## Additional Resources

- SDL2 Documentation: https://wiki.libsdl.org/
- OpenGL ES 3.2 Reference: https://www.khronos.org/opengles/
- Mesa Panfrost Driver: https://docs.mesa3d.org/drivers/panfrost.html
- Buildroot Manual: https://buildroot.org/docs.html