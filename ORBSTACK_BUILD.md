# OrbStack Build Instructions

This guide will help you build the RG353V custom distro using OrbStack on macOS.

## Prerequisites

1. **Install OrbStack**: Download from https://orbstack.dev/
2. **OrbStack should automatically integrate with Docker CLI**

## Quick Start

### Option 1: Using Docker Compose (Recommended)

```bash
# Navigate to project directory
cd /Users/kderbyma/Desktop/projects/pixospritz-arm

# Start the build
docker-compose up --build

# This will take 1-2 hours on first run
```

### Option 2: Manual Docker Build

```bash
cd /Users/kderbyma/Desktop/projects/pixospritz-arm

# Build the Docker image
docker build -t pixospritz-buildroot:latest .

# Run the build container
docker run -it \
  -v $(pwd)/rg353v-custom:/workspace/rg353v-custom \
  pixospritz-buildroot:latest

# Inside the container, the build will start automatically
```

### Option 3: Interactive Build (Recommended for Debugging)

```bash
cd /Users/kderbyma/Desktop/projects/pixospritz-arm

# Build and enter the container interactively
docker build -t pixospritz-buildroot:latest .

# Run interactively with a shell
docker run -it \
  -v $(pwd)/rg353v-custom:/workspace/rg353v-custom \
  -w /workspace/rg353v-custom/buildroot/buildroot-2024.02.1 \
  --entrypoint /bin/bash \
  pixospritz-buildroot:latest

# Inside the container, run:
# make BR2_EXTERNAL=/workspace/rg353v-custom rg353v_defconfig
# make -j$(nproc)
```

## Monitoring Build Progress

Once the build is running, you can monitor it:

```bash
# In another terminal, check container logs
docker logs -f $(docker ps -q --filter "ancestor=pixospritz-buildroot:latest")

# Or enter the running container to see more details
docker exec -it <container_id> bash
```

## Build Output

After successful build, the artifacts will be in:
```
./rg353v-custom/buildroot/buildroot-2024.02.1/output/
```

Key files:
- `output/host/bin/aarch64-buildroot-linux-gnu-g++` - Cross compiler
- `output/images/sdcard.img` - Bootable SD card image
- `output/build/` - Build artifacts

## Next Steps After Build

1. **Cross-compile your game engine**:
   ```bash
   cd rg353v-custom/buildroot/buildroot-2024.02.1/output/host/bin
   ./aarch64-buildroot-linux-gnu-g++ -v  # Verify it works
   ```

2. **Copy game engine to overlay**:
   ```bash
   cp <compiled-game-engine> \
     rg353v-custom/board/rg353v/rootfs-overlay/opt/game/game_engine
   chmod +x rg353v-custom/board/rg353v/rootfs-overlay/opt/game/game_engine
   ```

3. **Rebuild to create final image**:
   ```bash
   docker run -it \
     -v $(pwd)/rg353v-custom:/workspace/rg353v-custom \
     -w /workspace/rg353v-custom/buildroot/buildroot-2024.02.1 \
     --entrypoint /bin/bash \
     pixospritz-buildroot:latest
   
   # Inside container:
   make -j$(nproc)
   ```

4. **Flash to SD card**:
   ```bash
   sudo dd if=rg353v-custom/buildroot/buildroot-2024.02.1/output/images/sdcard.img \
     of=/dev/sdX bs=4M status=progress
   ```

## Troubleshooting

### Build hangs or is slow
- OrbStack uses virtualization; performance depends on your Mac's specs
- Reduce parallel jobs: `make -j4` instead of `make -j$(nproc)`

### Permission denied errors
- Ensure the container can write to mounted volumes
- Try: `docker run --user root ...`

### Out of disk space
- OrbStack stores images in `~/.orbstack`
- Clean up: `docker system prune -a`

## Container Shell Access

If you want to explore the build system or debug issues:

```bash
# Get the container ID
CONTAINER_ID=$(docker ps -q --filter "ancestor=pixospritz-buildroot:latest" --latest)

# Enter the container
docker exec -it $CONTAINER_ID bash

# Check buildroot status
cd /workspace/rg353v-custom/buildroot/buildroot-2024.02.1
ls -la output/
```

## Performance Tips

1. **Allocate more resources to OrbStack**:
   - In OrbStack settings, increase CPU cores and RAM

2. **Enable BuildKit for faster builds**:
   ```bash
   export DOCKER_BUILDKIT=1
   docker build -t pixospritz-buildroot:latest .
   ```

3. **Cache layers properly**:
   - First build will be slow; subsequent builds reuse cached layers
   - Don't modify the Dockerfile frequently
