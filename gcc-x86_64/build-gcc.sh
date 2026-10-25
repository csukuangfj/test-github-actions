#!/usr/bin/env bash
set -euxo pipefail

GCC_VERSION="$1"           # e.g. 11.4.0 / 12.3.0 / 13.2.0
BINUTILS_VERSION="${BINUTILS_VERSION:-2.40}"

PREFIX=/opt/gcc-${GCC_VERSION}

# Skip the manuals: texinfo is not in the base image and cannot be apt-
# installed (Debian 9 is EOL). MAKEINFO=missing is enough for gcc but not
# for binutils -- its doc rules still shell out and die with Error 127 --
# so pass MAKEINFO=true on the make command line instead, which overrides
# whatever each sub-configure wrote into its Makefile.
export MAKEINFO=true

# Belt and braces: put a makeinfo/install-info that succeed without doing
# anything on PATH. binutils' sub-configures (bfd, gas, ld, ...) re-detect
# makeinfo and write `missing makeinfo` into their own Makefiles regardless of
# the MAKEINFO environment variable, so a stub on PATH is what actually stops
# the doc rules from dying; MAKEINFO=true on the make lines covers the rest.
mkdir -p /usr/local/bin
for tool in makeinfo install-info; do
  printf '#!/bin/sh\nexit 0\n' > /usr/local/bin/${tool}
  chmod +x /usr/local/bin/${tool}
done
export PATH=/usr/local/bin:${PATH}

mkdir -p /tmp/gcc-build
cd /tmp

# Fall back to the .tar.gz if xz is missing. release tarballs carry the
# generated parser sources and MAKEINFO=true skips the manual, so
# bison/flex/texinfo are not required either.
# Download <url>.tar.xz or <url>.tar.gz. The caller passes the URL without the
# extension because the GNU mirror layout is not uniform: binutils is flat
# (/gnu/binutils/binutils-2.40.tar.gz) while gcc nests each release in its own
# directory (/gnu/gcc/gcc-11.4.0/gcc-11.4.0.tar.gz).
fetch() {
  local url="$1"
  for ext in xz gz; do
    if [ "${ext}" = "xz" ] && ! command -v xz >/dev/null 2>&1; then continue; fi
    if [ "${ext}" = "gz" ] && ! command -v gzip >/dev/null 2>&1; then continue; fi
    curl -fsSL -O "${url}.tar.${ext}" && return 0
  done
  echo "ERROR: could not download ${url}" >&2
  return 1
}

# --- binutils -------------------------------------------------------------
# gcc ships only the compiler drivers: it invokes whatever `as` and `ld` are
# on PATH. Both the manylinux2014 (devtoolset-10) and manylinux_2_24 (Debian 9)
# bases ship binutils too old for what gcc 11+ emits -- vpdpbusds (AVX512-VNNI)
# on x86_64, aarch64+bf16 -- which onnxruntime does not accept. So build a
# matching binutils into the same prefix and point gcc at it explicitly.
fetch "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}"
tar xf binutils-${BINUTILS_VERSION}.tar.*
cd binutils-${BINUTILS_VERSION}
mkdir build && cd build
../configure \
  --prefix="${PREFIX}" \
  --disable-multilib \
  --disable-nls \
  --disable-werror \
  --disable-gprofng
make -s -j"$(nproc)" MAKEINFO=true INSTALL_INFO=true
make install-strip MAKEINFO=true INSTALL_INFO=true
cd /tmp

# --- gcc ------------------------------------------------------------------
fetch "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}"
tar xf gcc-${GCC_VERSION}.tar.*
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
#
# --with-as/--with-ld bake the tool paths into the driver, so the compiler
# cannot silently fall back to the system binutils at build time either.
../configure \
  --prefix="${PREFIX}" \
  --enable-languages=c,c++ \
  --disable-multilib \
  --disable-bootstrap \
  --with-as="${PREFIX}/bin/as" \
  --with-ld="${PREFIX}/bin/ld"

make -s -j"$(nproc)" MAKEINFO=true INSTALL_INFO=true
make install-strip MAKEINFO=true INSTALL_INFO=true

# Reduce image size. cd out first: we are still inside /tmp/gcc-*.
cd /
rm -rf /tmp/gcc-* /tmp/binutils-* /tmp/gcc-build

"${PREFIX}/bin/gcc" --version
"${PREFIX}/bin/as" --version
"${PREFIX}/bin/ld" --version
