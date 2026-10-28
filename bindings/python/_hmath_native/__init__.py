# SPDX-License-Identifier: MPL-2.0
"""Locate the wheel's native library, or an explicit developer override."""

import ctypes.util
import os
from pathlib import Path


def library_path():
    override = os.environ.get("HMATH_LIBRARY")
    if override:
        return override
    bundled = Path(__file__).with_name("libhmath.so")
    if bundled.is_file():
        return str(bundled)
    # Source checkouts can use a separately built and installed C library.
    installed = ctypes.util.find_library("hmath")
    if installed:
        return installed
    raise ImportError(
        "HMath's native library is missing. Install a supported hmath-python "
        "binary wheel, or build the library when developing from source."
    )
