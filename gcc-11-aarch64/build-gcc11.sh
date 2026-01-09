#!/usr/bin/env bash
set -euxo pipefail

GCC_VERSION=11.4.0
PREFIX=/opt/gcc-${GCC_VERSION}

mkdir -p /tmp/gcc-build
cd /tmp

wget https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz
tar xf gcc-${GCC_VERSION}.tar.xz
cd gcc-${GCC_VERSION}

# Download prerequisites (GMP, MPFR, MPC sources)
./contrib/download_prerequisites

mkdir build
cd build

# Use ccache
export CC="ccache gcc"
export CXX="ccache g++"

../configure \
  --prefix=${PREFIX} \
  --enable-languages=c,c++ \
  --disable-multilib \
  --with-system-zlib

make -j$(nproc)
make install

# Reduce image size
rm -rf /tmp/gcc-${GCC_VERSION} /tmp/gcc-build

