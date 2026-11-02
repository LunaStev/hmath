# SPDX-License-Identifier: MPL-2.0
project('hmath', 'c', version: '1.1.0', meson_version: '>=1.3.0',
        default_options: ['c_std=c11', 'warning_level=2', 'buildtype=release'])
cabal = find_program('cabal')
python = import('python').find_installation('python3')
fs = import('fs')
if get_option('default_library') != 'shared'
    error('Cabal currently supports native-shared foreign libraries only; static native archives are not implemented.')
endif
if get_option('gpu').enabled()
    error('GPU execution is tracked in issue #41 and is not available in this build.')
endif
if meson.is_cross_build() and get_option('ghc') == ''
    error('A cross build requires an explicit target GHC through -Dghc=; the host compiler is never substituted.')
endif
buildtype = get_option('buildtype')
if not ['debug', 'debugoptimized', 'release', 'minsize'].contains(buildtype)
    error('Use debug, debugoptimized, release or minsize to select consistent C/GHC flags.')
endif
zlib = dependency('zlib', required: get_option('compression'))
compression = zlib.found() ? 'enabled' : 'disabled'
cabal_builddir = meson.current_build_dir() / 'cabal'
build_args = ['--builddir', cabal_builddir, '--buildtype', buildtype,
              '--compression', compression, '--cabal', cabal.full_path(),
              '--native-backend', get_option('native_backend') ? 'enabled' : 'disabled']
if get_option('ghc') != ''
    build_args += ['--ghc', get_option('ghc')]
endif
if get_option('werror')
    build_args += ['--werror']
endif
if get_option('offline')
    build_args += ['--offline']
