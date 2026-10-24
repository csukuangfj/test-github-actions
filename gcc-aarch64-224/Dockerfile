FROM quay.io/pypa/manylinux_2_24_aarch64

# ARG GCC_VERSION=11.4.0
ARG GCC_VERSION

ENV PREFIX=/opt/gcc-${GCC_VERSION}

# No packages are installed here. manylinux_2_24 is Debian 9, which went EOL in
# 2022 and whose apt mirrors are gone, so `apt-get update` is unreliable. The
# base image already ships everything the build needs (curl, make, binutils, a
# bootstrap g++); build-gcc.sh fetches gmp/mpfr/mpc itself and skips the manual.

# Build GCC
COPY build-gcc.sh /build-gcc.sh
RUN bash /build-gcc.sh ${GCC_VERSION}

# Expose GCC
ENV PATH=${PREFIX}/bin:${PATH}
ENV LD_LIBRARY_PATH=${PREFIX}/lib64:${PREFIX}/lib:${LD_LIBRARY_PATH}

# Sanity checks
# as/ld must come from the binutils we build: gcc falls back to the system
# ones otherwise, and Debian 9's binutils 2.28 cannot assemble AVX-VNNI
# (x86_64) or aarch64+bf16.
RUN gcc --version && g++ --version && as --version && ld --version && ldd --version \
 && as_path="$(command -v as)" \
 && echo "as=${as_path}" \
 && case "${as_path}" in /opt/gcc-*) ;; *) echo "ERROR: ${as_path} is the system binutils"; exit 1 ;; esac

# The point of this image is a gcc on a glibc 2.24 base whose default C++ ABI is
# the C++11 one. Red Hat SCL devtoolset is built
# --with-default-libstdcxx-abi=gcc4-compatible, so it silently forces
# _GLIBCXX_USE_CXX11_ABI=0 and ignores -D_GLIBCXX_USE_CXX11_ABI=1. Verify the
# default here so we never publish a devtoolset-like image again.
COPY check-cxx11-abi.sh /check-cxx11-abi.sh
RUN bash /check-cxx11-abi.sh
