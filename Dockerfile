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
