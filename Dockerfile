FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libncurses-dev \
    git \
    wget \
    curl \
    bc \
    bzip2 \
    cpio \
    rsync \
    file \
    unzip \
    pkg-config \
    libssl-dev \
    python3 \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create work directory
WORKDIR /workspace

# Copy external tree configuration
COPY rg353v-custom/board ./rg353v-custom/board
COPY rg353v-custom/configs ./rg353v-custom/configs
COPY rg353v-custom/package ./rg353v-custom/package
COPY rg353v-custom/Config.in ./rg353v-custom/
COPY rg353v-custom/external.desc ./rg353v-custom/
COPY rg353v-custom/external.mk ./rg353v-custom/

# Rename the config file to lowercase
RUN cd /workspace/rg353v-custom/configs && \
    if [ -f "RG353V_defconfig" ]; then \
        mv RG353V_defconfig rg353v_defconfig; \
    fi

# Download Buildroot fresh inside the container
RUN cd /workspace/rg353v-custom && \
    mkdir -p buildroot && \
    cd buildroot && \
    echo "Downloading Buildroot 2024.02.1..." && \
    wget -q https://buildroot.org/downloads/buildroot-2024.02.1.tar.gz && \
    tar xzf buildroot-2024.02.1.tar.gz && \
    rm buildroot-2024.02.1.tar.gz && \
    echo "Buildroot extracted successfully"

# Set working directory to buildroot
WORKDIR /workspace/rg353v-custom/buildroot/buildroot-2024.02.1

# Configure and build
RUN echo "Starting Buildroot configuration..." && \
    make BR2_EXTERNAL=/workspace/rg353v-custom rg353v_defconfig && \
    echo "Configuration complete. Starting build (this will take 1-2 hours)..." && \
    make -j$(nproc) && \
    echo "Build complete!"
