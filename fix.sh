#!/bin/bash
# Simpler fix: Don't use a Docker volume for dl/, just use regular mount

set -e

echo "=========================================="
echo "Simpler Fix: Remove Docker Volume"
echo "=========================================="
echo ""
echo "Problem: Docker volume for dl/ causing permission issues"
echo "Solution: Don't use a volume, just use regular directory mount"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clean existing dl directory
echo "Step 1: Cleaning dl/ directory..."
if [ -d "$SCRIPT_DIR/rg353v-custom/buildroot/dl" ]; then
    rm -rf "$SCRIPT_DIR/rg353v-custom/buildroot/dl"
    echo "  ✓ Removed old dl/"
fi

# Remove Docker volume
echo ""
echo "Step 2: Removing Docker volume..."
docker volume rm pixospritz-arm_buildroot-dl 2>/dev/null && echo "  ✓ Removed volume" || echo "  ✓ No volume to remove"

# Create simpler docker-compose WITHOUT volume
echo ""
echo "Step 3: Creating simplified docker-compose.yml (no volume)..."
cat > "$SCRIPT_DIR/docker-compose.yml" << 'COMPOSE_EOF'
version: '3.8'

services:
  buildroot:
    build:
      context: .
      args:
        USER_UID: 501
        USER_GID: 20
    volumes:
      # Just mount the entire project directory
      # No separate volume for dl/ - simpler and avoids permission issues
      - .:/home/builder/work
    working_dir: /home/builder/work
    tty: true
    stdin_open: true
COMPOSE_EOF

echo "  ✓ Created simplified docker-compose.yml"

echo ""
echo "=========================================="
echo "✓ Simplified Configuration Applied!"
echo "=========================================="
echo ""
echo "What changed:"
echo "  - Removed Docker volume for dl/ directory"
echo "  - Now using regular directory mount (simpler, fewer permission issues)"
echo "  - Downloads will be cached on your Mac at rg353v-custom/buildroot/dl/"
echo ""
echo "Now rebuild:"
echo "  docker-compose run --rm buildroot /home/builder/work/docker-build.sh"
echo ""