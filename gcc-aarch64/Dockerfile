FROM quay.io/pypa/manylinux2014_aarch64

# ARG GCC_VERSION=11.4.0
ARG GCC_VERSION

ENV PREFIX=/opt/gcc-${GCC_VERSION}

# Install build deps
# Install EPEL + build deps
RUN yum install -y \
      epel-release \
 && yum install -y \
      wget \
      make \
      bison \
      flex \
      texinfo \
      gmp-devel \
      mpfr-devel \
      libmpc-devel \
      zlib-devel \
      ccache \
 && yum clean all

# Configure ccache
ENV CCACHE_DIR=/ccache
ENV CCACHE_MAXSIZE=10G
ENV PATH=/usr/lib64/ccache:${PATH}

# Build GCC
COPY build-gcc.sh /build-gcc.sh
RUN bash /build-gcc.sh ${GCC_VERSION}

# Expose GCC
ENV PATH=${PREFIX}/bin:${PATH}
ENV LD_LIBRARY_PATH=${PREFIX}/lib64:${PREFIX}/lib:${LD_LIBRARY_PATH}

# Sanity checks
RUN gcc --version && g++ --version && ldd --version

