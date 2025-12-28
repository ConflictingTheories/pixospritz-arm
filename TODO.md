# TODO: Build Custom Distro for Ambernic RG353V

## Phase 1: Environment Setup & Initial Build
- [x] Verify Buildroot directory exists and is extracted in rg353v-custom/buildroot/buildroot-2024.02.1
- [x] Execute rg353v_build_script.sh to configure Buildroot with external toolchain and start build (running, fixed PATH issues)

## Phase 2: Buildroot Compilation
- [x] Install gcc on build machine (completed)
- [x] Install gpatch (GNU patch) for Buildroot dependencies (completed)
- [x] Restart rg353v_build_script.sh after gcc installation completes (running, switching to external toolchain)
- [ ] Monitor Buildroot compilation for errors
- [ ] Troubleshoot any defconfig or toolchain issues if build fails
- [ ] Ensure output/images/sdcard.img is generated

## Phase 3: Game Engine Cross-Compilation
- [ ] Adjust build_script.arm64.sh paths if necessary for local execution (not Docker)
- [ ] Run build_script.arm64.sh to cross-compile the game engine
- [ ] Confirm 'pixospritz' executable is built in pixospritz-rg35xx-knulli/output/ or equivalent

## Phase 4: Integration into Rootfs Overlay
- [ ] Create /opt/game directory in rootfs-overlay if not exists
- [ ] Copy the compiled executable to rg353v-custom/board/rg353v/rootfs-overlay/opt/game/ and rename to 'game_engine' to match game_init
- [ ] Ensure game_init script is executable and correct

## Phase 5: Final Buildroot Rebuild
- [ ] Re-run make in Buildroot to incorporate overlay changes
- [ ] Verify updated sdcard.img is generated

## Followup Steps
- [ ] Test booting the image (e.g., via QEMU if possible)
- [ ] Address any remaining compilation errors in game engine
