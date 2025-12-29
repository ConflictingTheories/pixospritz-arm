# TODO: Build Custom Distro for Ambernic RG353V

## Phase 1: Environment Setup & Initial Build
- [x] Execute docker-compose build to build the Docker image (if not already built)
- [ ] Run docker-compose run --rm buildroot /home/builder/work/docker-build.sh to perform initial Buildroot build (switched to host script)
- [ ] Verify output/images/sdcard.img is generated in rg353v-custom/buildroot/buildroot-2024.02.1/output/images/

## Phase 2: Buildroot Compilation
- [ ] Ensure Buildroot is configured with make BR2_EXTERNAL=.. rg353v_defconfig and compiled with make -j$(nproc)
- [ ] Troubleshoot any errors in build.log if build fails

## Phase 3: Game Engine Cross-Compilation
- [ ] Run build_script_local.arm64.sh to cross-compile Pixospritz using the local toolchain
- [ ] Confirm pixospritz executable is built in pixospritz-rg35xx-knulli/output/compiled/pixospritz/

## Phase 4: Integration into Rootfs Overlay
- [ ] Create /opt/game directory in rg353v-custom/board/rg353v/rootfs-overlay/ if not exists
- [ ] Copy the compiled pixospritz to rg353v-custom/board/rg353v/rootfs-overlay/opt/game/game_engine
- [ ] Ensure game_init is executable

## Phase 5: Final Buildroot Rebuild
- [ ] Re-run make in Buildroot to incorporate overlay changes
- [ ] Verify updated sdcard.img

## Followup Steps
- [ ] Test booting the image (e.g., flash to SD card or use QEMU)
- [ ] Address any compilation errors in game engine or Buildroot