endif
hmath_sources = files(
    'cabal.project',
    'cbits/algebra.c',
    'cbits/autodiff_bindings.c',
    'cbits/backend.c',
    'cbits/buffer.c',
    'cbits/bytes.c',
    'cbits/deeplearning.c',
    'cbits/error_wire.c',
    'cbits/execution.c',
    'cbits/expression.c',
    'cbits/foundation.c',
    'cbits/geometry.c',
    'cbits/graph_bindings.c',
    'cbits/image.c',
    'cbits/interchange.c',
    'cbits/interchange_io.c',
    'cbits/linear.c',
    'cbits/machinelearning.c',
    'cbits/matrix_bindings.c',
    'cbits/matrix_internal.h',
    'cbits/matrix_value.c',
    'cbits/native.c',
    'cbits/native_dlpack.c',
    'cbits/native_internal.h',
    'cbits/numeric_generated.c',
    'cbits/numeric_internal.h',
    'cbits/numeric_objects.c',
    'cbits/numeric_types.c',
    'cbits/numerical.c',
    'cbits/optimization.c',
    'cbits/optimization_all.c',
    'cbits/polynomial.c',
    'cbits/rotations.c',
    'cbits/runtime.c',
    'cbits/scalar_extras.c',
    'cbits/shape.c',
    'cbits/spectral.c',
    'cbits/stochastic.c',
    'cbits/tensor_bindings.c',
    'cbits/timeseries.c',
    'cbits/units.c',
    'cbits/value.c',
    'cbits/value_internal.h',
    'hmath.cabal',
    'include/hmath.h',
    'include/hmath_algebra.h',
    'include/hmath_autodiff.h',
    'include/hmath_backend.h',
    'include/hmath_buffer.h',
    'include/hmath_bytes.h',
    'include/hmath_callback.h',
    'include/hmath_deeplearning.h',
    'include/hmath_dlpack.h',
    'include/hmath_error.h',
    'include/hmath_execution.h',
    'include/hmath_expression.h',
    'include/hmath_expression_error.h',
    'include/hmath_foundation.h',
    'include/hmath_geometry.h',
    'include/hmath_graph.h',
    'include/hmath_image.h',
    'include/hmath_interchange.h',
    'include/hmath_interchange_error.h',
    'include/hmath_linear.h',
    'include/hmath_machinelearning.h',
    'include/hmath_matrix.h',
    'include/hmath_matrix_value.h',
    'include/hmath_numeric.h',
    'include/hmath_numeric_objects.h',
    'include/hmath_numeric_types.h',
    'include/hmath_numerical.h',
    'include/hmath_optimization.h',
    'include/hmath_optimization_all.h',
    'include/hmath_polynomial.h',
    'include/hmath_rotations.h',
    'include/hmath_scalar_extras.h',
    'include/hmath_shape.h',
    'include/hmath_spectral.h',
    'include/hmath_stochastic.h',
    'include/hmath_tensor_bindings.h',
    'include/hmath_timeseries.h',
    'include/hmath_units.h',
    'include/hmath_value.h',
    'src/HMath.hs',
    'src/HMath/API.hs',
    'src/HMath/API/Algebra.hs',
    'src/HMath/API/Buffer.hs',
    'src/HMath/API/Convergence.hs',
    'src/HMath/API/Shape.hs',
    'src/HMath/Algebra.hs',
    'src/HMath/Algorithms.hs',
    'src/HMath/Autodiff.hs',
    'src/HMath/Backend.hs',
    'src/HMath/Basic.hs',
    'src/HMath/Calculus.hs',
    'src/HMath/Combinatorics.hs',
    'src/HMath/Complex.hs',
    'src/HMath/Constants.hs',
    'src/HMath/DataStructure.hs',
    'src/HMath/DeepLearning.hs',
    'src/HMath/DeepLearning/Core.hs',
    'src/HMath/DeepLearning/Layers.hs',
    'src/HMath/DeepLearning/Metrics.hs',
    'src/HMath/DeepLearning/Precision.hs',
    'src/HMath/Discrete.hs',
    'src/HMath/Error.hs',
    'src/HMath/Expression.hs',
    'src/HMath/FFI.hs',
    'src/HMath/FFI/AlgebraAll.hs',
    'src/HMath/FFI/AlgebraCodec.hs',
    'src/HMath/FFI/Autodiff.hs',
    'src/HMath/FFI/AutodiffChecked.hs',
    'src/HMath/FFI/AutodiffValue.hs',
    'src/HMath/FFI/Boundary.hs',
    'src/HMath/FFI/Buffer.hs',
    'src/HMath/FFI/Buffer/Codec.hs',
    'src/HMath/FFI/Bytes.hs',
    'src/HMath/FFI/Coefficient.hs',
    'src/HMath/FFI/DeepLearning.hs',
    'src/HMath/FFI/Execution.hs',
    'src/HMath/FFI/Expression.hs',
    'src/HMath/FFI/Foundation.hs',
    'src/HMath/FFI/FoundationCodec.hs',
    'src/HMath/FFI/Geometry.hs',
    'src/HMath/FFI/Graph.hs',
    'src/HMath/FFI/GraphCodec.hs',
    'src/HMath/FFI/Image.hs',
    'src/HMath/FFI/InterchangeAll.hs',
    'src/HMath/FFI/InterchangeCodec.hs',
    'src/HMath/FFI/InterchangeElement.hs',
    'src/HMath/FFI/InterchangeError.hs',
    'src/HMath/FFI/LinearAll.hs',
    'src/HMath/FFI/LinearCodec.hs',
    'src/HMath/FFI/MachineLearning.hs',
    'src/HMath/FFI/MachineLearning/Codec.hs',
    'src/HMath/FFI/MachineLearning/Types.hs',
    'src/HMath/FFI/MathError.hs',
    'src/HMath/FFI/Matrix.hs',
    'src/HMath/FFI/MatrixValue.hs',
    'src/HMath/FFI/Numeric.hs',
    'src/HMath/FFI/NumericObjects.hs',
    'src/HMath/FFI/NumericTypes.hs',
    'src/HMath/FFI/NumericTypes/Core.hs',
    'src/HMath/FFI/NumericalAll.hs',
    'src/HMath/FFI/NumericalCodec.hs',
    'src/HMath/FFI/OptimizationAll.hs',
    'src/HMath/FFI/Optimizer.hs',
    'src/HMath/FFI/Ordering.hs',
    'src/HMath/FFI/Polynomial.hs',
    'src/HMath/FFI/RandomCodec.hs',
    'src/HMath/FFI/Rotations.hs',
    'src/HMath/FFI/ScalarExtras.hs',
    'src/HMath/FFI/ShapeAll.hs',
    'src/HMath/FFI/ShapeCodec.hs',
    'src/HMath/FFI/SpectralAll.hs',
    'src/HMath/FFI/Stochastic.hs',
    'src/HMath/FFI/TensorAll.hs',
    'src/HMath/FFI/TensorCodec.hs',
    'src/HMath/FFI/TimeSeries.hs',
    'src/HMath/FFI/Units.hs',
    'src/HMath/FFI/Value.hs',
    'src/HMath/Fourier.hs',
    'src/HMath/Geometry.hs',
    'src/HMath/Geometry/Collision.hs',
    'src/HMath/Geometry/Internal.hs',
    'src/HMath/Geometry/Polygon.hs',
    'src/HMath/Geometry/Primitives.hs',
    'src/HMath/Geometry/Spatial.hs',
    'src/HMath/Geometry/Transform.hs',
    'src/HMath/Geometry/Triangulation.hs',
    'src/HMath/Graph.hs',
    'src/HMath/Graph/Analysis.hs',
    'src/HMath/Graph/Core.hs',
    'src/HMath/Graph/Flow.hs',
    'src/HMath/Graph/Paths.hs',
    'src/HMath/Image.hs',
    'src/HMath/Image/Color.hs',
    'src/HMath/Image/Core.hs',
    'src/HMath/Image/Filter.hs',
    'src/HMath/Image/Histogram.hs',
    'src/HMath/Image/Measure.hs',
    'src/HMath/Image/Spatial.hs',
    'src/HMath/Interchange.hs',
    'src/HMath/Interchange/Array.hs',
    'src/HMath/Interchange/Binary.hs',
    'src/HMath/Interchange/Compression.hs',
    'src/HMath/Interchange/IO.hs',
    'src/HMath/Interchange/Numpy.hs',
    'src/HMath/Interchange/Text.hs',
    'src/HMath/Interpolation.hs',
    'src/HMath/Linear.hs',
    'src/HMath/MachineLearning.hs',
    'src/HMath/MachineLearning/Clustering.hs',
    'src/HMath/MachineLearning/Decomposition.hs',
    'src/HMath/MachineLearning/Internal.hs',
    'src/HMath/MachineLearning/Neighbors.hs',
    'src/HMath/MachineLearning/Preprocessing.hs',
    'src/HMath/MachineLearning/Regression.hs',
    'src/HMath/Matrix.hs',
    'src/HMath/Matrix/Advanced.hs',
    'src/HMath/Matrix/Decomposition.hs',
    'src/HMath/Matrix/Internal.hs',
    'src/HMath/Matrix/Iterative.hs',
    'src/HMath/Matrix/LAPACK.hs',
    'src/HMath/Matrix/LU.hs',
    'src/HMath/Matrix/QR.hs',
    'src/HMath/NumberTheory.hs',
    'src/HMath/Numeric.hs',
    'src/HMath/ODE.hs',
    'src/HMath/ODE/Tableau.hs',
    'src/HMath/Optimization.hs',
    'src/HMath/Optimization/Common.hs',
    'src/HMath/Optimization/Constrained.hs',
    'src/HMath/Optimization/FirstOrder.hs',
    'src/HMath/Optimization/Global.hs',
    'src/HMath/Optimization/Local.hs',
    'src/HMath/PDE.hs',
    'src/HMath/Polynomial.hs',
    'src/HMath/Probability.hs',
    'src/HMath/Quaternion.hs',
    'src/HMath/Random.hs',
    'src/HMath/Root.hs',
    'src/HMath/Rotation.hs',
    'src/HMath/Scalar.hs',
    'src/HMath/Signal.hs',
    'src/HMath/Signal/Internal.hs',
    'src/HMath/Sparse.hs',
    'src/HMath/Sparse/Spectral.hs',
    'src/HMath/Special.hs',
    'src/HMath/Statistics.hs',
    'src/HMath/Statistics/Advanced.hs',
    'src/HMath/Symbolic.hs',
    'src/HMath/Tensor.hs',
    'src/HMath/Tensor/Mutable.hs',
    'src/HMath/TimeSeries.hs',
    'src/HMath/TimeSeries/Core.hs',
    'src/HMath/TimeSeries/Diagnostics.hs',
    'src/HMath/TimeSeries/Models.hs',
    'src/HMath/Trigonometry.hs',
    'src/HMath/Units.hs',
    'src/HMath/Vector.hs',

)

