# HMath

Mathematics and numerical computing in Haskell, with a native C ABI.

## Build and test

Requires GHC, Cabal, a C11 compiler, Meson >= 0.63, Ninja, and Python 3.

```sh
meson setup builddir
meson compile -C builddir
meson test -C builddir
```

[MPL-2.0](LICENSE) · [Roadmap](ROADMAP.md)
