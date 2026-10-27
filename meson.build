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
    'src/HMath/Error.hs',
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

# Cabal and the shared-library build use the same source-tree build directory.
test(
    'hmath-haskell',
    cabal,
    args: ['test', 'hmath-tests', '--test-show-details=direct'],
    workdir: meson.current_source_dir(),
    depends: hmath,
    is_parallel: false,
    timeout: 120
)

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

test(
    'hmath-python-ffi-optimized',
    python,
    args: ['-O', files('examples/python/main.py')],
    env: {'HMATH_LIBRARY': hmath.full_path()},
    depends: hmath
)

# Each lifecycle scenario runs in a fresh process against the real GHC RTS.
test(
    'hmath-ffi-lifecycle',
    python,
    args: [files('test/ffi_lifecycle.py'), hmath.full_path()],
    depends: hmath,
    timeout: 45
)

# Test-only libraries prove each example exits unsuccessfully on wrong results.
# They are never linked into the published library or installed.
foreach fault : [
    ['addition', 1, 'addition: expected'],
    ['factorial', 2, 'factorial(10): expected'],
    ['mean', 3, 'mean: expected'],
    ['dot', 4, 'dot: expected'],
]
    bad_library = shared_library(
        'hmath-bad-' + fault[0],
        'test/ffi_bad_results.c',
        include_directories: include_directories('include'),
        c_args: ['-DHMATH_TEST_FAULT=' + fault[1].to_string()],
        install: false
    )
    bad_c_client = executable(
        'hmath-c-bad-' + fault[0],
        'examples/c/main.c',
        include_directories: include_directories('include'),
        link_with: bad_library,
        install: false
    )
    test(
        'hmath-ffi-reject-' + fault[0],
        python,
        args: [
            files('test/ffi_failure_detection.py'),
            '--c-client', bad_c_client.full_path(),
            '--python-example', files('examples/python/main.py'),
            '--library', bad_library.full_path(),
            '--diagnostic', fault[2],
        ],
        depends: [bad_c_client, bad_library],
        timeout: 20
    )
endforeach
