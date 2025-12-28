#!/bin/bash
# Improved Docker-based build for RG353V
# Fixes all the issues from the old Dockerfile

set -e

echo "=========================================="
echo "RG353V Docker Build Setup (IMPROVED)"
echo "=========================================="
echo ""
echo "This version fixes:"
echo "  ✓ Uses Debian (more stable than Ubuntu for Buildroot)"
echo "  ✓ Doesn't pre-download Buildroot (causes cache issues)"
echo "  ✓ Doesn't pre-configure (causes stale config problems)"
echo "  ✓ Better package versions and dependencies"
echo "  ✓ Proper volume mounting for iterative builds"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed!"
    echo "Install: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker is not running!"
    echo "Please start Docker Desktop and try again."
    exit 1
fi

echo "✓ Docker is available"
echo ""

# Create improved Dockerfile
cat > "$SCRIPT_DIR/Dockerfile" << 'DOCKERFILE_EOF'
FROM debian:bookworm-slim

# Install ALL required dependencies in one layer
# This is the complete list for Buildroot + U-Boot + Kernel
RUN apt-get update && apt-get install -y \
    # Core build tools
    build-essential \
    gcc \
    g++ \
    make \
    # Buildroot essentials
    git \
    wget \
    curl \
    cpio \
    unzip \
    rsync \
    bc \
    file \
    patch \
    perl \
    texinfo \
    # Python (for U-Boot)
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    # Libraries
    libncurses-dev \
    libssl-dev \
    libelf-dev \
    # Build tools
    bison \
    flex \
    gawk \
    tar \
    gzip \
    bzip2 \
    xz-utils \
    sed \
    grep \
    diffutils \
    findutils \
    # Compression tools
    lzip \
    lzop \
    # Device tree compiler
    device-tree-compiler \
    # Misc utilities
    vim-tiny \
    less \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages for U-Boot
# Use system packages first (preferred), then pip for missing ones
RUN apt-get update && apt-get install -y \
    python3-pyelftools \
    python3-setuptools \
    && rm -rf /var/lib/apt/lists/*

# pylibfdt might not be in system packages, install via pip with override
RUN pip3 install --break-system-packages --no-cache-dir pylibfdt || \
    echo "pylibfdt install failed, will try during build"

# Create non-root user for safer builds
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set locale (prevents encoding issues)
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y locales && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Switch to builder user
USER builder
WORKDIR /home/builder

CMD ["/bin/bash"]
DOCKERFILE_EOF

echo "✓ Improved Dockerfile created"

# Create docker-compose.yml
cat > "$SCRIPT_DIR/docker-compose.yml" << 'COMPOSE_EOF'
version: '3.8'

services:
  buildroot:
    build: .
    volumes:
      # Mount the ENTIRE project directory
      - .:/home/builder/work
      # Persist the download directory (saves bandwidth)
      - buildroot-dl:/home/builder/work/rg353v-custom/buildroot/buildroot-2024.02.1/dl
    working_dir: /home/builder/work
    tty: true
    stdin_open: true
    user: builder

volumes:
  buildroot-dl:
    driver: local
COMPOSE_EOF

echo "✓ docker-compose.yml created"

# Create the build script - THIS IS THE KEY IMPROVEMENT
cat > "$SCRIPT_DIR/docker-build.sh" << 'BUILD_SCRIPT_EOF'
#!/bin/bash
# This script runs INSIDE the Docker container
# It's designed to be run multiple times without issues

set -e

echo "=========================================="
echo "Building RG353V Firmware"
echo "=========================================="

# Navigate to buildroot directory
cd /home/builder/work/rg353v-custom/buildroot/buildroot-2024.02.1

# Only clean if explicitly requested
if [ "$1" = "clean" ]; then
    echo "Performing clean build..."
    make clean
fi

# Apply configuration
echo "Applying rg353v_defconfig..."
make BR2_EXTERNAL=/home/builder/work/rg353v-custom rg353v_defconfig

# Show configuration summary
echo ""
echo "Build configuration:"
echo "  Target: ARM64 (Cortex-A55)"
echo "  Toolchain: External (Bootlin)"
echo "  Kernel: 6.1.50"
echo "  U-Boot: 2023.07"
echo ""

# Build with all available cores
NUM_CORES=$(nproc)
echo "Building with $NUM_CORES CPU cores..."
echo "This will take 30-45 minutes on first build."
echo "Subsequent builds will be much faster (incremental)."
echo ""

# Run the build and capture output
make -j$NUM_CORES 2>&1 | tee /home/builder/work/build.log

# Check if build succeeded
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ Build Complete!"
    echo "=========================================="
    echo ""
    echo "Output images:"
    ls -lh output/images/ 2>/dev/null || echo "No images found in output/images/"
    echo ""
    echo "Files are in: rg353v-custom/buildroot/buildroot-2024.02.1/output/images/"
else
    echo ""
    echo "=========================================="
    echo "✗ Build Failed!"
    echo "=========================================="
    echo ""
    echo "Check the build log at: build.log"
    exit 1
fi
BUILD_SCRIPT_EOF

chmod +x "$SCRIPT_DIR/docker-build.sh"

echo "✓ Build script created"

# Create helper scripts
cat > "$SCRIPT_DIR/docker-shell.sh" << 'SHELL_EOF'
#!/bin/bash
# Open an interactive shell in the build container
echo "Opening interactive shell in build container..."
echo "You can run commands like:"
echo "  cd rg353v-custom/buildroot/buildroot-2024.02.1"
echo "  make menuconfig"
echo "  make -j$(nproc)"
docker-compose run --rm buildroot bash
SHELL_EOF

chmod +x "$SCRIPT_DIR/docker-shell.sh"

cat > "$SCRIPT_DIR/docker-clean.sh" << 'CLEAN_EOF'
#!/bin/bash
# Clean build artifacts
echo "Cleaning build artifacts..."
docker-compose run --rm buildroot /home/builder/work/docker-build.sh clean
echo "Clean complete!"
CLEAN_EOF

chmod +x "$SCRIPT_DIR/docker-clean.sh"

echo "✓ Helper scripts created"
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "KEY IMPROVEMENTS over old Dockerfile:"
echo "  ✓ Uses Debian Bookworm (more stable)"
echo "  ✓ Runs as non-root user (safer)"
echo "  ✓ Doesn't pre-configure (prevents stale configs)"
echo "  ✓ Persistent download volume (faster rebuilds)"
echo "  ✓ Incremental builds work properly"
echo "  ✓ Better error handling"
echo ""
echo "To build your firmware:"
echo ""
echo "  1. Build Docker image (first time only):"
echo "     docker-compose build"
echo ""
echo "  2. Run the build:"
echo "     docker-compose run --rm buildroot /home/builder/work/docker-build.sh"
echo ""
echo "  3. For clean build:"
echo "     docker-compose run --rm buildroot /home/builder/work/docker-build.sh clean"
echo ""
echo "Helpful commands:"
echo "  ./docker-shell.sh     - Open interactive shell"
echo "  ./docker-clean.sh     - Clean build artifacts"
echo ""
echo "=========================================="