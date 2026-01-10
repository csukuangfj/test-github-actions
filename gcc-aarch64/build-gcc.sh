#!/usr/bin/env bash
set -euxo pipefail

GCC_VERSION="$1"           # e.g. 11.4.0 / 12.3.0 / 13.2.0

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
  --with-system-zlib \
  --disable-bootstrap

make -s -j$(nproc)
make install-strip


# Reduce image size
rm -rf /tmp/gcc-${GCC_VERSION} /tmp/gcc-build