# The ABI epoch is independent of the package release version.
if host_machine.system() == 'windows'
    library_names = ['hmath.dll']
elif host_machine.system() == 'darwin'
    library_names = ['libhmath.dylib']
else
    library_names = ['libhmath.so', 'libhmath.so.1']
endif
hmath = custom_target('hmath', output: library_names, input: hmath_sources,
    command: [python, files('meson-build.py'), meson.current_source_dir(), '@OUTPUT@'] + build_args,
    build_by_default: true, console: true, install: true,
    install_dir: get_option('libdir'), install_tag: 'runtime')
hmath_library = hmath[0]
install_headers('include/hmath.h', 'include/hmath_algebra.h', 'include/hmath_autodiff.h', 'include/hmath_buffer.h', 'include/hmath_bytes.h', 'include/hmath_callback.h', 'include/hmath_deeplearning.h', 'include/hmath_dlpack.h', 'include/hmath_error.h', 'include/hmath_execution.h', 'include/hmath_expression.h', 'include/hmath_expression_error.h', 'include/hmath_foundation.h', 'include/hmath_geometry.h', 'include/hmath_graph.h', 'include/hmath_image.h', 'include/hmath_interchange.h', 'include/hmath_interchange_error.h', 'include/hmath_linear.h', 'include/hmath_machinelearning.h', 'include/hmath_matrix.h', 'include/hmath_matrix_value.h', 'include/hmath_numeric.h', 'include/hmath_numeric_objects.h', 'include/hmath_numeric_types.h', 'include/hmath_numerical.h', 'include/hmath_optimization.h', 'include/hmath_optimization_all.h', 'include/hmath_polynomial.h', 'include/hmath_rotations.h', 'include/hmath_scalar_extras.h', 'include/hmath_shape.h', 'include/hmath_spectral.h', 'include/hmath_stochastic.h', 'include/hmath_tensor_bindings.h', 'include/hmath_timeseries.h', 'include/hmath_units.h', 'include/hmath_value.h')
install_data('LICENSE', install_dir: get_option('datadir') / 'licenses/hmath')
hmath_dep = declare_dependency(link_with: hmath_library, include_directories: include_directories('include'))
meson.override_dependency('hmath', hmath_dep)
if get_option('benchmarks')
    executable('hmath-native-benchmark', 'bench/native.c', dependencies: hmath_dep,
               build_rpath: meson.current_build_dir())
