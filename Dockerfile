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
    python3-pip \
    u-boot-tools \
    libelf-dev \
    bison \
    flex \
    gettext \
    swig \
    device-tree-compiler \
    && rm -rf /var/lib/apt/lists/*

# Install Python U-Boot dependencies via pip
RUN pip3 install pyelftools pylibfdt

# Set locale to avoid issues with some build tools
RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Set work directory to /workspace
WORKDIR /workspace

# Copy external tree configuration for build process
COPY rg353v-custom /workspace/rg353v-custom

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

# Configure Buildroot with the external tree, but do not start the full build yet.
RUN echo "Starting Buildroot configuration..." && \
    make BR2_EXTERNAL=/workspace/rg353v-custom rg353v_defconfig && \
    echo "Initial configuration complete. Full build will be triggered separately."
