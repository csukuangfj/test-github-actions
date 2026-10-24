#!/usr/bin/env bash
set -euxo pipefail

GCC_VERSION="$1"           # e.g. 11.4.0 / 12.3.0 / 13.2.0

PREFIX=/opt/gcc-${GCC_VERSION}

mkdir -p /tmp/gcc-build
cd /tmp

# manylinux_2_24 is Debian 9 and EOL, so its apt mirrors are gone: install
# nothing and use what the image already ships. curl is present; wget is not.
# Fall back to the .tar.gz if xz is missing. release tarballs carry the
# generated parser sources and MAKEINFO=missing skips the manual, so
# bison/flex/texinfo are not required either.
ARCHIVE=gcc-${GCC_VERSION}.tar.xz
if ! command -v xz >/dev/null 2>&1; then
  ARCHIVE=gcc-${GCC_VERSION}.tar.gz
fi

curl -fsSL -O "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/${ARCHIVE}"
tar xf "${ARCHIVE}"
cd gcc-${GCC_VERSION}

# Downloads and builds GMP, MPFR and MPC in-tree, so no -devel packages needed.
./contrib/download_prerequisites

mkdir build
cd build

# Note: we deliberately do NOT pass --with-default-libstdcxx-abi=gcc4-compatible.
# A stock gcc therefore defaults to _GLIBCXX_USE_CXX11_ABI=1, which is what
# consumers expect. Red Hat SCL devtoolset is built gcc4-compatible (ABI=0) and
# then ignores -D_GLIBCXX_USE_CXX11_ABI, which is why it cannot be used to
# produce a C++11-ABI archive.
MAKEINFO=missing ../configure \
  --prefix=${PREFIX} \
  --enable-languages=c,c++ \
  --disable-multilib \
  --disable-bootstrap

make -s -j$(nproc)
make install-strip

# Reduce image size
rm -rf /tmp/gcc-${GCC_VERSION} /tmp/gcc-build /tmp/${ARCHIVE}