endif

# Relative package metadata continues to work after DESTDIR staging or relocation.
metadata = configuration_data()
metadata.set('VERSION', meson.project_version())
metadata.set('LIBDIR', fs.relative_to(get_option('prefix') / get_option('libdir'), get_option('prefix')))
metadata.set('INCLUDEDIR', fs.relative_to(get_option('prefix') / get_option('includedir'), get_option('prefix')))
metadata.set('LIBRARY', library_names[0])
pc_dir = get_option('libdir') / 'pkgconfig'
cmake_dir = get_option('libdir') / 'cmake/HMath'
metadata.set('PC_PREFIX_RELATIVE', fs.relative_to(get_option('prefix'), get_option('prefix') / pc_dir))
metadata.set('CMAKE_PREFIX_RELATIVE', fs.relative_to(get_option('prefix'), get_option('prefix') / cmake_dir))
configure_file(input: 'meson/hmath.pc.in', output: 'hmath.pc', configuration: metadata,
               install: true, install_dir: pc_dir)
configure_file(input: 'meson/cmake/HMathConfig.cmake.in', output: 'HMathConfig.cmake',
               configuration: metadata, install: true, install_dir: cmake_dir)
configure_file(input: 'meson/cmake/HMathConfigVersion.cmake.in', output: 'HMathConfigVersion.cmake',
               configuration: metadata, install: true, install_dir: cmake_dir)

