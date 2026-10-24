#!/usr/bin/env bash
set -euxo pipefail

GCC_VERSION="$1"           # e.g. 11.4.0 / 12.3.0 / 13.2.0
BINUTILS_VERSION="${BINUTILS_VERSION:-2.40}"

PREFIX=/opt/gcc-${GCC_VERSION}

mkdir -p /tmp/gcc-build
cd /tmp

# manylinux_2_24 is Debian 9 and EOL, so its apt mirrors are gone: install
# nothing and use what the image already ships. curl is present; wget is not.
# Fall back to the .tar.gz if xz is missing. release tarballs carry the
# generated parser sources and MAKEINFO=missing skips the manual, so
# bison/flex/texinfo are not required either.
fetch() {
  local name="$1"
  for ext in xz gz; do
    if [ "${ext}" = "gz" ] && ! command -v gzip >/dev/null 2>&1; then continue; fi
    if [ "${ext}" = "xz" ] && ! command -v xz >/dev/null 2>&1; then continue; fi
    curl -fsSL -O "https://ftp.gnu.org/gnu/${name%%-*}/${name}.tar.${ext}" && return 0
  done
  echo "ERROR: could not download ${name}" >&2
  return 1
}

# --- binutils -------------------------------------------------------------
# gcc ships only the compiler drivers: it invokes the *system* `as` and `ld`.
# Debian 9's binutils is 2.28 and cannot assemble what gcc 11+ emits for
# AVX-VNNI (x86_64) or aarch64+bf16 -- onnxruntime rejects both. So build a
# matching binutils into the same prefix and point gcc at it explicitly.
fetch binutils-${BINUTILS_VERSION}
tar xf binutils-${BINUTILS_VERSION}.tar.*
cd binutils-${BINUTILS_VERSION}
mkdir build && cd build
MAKEINFO=missing ../configure \
  --prefix="${PREFIX}" \
  --disable-multilib \
  --disable-nls \
  --disable-werror
make -s -j"$(nproc)"
make install-strip
cd /tmp

# --- gcc ------------------------------------------------------------------
fetch gcc-${GCC_VERSION}
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
MAKEINFO=missing ../configure \
  --prefix="${PREFIX}" \
  --enable-languages=c,c++ \
  --disable-multilib \
  --disable-bootstrap \
  --with-as="${PREFIX}/bin/as" \
  --with-ld="${PREFIX}/bin/ld"

make -s -j"$(nproc)"
make install-strip

# Reduce image size
rm -rf /tmp/gcc-* /tmp/binutils-* /tmp/gcc-build

"${PREFIX}/bin/gcc" --version
"${PREFIX}/bin/as" --version
"${PREFIX}/bin/ld" --version
