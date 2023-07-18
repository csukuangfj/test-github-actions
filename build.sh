#!/usr/bin/env bash

set -ex


if [ -z $PYTHON_VERSION ]; then
  echo "Please set the environment variable PYTHON_VERSION"
  echo "Example: export PYTHON_VERSION=3.8"
  # Valid values: 3.8, 3.9, 3.10, 3.11
  exit 1
fi

if [ -z $CUDA_VERSION ]; then
  echo "Please set the environment variable CUDA_VERSION"
  echo "Example: export CUDA_VERSION=10.2"
  # valid values: 10.2, 11.1, 11.3, 11.6, 11.7, 11.8
  exit 1
fi

if [ -z $TORCH_VERSION ]; then
  echo "Please set the environment variable TORCH_VERSION"
  echo "Example: export TORCH_VERSION=1.10.0"
  exit 1
fi

echo "Installing ${PYTHON_VERSION}.1"

yum -y install openssl-devel bzip2-devel libffi-devel xz-devel wget redhat-lsb-core

if [[ ${PYTHON_VERSION} =~ 3.6. ]]; then
  curl -O https://www.python.org/ftp/python/${PYTHON_VERSION}.1/Python-${PYTHON_VERSION}.1.tgz
  tar xf Python-${PYTHON_VERSION}.1.tgz
  pushd Python-${PYTHON_VERSION}.1

  PYTHON_INSTALL_DIR=$PWD/py-${PYTHON_VERSION}
  ./configure --enable-optimizations --enable-shared --prefix=$PYTHON_INSTALL_DIR
  make install


  popd
else
  case $PYTHON_VERSION in
    3.7)
      PYTHON_INSTALL_DIR=/opt/_internal/cpython-3.7.5
      ;;
    3.8)
      PYTHON_INSTALL_DIR=/opt/_internal/cpython-3.8.1
      ;;
    3.9)
      PYTHON_INSTALL_DIR=/opt/_internal/cpython-3.9.0
      ;;
    3.10)
      PYTHON_INSTALL_DIR=/opt/_internal/cpython-3.10.1
      ;;
    3.11)
      PYTHON_INSTALL_DIR=/opt/_internal/cpython-3.11.0
      ;;
    *)
      echo "Unsupported Python version: ${PYTHON_VERSION}"
      exit 1
      ;;
  esac
fi

export PATH=$PYTHON_INSTALL_DIR/bin:$PATH
export LD_LIBRARY_PATH=$PYTHON_INSTALL_DIR/lib:$LD_LIBRARY_PATH

python3 --version
which python3

curl -O https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py

python3 -m pip install -U pip cmake
python3 -m pip install wheel twine typing_extensions
python3 -m pip install bs4 requests tqdm auditwheel

echo "Installing torch"
./install_torch.sh

rm -rf ~/.cache/pip
yum clean all

echo "Downloading k2"
git clone --depth 1 https://github.com/k2-fsa/k2
cd k2

export CMAKE_CUDA_COMPILER_LAUNCHER=
export K2_CMAKE_ARGS=" -DPYTHON_EXECUTABLE=$PYTHON_INSTALL_DIR/bin/python3 "
export K2_MAKE_ARGS=" -j2 "

python3 setup.py bdist_wheel

# cp ./dist/*.whl /var/www

auditwheel --verbose repair \
  --exclude libc10.so \
  --exclude libc10_cuda.so \
  --exclude libcuda.so.1 \
  --exclude libcudart.so.${CUDA_VERSION} \
  --exclude libnvToolsExt.so.1 \
  --exclude libnvrtc.so.${CUDA_VERSION} \
  --exclude libtorch.so \
  --exclude libtorch_cpu.so \
  --exclude libtorch_cuda.so \
  --exclude libtorch_python.so \
  \
  --exclude libcudnn.so.8 \
  --exclude libcublas.so.11 \
  --exclude libcublasLt.so.11 \
  --exclude libcudart.so.11.0 \
  --exclude libnvrtc.so.11.2 \
  --exclude libtorch_cuda_cu.so \
  --exclude libtorch_cuda_cpp.so \
  --plat manylinux_2_17_x86_64 \
  -w ../var/www \
  dist/*.whl