if get_option('tests')
    if get_option('haskell_tests')
        test('hmath-haskell', python,
             args: [files('meson-build.py'), meson.current_source_dir(), '--test'] + build_args,
             depends: hmath, is_parallel: false, timeout: 900)
    endif
    hmath_c_test = executable('hmath-c-test', 'examples/c/main.c',
        dependencies: hmath_dep, build_rpath: meson.current_build_dir())
    test('hmath-c-ffi', hmath_c_test)
    header_test = executable('hmath-c99-header', 'test/native/header_c99.c',
        dependencies: hmath_dep, override_options: ['c_std=c99'],
        build_rpath: meson.current_build_dir())
    test('hmath-c99-header', header_test)
    numeric_contracts = executable('hmath-numeric-contracts', 'test/native/numeric_contracts.c',
        dependencies: hmath_dep, override_options: ['c_std=c99'],
        build_rpath: meson.current_build_dir())
    test('hmath-numeric-contracts', numeric_contracts)
    matrix_contracts = executable('hmath-matrix-contracts', 'test/native/matrix_contracts.c',
        dependencies: hmath_dep, override_options: ['c_std=c99'],
        build_rpath: meson.current_build_dir())
    test('hmath-matrix-contracts', matrix_contracts)
    ad_contracts = executable('hmath-autodiff-contracts', 'test/native/autodiff_contracts.c',
        dependencies: hmath_dep, override_options: ['c_std=c99'],
        build_rpath: meson.current_build_dir())
    test('hmath-autodiff-contracts', ad_contracts)
    storage_contracts = executable('hmath-kernel-storage',
        ['test/native/kernel_storage.c', 'cbits/native.c', 'cbits/error_wire.c'],
        dependencies: dependency('threads'),
        include_directories: include_directories('include', 'cbits'))
    test('hmath-kernel-storage', storage_contracts)

    if add_languages('cpp', required: false)
        numeric_cpp = executable('hmath-numeric-cpp', 'test/native/numeric_contracts.cpp',
            dependencies: hmath_dep, override_options: ['cpp_std=c++17'],
            build_rpath: meson.current_build_dir())
        test('hmath-numeric-cpp', numeric_cpp)
        foreach contract : ['tensor_contracts', 'deeplearning_contracts', 'autodiff_checked_contracts', 'foundation_contracts', 'interchange_contracts']
            cpp_client = executable('hmath-' + contract + '-cpp', 'test/native/' + contract + '.cpp',
                dependencies: hmath_dep, override_options: ['cpp_std=c++17'],
                build_rpath: meson.current_build_dir())
            test('hmath-' + contract + '-cpp', cpp_client)
        endforeach
    endif
    test('hmath-generated-bindings', python,
        args: [files('tools/generate_numeric_bindings.py'), '--check'])
    foreach domain : ['graph', 'matrix', 'matrix_value', 'polynomial', 'units', 'optimization', 'timeseries', 'rotation', 'image', 'expression', 'linear', 'numerical', 'geometry', 'stochastic', 'spectral', 'foundation', 'algebra', 'shape', 'tensor', 'deeplearning', 'machinelearning', 'interchange']
        test('hmath-generated-' + domain, python,
            args: [files('tools/generate_' + domain + '_bindings.py'), '--check'])
    endforeach
    foreach domain : ['matrix_value', 'polynomial', 'numeric_types', 'graph', 'optimization', 'units', 'rotation', 'timeseries', 'image', 'expression', 'linear', 'geometry', 'stochastic', 'numerical', 'spectral', 'structural_matrix', 'foundation', 'algebra', 'shape', 'machinelearning', 'tensor', 'deeplearning']
        test('hmath-' + domain + '-equivalence', python,
            args: [files('tools/check_' + domain + '_equivalence.py'), '--library', hmath_library.full_path()],
            depends: hmath, timeout: 300)
    endforeach
    test('hmath-interchange-bindings-equivalence', python,
        args: [files('tools/check_interchange_bindings_equivalence.py'), '--library', hmath_library.full_path()],
        depends: hmath, timeout: 300)
    foreach domain : ['value', 'polynomial', 'optimization', 'units', 'expression', 'linear', 'stochastic', 'numerical', 'spectral', 'foundation', 'tensor', 'deeplearning', 'interchange']
        test('hmath-' + domain + '-python', python,
            args: [files('test/native/' + domain + '_bindings.py')],
            env: {'HMATH_LIBRARY': hmath_library.full_path(), 'PYTHONPATH': meson.current_source_dir() / 'bindings/python'}, depends: hmath)
    endforeach
    foreach contract : ['numeric_variants', 'polynomial_contracts', 'execution_smoke', 'numeric_types', 'rotations', 'optimization_contracts', 'structured_contracts', 'image', 'expression_contracts', 'geometry', 'stochastic_contracts', 'linear_contracts', 'foundation_contracts', 'structural_matrix_contracts', 'machinelearning', 'tensor_contracts', 'deeplearning_contracts', 'autodiff_checked_contracts', 'spectral_contracts', 'scalar_extras', 'interchange_contracts']
        client = executable('hmath-' + contract, 'test/native/' + contract + '.c',
            dependencies: hmath_dep, override_options: ['c_std=c99'],
            build_rpath: meson.current_build_dir())
        test('hmath-' + contract, client)
    endforeach
    test('hmath-callback-errors', python,
        args: [files('test/native/callback_errors.py')],
        env: {'HMATH_LIBRARY': hmath_library.full_path(), 'PYTHONPATH': meson.current_source_dir() / 'bindings/python'}, depends: hmath)
    test('hmath-release-candidate', python, args: [files('test/release_candidate.py')])
    test('hmath-release-publishing', python, args: [files('test/release_publishing.py')])
    test('hmath-scalar-extras', python, args: [files('tools/check_scalar_extras.py'), '--library', hmath_library.full_path()], depends: hmath, timeout: 300)
    test('hmath-generated-scalar-extras', python, args: [files('tools/generate_scalar_extras.py'), '--check'])
    test('hmath-generated-numeric-types', python, args: [files('tools/generate_numeric_types.py'), '--check'])
    test('hmath-generated-numeric-objects', python,
        args: [files('tools/generate_numeric_objects.py'), '--check'])
    test('hmath-numeric-objects-equivalence', python,
        args: [files('tools/check_numeric_objects_equivalence.py'), '--library', hmath_library.full_path()],
        depends: hmath, timeout: 300)
    test('hmath-numeric-equality-equivalence', python,
        args: [files('tools/check_numeric_equality.py'), '--library', hmath_library.full_path()],
        depends: hmath, timeout: 300)
    numeric_objects_client = executable('hmath-numeric-objects-contracts', 'test/native/numeric_objects_contracts.c',
        dependencies: hmath_dep, override_options: ['c_std=c99'],
        build_rpath: meson.current_build_dir())
    test('hmath-numeric-objects-contracts', numeric_objects_client)
    if add_languages('cpp', required: false)
        numeric_objects_cpp = executable('hmath-numeric-objects-contracts-cpp', 'test/native/numeric_objects_contracts.cpp',
            dependencies: hmath_dep, override_options: ['cpp_std=c++17'],
            build_rpath: meson.current_build_dir())
        test('hmath-numeric-objects-contracts-cpp', numeric_objects_cpp)
    endif

    test('hmath-generated-buffer', python,
        args: [files('tools/generate_buffer_bindings.py'), '--check'])
    test('hmath-buffer-equivalence', python,
        args: [files('tools/check_buffer_equivalence.py'), '--library', hmath_library.full_path()],
        depends: hmath, timeout: 300)
    buffer_client = executable('hmath-buffer-contracts', 'test/native/buffer_contracts.c',
        dependencies: hmath_dep, override_options: ['c_std=c99'],
        build_rpath: meson.current_build_dir())
    test('hmath-buffer-contracts', buffer_client)
    if add_languages('cpp', required: false)
        buffer_cpp = executable('hmath-buffer-contracts-cpp', 'test/native/buffer_contracts.cpp',
            dependencies: hmath_dep, override_options: ['cpp_std=c++17'],
            build_rpath: meson.current_build_dir())
        test('hmath-buffer-contracts-cpp', buffer_cpp)
    endif

    test('hmath-binding-coverage', python,
        args: [files('tools/check_binding_coverage.py')])
    test('hmath-expanded-python', python,
        args: [files('test/native/expanded_bindings.py')],
        env: {'HMATH_LIBRARY': hmath_library.full_path()}, depends: hmath)
    oracle_optimization = '2'
    if buildtype == 'debug'
        oracle_optimization = '0'
    elif buildtype == 'minsize'
        oracle_optimization = '1'
    endif
    test('hmath-numeric-equivalence', python,
        args: [files('tools/check_numeric_equivalence.py'), '--library', hmath_library.full_path(), '--oracle-builddir', meson.current_build_dir() / 'numeric-oracle', '--optimization', oracle_optimization],
        depends: hmath, timeout: 300)
    test('hmath-matrix-equivalence', python,
        args: [files('tools/check_matrix_equivalence.py'), '--library', hmath_library.full_path()],
        depends: hmath, timeout: 300)
    test('hmath-autodiff-equivalence', python,
        args: [files('tools/check_autodiff_equivalence.py'), '--library', hmath_library.full_path()],
        depends: hmath, timeout: 300)
    test('hmath-autodiff-coefficients', python,
        args: [files('tools/check_autodiff_coefficients.py'), '--library', hmath_library.full_path()],
        depends: hmath, timeout: 300)
    test('hmath-autodiff-python', python,
        args: [files('test/native/autodiff_bindings.py')],
        env: {'HMATH_LIBRARY': hmath_library.full_path()}, depends: hmath)


    if host_machine.system() != 'windows'
        contract_test = executable('hmath-native-contracts', 'test/native/contracts.c',
            dependencies: [hmath_dep, dependency('threads')],
            build_rpath: meson.current_build_dir())
        test('hmath-native-contracts', contract_test)
    endif
    test('hmath-python-ffi', python, args: [files('examples/python/main.py')],
         env: {'HMATH_LIBRARY': hmath_library.full_path()}, depends: hmath)
    test('hmath-python-ffi-optimized', python, args: ['-O', files('examples/python/main.py')],
         env: {'HMATH_LIBRARY': hmath_library.full_path()}, depends: hmath)
    if not get_option('python_bindings').disabled()
        python_modules = run_command(python, '-c', 'import numpy, cffi', check: false)
        if python_modules.returncode() == 0
            if get_option('native_backend') and host_machine.system() == 'linux'
                test('hmath-execution', python,
                    args: [files('tools/check_execution.py'), '--library', hmath_library.full_path()],
                    depends: hmath, timeout: 180)
            endif
            test('hmath-python-bindings', python, args: [files('bindings/python/test_bindings.py')],
                 env: {'HMATH_LIBRARY': hmath_library.full_path()}, depends: hmath)
            test('hmath-numpy-dlpack', python, args: [files('test/native/dlpack_numpy.py')],
                 env: {'HMATH_LIBRARY': hmath_library.full_path()}, depends: hmath)
            test('hmath-python-abi-rejection', python,
                 args: [files('test/native/abi_rejection.py')])
        elif get_option('python_bindings').enabled()
            error('Python binding tests require NumPy and cffi in the selected Python installation.')
        endif
    endif
    wavec = find_program('wavec', required: get_option('wave_bindings'))
    if wavec.found()
        test('hmath-wave-bindings', python,
             args: [files('tools/run_wave.py'), '--library', hmath_library.full_path(),
                    '--compiler', wavec.full_path()], depends: hmath, timeout: 120)
    endif
    test('hmath-ffi-lifecycle', python,
         args: [files('test/ffi_lifecycle.py'), hmath_library.full_path()], depends: hmath, timeout: 45)
    foreach fault : [['addition', 1, 'addition: expected'], ['factorial', 2, 'factorial(10): expected'],
                     ['mean', 3, 'mean: expected'], ['dot', 4, 'dot: expected']]
        bad_library = shared_library('hmath-bad-' + fault[0], 'test/ffi_bad_results.c',
            include_directories: include_directories('include'),
            c_args: ['-DHMATH_TEST_FAULT=' + fault[1].to_string()])
        bad_client = executable('hmath-c-bad-' + fault[0], 'examples/c/main.c',
            include_directories: include_directories('include'), link_with: bad_library)
        test('hmath-ffi-reject-' + fault[0], python,
            args: [files('test/ffi_failure_detection.py'), '--c-client', bad_client.full_path(),
                   '--python-example', files('examples/python/main.py'), '--library', bad_library.full_path(),
                   '--diagnostic', fault[2]], depends: [bad_client, bad_library], timeout: 20)
    endforeach
endif
summary({'Build configuration': buildtype, 'Compression': compression,
         'Cabal directory': cabal_builddir, 'Native ABI epoch': '1',
         'GPU': 'unavailable', 'Static foreign library': 'unavailable'}, section: 'HMath')
