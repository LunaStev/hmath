# SPDX-License-Identifier: MPL-2.0

project(
    'hmath',
    'c',
    version: '0.1.0',
    meson_version: '>=0.63.0',
    default_options: ['c_std=c11', 'buildtype=release']
)

cabal = find_program('cabal')
python = import('python').find_installation('python3')

hmath_sources = files(
    'hmath.cabal',
    'cabal.project',
    'include/hmath.h',
    'cbits/runtime.c',
    'src/HMath.hs',
    'src/HMath/Basic.hs',
    'src/HMath/Linear.hs',
    'src/HMath/Matrix.hs',
    'src/HMath/Statistics.hs',
    'src/HMath/FFI.hs'
)

hmath = custom_target(
    'hmath',
    output: 'libhmath.so',
    input: hmath_sources,
    command: [
        python,
        files('meson-build.py'),
        meson.current_source_dir(),
        '@OUTPUT@'
    ],
    build_by_default: true,
    console: true,
    install: true,
    install_dir: get_option('libdir')
)

install_headers('include/hmath.h')

hmath_c_test = executable(
    'hmath-c-test',
    'examples/c/main.c',
    include_directories: include_directories('include'),
    link_with: hmath,
    build_rpath: meson.current_build_dir(),
    install: false
)

test('hmath-c-ffi', hmath_c_test)

test(
    'hmath-python-ffi',
    python,
    args: [files('examples/python/main.py')],
    env: {
        'HMATH_LIBRARY': hmath.full_path()
    },
    depends: hmath
)
