FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ---------- 基础依赖 ----------
RUN apt-get update && apt-get install -y \
    build-essential \
    bison flex \
    texinfo help2man \
    gawk \
    libncurses-dev \
    libtool libtool-bin \
    autoconf automake \
    wget curl git \
    python3 \
    unzip \
    ca-certificates \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# ---------- crosstool-ng ----------
WORKDIR /opt
RUN git clone https://github.com/crosstool-ng/crosstool-ng.git
WORKDIR /opt/crosstool-ng
RUN ./bootstrap && \
    ./configure --enable-local && \
    make -j$(nproc)

ENV PATH=/opt/crosstool-ng:${PATH}

# ---------- ct-ng config ----------
WORKDIR /opt/build

COPY ct-ng-armv7-gcc11.config .config

# ---------- build toolchain ----------
RUN ct-ng build

# ---------- final location ----------
RUN mv /opt/x-tools /opt/cross

ENV PATH=/opt/cross/armv7-unknown-linux-gnueabihf/bin:$PATH

