#!/usr/bin/env bash
set -euxo pipefail

# The whole point of this image is a gcc on a glibc 2.17 base whose *default*
# C++ ABI is the C++11 one (std::__cxx11::basic_string). Red Hat SCL devtoolset
# is built --with-default-libstdcxx-abi=gcc4-compatible: it silently forces
# _GLIBCXX_USE_CXX11_ABI=0 and ignores -D_GLIBCXX_USE_CXX11_ABI=1, which is why
# it cannot be used to produce a C++11-ABI archive.
#
# std::string has to appear in a mangled signature for the ABI to be visible in
# the symbol table -- a function *returning* std::string does not encode its
# return type, so take it as a parameter instead.

cat > /tmp/abi-check.cc <<'EOF'
#include <string>
void take(std::string const& s) { (void)s; }
EOF

g++ -std=c++17 -c /tmp/abi-check.cc -o /tmp/abi-check.o

echo "---- nm /tmp/abi-check.o ----"
nm /tmp/abi-check.o

if nm /tmp/abi-check.o | grep -q '__cxx11'; then
  echo "OK: the default _GLIBCXX_USE_CXX11_ABI is 1 (C++11 ABI)"
else
  echo "ERROR: this gcc defaults to the old COW std::string ABI" >&2
  echo "       (_GLIBCXX_USE_CXX11_ABI=0). It is not a usable replacement" >&2
  echo "       for Red Hat SCL devtoolset." >&2
  exit 1
fi

# Confirm -D_GLIBCXX_USE_CXX11_ABI is actually honoured, not overridden by the
# headers the way devtoolset does it.
g++ -std=c++17 -D_GLIBCXX_USE_CXX11_ABI=0 -c /tmp/abi-check.cc -o /tmp/abi-check-0.o
if nm /tmp/abi-check-0.o | grep -q '__cxx11'; then
  echo "ERROR: -D_GLIBCXX_USE_CXX11_ABI=0 was ignored" >&2
  exit 1
fi
echo "OK: -D_GLIBCXX_USE_CXX11_ABI is honoured in both directions"

rm -f /tmp/abi-check.cc /tmp/abi-check.o /tmp/abi-check-0.o
