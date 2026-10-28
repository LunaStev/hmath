# SPDX-License-Identifier: MPL-2.0

"""Exercise the real GHC runtime in a fresh process for every lifecycle case."""

import argparse
import ctypes
import signal
import subprocess
import sys
import threading
from pathlib import Path

# These are the public enum hmath_init_result values from include/hmath.h.
HMATH_INIT_OK = 0
HMATH_INIT_ALREADY_SHUT_DOWN = 1
CHILD_TIMEOUT_SECONDS = 5


def expect_equal(actual, expected, description):
    if actual != expected:
        raise AssertionError(f"{description}: expected {expected!r}, got {actual!r}")


def load_library(path):
    # CDLL releases the GIL during calls, so the thread cases reach C concurrently.
    library = ctypes.CDLL(str(path))
    library.hmath_init.argtypes = []
    library.hmath_init.restype = ctypes.c_int
    library.hmath_shutdown.argtypes = []
    library.hmath_shutdown.restype = None
    library.hmath_add_f64.argtypes = [ctypes.c_double, ctypes.c_double]
    library.hmath_add_f64.restype = ctypes.c_double
    return library


def expect_running(library):
    expect_equal(library.hmath_add_f64(1.25, 2.5), 3.75, "numeric call after init")


def expect_terminal(library):
    # Reaching the assertion also proves that init did not terminate the host.
    expect_equal(
        library.hmath_init(),
        HMATH_INIT_ALREADY_SHUT_DOWN,
        "init after final shutdown",
    )


def parallel_calls(calls):
    barrier = threading.Barrier(len(calls))
    results = [None] * len(calls)
    errors = [None] * len(calls)

    def worker(index, call):
        try:
            barrier.wait(timeout=2)
            results[index] = call()
        # Propagate any worker failure to the main test thread.
        except Exception as error:  # noqa: BLE001
            errors[index] = repr(error)

    threads = [
        threading.Thread(target=worker, args=(index, call), daemon=True)
        for index, call in enumerate(calls)
    ]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()
    if any(error is not None for error in errors):
        raise AssertionError(f"concurrent lifecycle calls failed: {errors!r}")
    return results


def normal(library):
    expect_equal(library.hmath_init(), HMATH_INIT_OK, "initial init")
    expect_running(library)
    library.hmath_shutdown()
    expect_terminal(library)


def shutdown_before_init(library):
    library.hmath_shutdown()
    library.hmath_shutdown()
    expect_equal(library.hmath_init(), HMATH_INIT_OK, "init after unused shutdown")
    expect_running(library)
    library.hmath_shutdown()
    expect_terminal(library)


def duplicate_calls(library):
    expect_equal(library.hmath_init(), HMATH_INIT_OK, "initial init")
    expect_equal(library.hmath_init(), HMATH_INIT_OK, "duplicate init")
    expect_running(library)
    library.hmath_shutdown()
    # Init is not a reference count: one shutdown ends both successful init calls.
    expect_terminal(library)
    library.hmath_shutdown()
    expect_terminal(library)


def concurrent_init(library):
    results = parallel_calls([library.hmath_init] * 8)
    expect_equal(results, [HMATH_INIT_OK] * 8, "concurrent init results")
    expect_running(library)
    library.hmath_shutdown()
    expect_terminal(library)


def concurrent_shutdown(library):
    expect_equal(library.hmath_init(), HMATH_INIT_OK, "initial init")
    expect_running(library)
    # Numeric work is finished before any shutdown thread starts.
    parallel_calls([library.hmath_shutdown] * 8)
    expect_terminal(library)


def mixed_final_transition(library):
    expect_equal(library.hmath_init(), HMATH_INIT_OK, "initial init")
    calls = [library.hmath_init, library.hmath_shutdown] * 8
    results = parallel_calls(calls)
    # Init may run before or after the one final shutdown. There is deliberately
    # no numeric work during or after this race; successful init cannot pin RTS.
    for result in results[::2]:
        if result not in (HMATH_INIT_OK, HMATH_INIT_ALREADY_SHUT_DOWN):
            raise AssertionError(f"unexpected racing init result: {result!r}")
    expect_terminal(library)
    library.hmath_shutdown()


SCENARIOS = {
    "normal": normal,
    "shutdown-before-init": shutdown_before_init,
    "duplicate-calls": duplicate_calls,
    "concurrent-init": concurrent_init,
    "concurrent-shutdown": concurrent_shutdown,
    "mixed-final-transition": mixed_final_transition,
}


def run_isolated(library_path):
    failures = 0
    for name in SCENARIOS:
        command = [
            sys.executable,
            str(Path(__file__).resolve()),
            str(library_path),
            "--scenario",
            name,
        ]
        try:
            completed = subprocess.run(
                command,
                capture_output=True,
                text=True,
                errors="replace",
                timeout=CHILD_TIMEOUT_SECONDS,
                check=False,
            )
        except subprocess.TimeoutExpired:
            print(f"FAIL {name}: child exceeded {CHILD_TIMEOUT_SECONDS}s", flush=True)
            failures += 1
            continue
        if completed.returncode == 0:
            print(f"PASS {name}", flush=True)
            continue
        failures += 1
        if completed.returncode < 0:
            status = f"signal {signal.Signals(-completed.returncode).name}"
        else:
            status = f"exit status {completed.returncode}"
        print(f"FAIL {name}: child terminated with {status}", flush=True)
        for output in (completed.stdout, completed.stderr):
            if output:
                print(output.rstrip(), flush=True)
    return 1 if failures else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("library", type=Path, help="path to the built HMath library")
    parser.add_argument("--scenario", choices=SCENARIOS, help=argparse.SUPPRESS)
    arguments = parser.parse_args()
    library_path = arguments.library.resolve(strict=True)
    if arguments.scenario is not None:
        SCENARIOS[arguments.scenario](load_library(library_path))
        return 0
    return run_isolated(library_path)


if __name__ == "__main__":
    sys.exit(main())
