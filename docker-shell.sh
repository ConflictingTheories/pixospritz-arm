#!/bin/bash
# Open an interactive shell in the build container
echo "Opening interactive shell in build container..."
echo "You can run commands like:"
echo "  cd rg353v-custom/buildroot/buildroot-2024.02.1"
echo "  make menuconfig"
echo "  make -j$(nproc)"
docker-compose run --rm buildroot bash
