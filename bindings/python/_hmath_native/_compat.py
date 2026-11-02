# SPDX-License-Identifier: MPL-2.0
"""Small compatibility helpers for the supported Python 3.9 baseline."""

from itertools import zip_longest


def zip_equal(*iterables):
    """Zip equal-length inputs, rejecting an unmatched tail on Python 3.9+."""
    missing = object()
    for values in zip_longest(*iterables, fillvalue=missing):
        if any(value is missing for value in values):
            raise ValueError("zip arguments have different lengths")
        yield values
