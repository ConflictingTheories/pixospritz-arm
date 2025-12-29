FROM debian:bookworm-slim



RUN apt-get update && apt-get install -y \
    # Sudo for non-root user
    sudo \
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
# Accept build arguments for UID/GID
ARG USER_UID=1000
ARG USER_GID=1000
# Install Python packages for U-Boot
RUN apt-get update && apt-get install -y \
    python3-pyelftools \
    python3-setuptools \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages --no-cache-dir pylibfdt || \
    echo "pylibfdt install failed, will try during build"

# Create builder user with MATCHING UID from host
# Handle the case where GID might already exist (like macOS GID 20)
RUN set -ex; \
    # Create group only if it doesn't exist
    if ! getent group ${USER_GID} > /dev/null 2>&1; then \
        groupadd -g ${USER_GID} builder; \
    fi; \
    # Create user with the specified UID and GID (even if group already exists)
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash builder; \
    # Give sudo access
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set locale
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
