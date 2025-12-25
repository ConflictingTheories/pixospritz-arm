# TODO: Build RG353V Custom Game Engine Distro

- [x] Run build script to set up project structure
- [x] Fix toolchain path in toolchain-rg353v.cmake
- [x] Fix external.desc name to match defconfig variables
- [ ] Run make rg353v_defconfig to configure Buildroot
- [ ] Run make -j$(nproc) to build the system
- [ ] Cross-compile the game engine using CMake and toolchain
- [ ] Copy compiled game engine to rootfs overlay
- [ ] Rebuild the SD card image
- [ ] Flash image to SD card (requires user to specify device)
