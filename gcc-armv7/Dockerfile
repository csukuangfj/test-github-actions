# ============================================================
# Stage 1: build armv7 cross toolchain (gcc 11 + glibc 2.17)
# ============================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------
# Base build dependencies
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
    bzip2 \
    gzip \
    curl \
    unzip \
    python3 \
    ca-certificates \
    xz-utils \
    file \
    rsync \
    sudo \
    && rm -rf /var/lib/apt/lists/*
RUN update-ca-certificates


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
# ⭐ Create non-root user for ct-ng
# ------------------------------------------------------------
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Toolchain output directories
RUN mkdir -p /opt/build /opt/x-tools && \
    chown -R builder:builder /opt/build /opt/x-tools /opt/crosstool-ng

# ------------------------------------------------------------
# Switch to builder user ⭐
# ------------------------------------------------------------
USER builder
WORKDIR /opt/build

# ct-ng expects this
RUN mkdir -p /home/builder/.ct-ng

# ------------------------------------------------------------
# Copy ct-ng config
# ------------------------------------------------------------
COPY --chown=builder:builder ct-ng-armv7-gcc11.config .config

RUN ct-ng olddefconfig

# ------------------------------------------------------------
# Build toolchain (LONG STEP)
# ------------------------------------------------------------
RUN ct-ng build || ( \
    echo "========== ct-ng FAILED ==========" && \
    echo "---- last 200 lines of build.log ----" && \
    tail -n 200 build.log && \
    exit 1 )

# ============================================================
# Stage 2: runtime image
# ============================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    python3 \
    git \
    file \
    && rm -rf /var/lib/apt/lists/*

COPY --from=0 /opt/x-tools /opt/x-tools

ENV PATH="/opt/x-tools/armv7-unknown-linux-gnueabihf/bin:${PATH}"
ENV CC=armv7-unknown-linux-gnueabihf-gcc
ENV CXX=armv7-unknown-linux-gnueabihf-g++
ENV AR=armv7-unknown-linux-gnueabihf-ar
ENV LD=armv7-unknown-linux-gnueabihf-ld

WORKDIR /work
CMD ["/bin/bash"]

