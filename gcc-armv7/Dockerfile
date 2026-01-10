# ============================================================
# Stage 1: build armv7 cross toolchain (gcc 11 + glibc 2.17)
# ============================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------
# Base build dependencies (crosstool-ng 官方推荐)
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    bison \
    flex \
    texinfo \
    help2man \
    gawk \
    libncurses5-dev \
    libncursesw5-dev \
    libtool \
    libtool-bin \
    automake \
    autoconf \
    patch \
    git \
    wget \
    curl \
    unzip \
    python3 \
    ca-certificates \
    xz-utils \
    file \
    rsync \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Build & install crosstool-NG
# ------------------------------------------------------------
WORKDIR /opt

RUN git clone https://github.com/crosstool-ng/crosstool-ng.git && \
    cd crosstool-ng && \
    git checkout crosstool-ng-1.25.0 && \
    ./bootstrap && \
    ./configure --prefix=/opt/crosstool-ng && \
    make -j$(nproc) && \
    make install

ENV PATH="/opt/crosstool-ng/bin:${PATH}"

# ------------------------------------------------------------
# Prepare build directories
# ------------------------------------------------------------
RUN mkdir -p \
    /opt/build \
    /opt/x-tools \
    /root/.ct-ng

WORKDIR /opt/build

# ------------------------------------------------------------
# Copy ct-ng config
# ------------------------------------------------------------
COPY ct-ng-armv7-gcc11.config .config

# Normalize config (important!)
RUN ct-ng olddefconfig

# ------------------------------------------------------------
# Build toolchain (this is the long step)
# ------------------------------------------------------------
RUN ct-ng build

# ============================================================
# Stage 2: runtime / usage image (smaller)
# ============================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Runtime deps (enough to compile projects)
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    python3 \
    git \
    file \
    && rm -rf /var/lib/apt/lists/*

# Copy toolchain
COPY --from=0 /opt/x-tools /opt/x-tools

# Export toolchain
ENV PATH="/opt/x-tools/armv7-unknown-linux-gnueabihf/bin:${PATH}"
ENV CC=armv7-unknown-linux-gnueabihf-gcc
ENV CXX=armv7-unknown-linux-gnueabihf-g++
ENV AR=armv7-unknown-linux-gnueabihf-ar
ENV LD=armv7-unknown-linux-gnueabihf-ld
ENV STRIP=armv7-unknown-linux-gnueabihf-strip

WORKDIR /work

CMD ["/bin/bash"]

