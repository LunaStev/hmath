#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Run inside the official manylinux_2_28_x86_64 image, with this checkout at /io.
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
dnf install -y gmp-devel ncurses-devel libffi-devel

if [ ! -x /opt/ghc/bin/ghc ]; then
  curl --fail --location --retry 3 -o ghc.tar.xz \
    https://downloads.haskell.org/~ghc/9.10.3/ghc-9.10.3-x86_64-rocky8-linux.tar.xz
  echo 'd0504f094b827e64653f8e8d7b4b3029bf7ff026f5091c0b22366dcd1b032f2d  ghc.tar.xz' | sha256sum --check
  tar -xf ghc.tar.xz
  cd ghc-9.10.3-x86_64-unknown-linux
  ./configure --prefix=/opt/ghc
  make install > "$work/ghc-install.log" 2>&1 || { tail -40 "$work/ghc-install.log"; exit 1; }
  export PATH="/opt/ghc/bin:$PATH"
  cd "$work"
  curl --fail --location --retry 3 -o cabal.tar.xz \
    https://downloads.haskell.org/cabal/cabal-install-3.16.1.0/cabal-install-3.16.1.0-x86_64-linux-rocky8.tar.xz
  echo '9d3c8be81bfd4c9ddc394ff6995369d5babb8ce431bb8eddda806011a903af69  cabal.tar.xz' | sha256sum --check
  tar -xf cabal.tar.xz cabal
  install cabal /usr/local/bin/cabal
fi
export PATH="/opt/ghc/bin:$PATH"

python=/opt/python/cp312-cp312/bin/python
"$python" -m pip install 'build==1.3.0' 'auditwheel==6.8.2' 'patchelf==0.17.2.4'
"$python" /io/meson-build.py /io "$work/libhmath.so" --builddir "$work/cabal-build" --offline
cd /io
HMATH_BUILD_LIBRARY="$work/libhmath.so" "$python" -m build --wheel --outdir "$work/wheels"
"$python" -m auditwheel repair --strip --plat manylinux_2_28_x86_64 \
  --wheel-dir /io/dist "$work"/wheels/*.whl
"$python" -m build --sdist --outdir /io/dist
"$python" -m auditwheel show /io/dist/*.whl

# An sdist must really build without the wheel staging environment variable.
mkdir "$work/source"
tar -xf /io/dist/hmath_python-*.tar.gz -C "$work/source"
cd "$work"/source/hmath_python-*
"$python" -m build --wheel --outdir "$work/source-wheel"
