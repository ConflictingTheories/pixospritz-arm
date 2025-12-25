# Pixospritz ARM - Ambernic Custom Distro OS

This project outlines the ARM specific version of the pixospritz game console and engine. This is the Ambernic RG353V Custom OS.

It will autoboot into the game-engine (with crash recovery, soft resets, hard resets)

---

Gamepad controls will be wired into console logic.

---

This will be the "hardware" console of the platform. IT will be fully compatible with the web platform and general pixospritz ecosystem.


# 1. Run the build script
bash rg353v_build_script.sh

# 2. Wait for Buildroot to compile (1-2 hours first time)
cd ~/rg353v-custom/buildroot
make BR2_EXTERNAL=.. rg353v_defconfig
make -j$(nproc)

# 3. Cross-compile your game engine
cd ~/your-game-engine
./build-rg353v.sh

# 4. Copy to overlay and rebuild
cp build-rg353v/game_engine ~/rg353v-custom/board/rg353v/rootfs-overlay/opt/game/
cd ~/rg353v-custom/buildroot
make -j$(nproc)

# 5. Flash to SD card
sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M status=progress