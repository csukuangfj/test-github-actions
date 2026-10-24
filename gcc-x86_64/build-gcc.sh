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

# Note: we deliberately do NOT pass --with-default-libstdcxx-abi=gcc4-compatible.
# A stock gcc therefore defaults to _GLIBCXX_USE_CXX11_ABI=1, which is what
# consumers expect. Red Hat SCL devtoolset is built gcc4-compatible (ABI=0) and
# then ignores -D_GLIBCXX_USE_CXX11_ABI, which is the whole reason this image
# exists.
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
