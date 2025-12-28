set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Set the toolchain paths to Bootlin toolchain
set(TOOLCHAIN_PREFIX "/opt/aarch64--glibc--stable-2022.08-1")
set(CMAKE_SYSROOT "${TOOLCHAIN_PREFIX}/aarch64-linux/sysroot")

# Specify the cross compilers
set(CMAKE_C_COMPILER "${TOOLCHAIN_PREFIX}/bin/aarch64-linux-gcc")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_PREFIX}/bin/aarch64-linux-g++")

# Set CMAKE_FIND_ROOT_PATH
set(CMAKE_FIND_ROOT_PATH "${CMAKE_SYSROOT}")

# Adjust the default behavior of the find commands
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# SDL2 and OpenGL paths
set(SDL2_INCLUDE_DIRS "${CMAKE_SYSROOT}/usr/include/SDL2")
set(SDL2_LIBRARIES "${CMAKE_SYSROOT}/usr/lib/libSDL2.so")
set(OPENGL_INCLUDE_DIR "${CMAKE_SYSROOT}/usr/include")
