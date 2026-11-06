# Testing cl-raygui

From the project directory, with SBCL, Quicklisp, cl-raylib, CMake, a C compiler,
and shared raylib development files installed:

```sh
python3 tools/run-tests.py
```

This builds the production library and native test libraries, then runs three
isolated Lisp processes:

1. **Headless and ABI checks:** the existing library/memory tests and the C
   compiler's actual struct layouts and calling conventions. The runner requires
   the ABI probe rather than silently skipping it. It also verifies that the
   headless suite restores style, state, locking, and retained tooltips after
   both success and failure.
2. **Interaction checks:** 76 assertions in 14 scenarios exercise buttons,
   checkboxes, toggles, disabled/locked controls, dropdowns, slider dragging,
   UTF-8 typing and deletion, buffer capacity, integer/float editing, lists,
   scrolling, HSV/alpha controls, tabs, confirmation dialogs, and text dialogs.
3. **Example checks:** load and compile all ten top-level examples without
   opening windows.

Interaction tests compile the unmodified `vendor/raygui.h` into a separate test
library. Its documented `GUI_*` hooks provide scripted per-frame input. Drawing
calls go to a sink, and a fixed test font supplies glyph metrics. The controls,
their state machines, the public Lisp wrappers, and raylib's CPU-side UTF-8,
color, glyph lookup, and collision functions execute normally. This catches
incorrect flags, changed values, argument/return order, and buffer updates
without desktop access. It does **not** check pixel output or OS input delivery.

The interaction library is loaded instead of production raygui in its own
process, before any bindings load. Do not load it alongside the production
library in an existing REPL: both export the same C function names.

To also exercise real window creation and rendering:

```sh
python3 tools/run-tests.py --graphics
```

This adds the existing hidden-window graphics smoke test and executes each
example in a fresh process for three actual drawing frames. Only its loop-exit
function is replaced to bound execution; rendering and controls use the real
libraries. Each process has a timeout and any failure makes the runner exit
nonzero. These checks detect startup/drawing failures; they do not assert
screenshots or click through every example's application logic.

On Linux, a virtual display and software OpenGL can run the graphical checks:

```sh
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a python3 tools/run-tests.py --graphics
```

On macOS, use Terminal in a logged-in desktop session, on the main thread.
An unavailable window service can stall initialization; the runner reports a
timeout as a failure. Without `--graphics`, the omitted graphics checks are
explicitly reported as skipped.

Useful options:

```sh
python3 tools/run-tests.py --no-build
python3 tools/run-tests.py --quicklisp-setup ~/.quicklisp/setup.lisp
python3 tools/run-tests.py --build-dir /path/to/test-build --timeout 180
```

`CMAKE_PREFIX_PATH` can select the raylib installation. `--sbcl` selects an
SBCL executable. Build outputs, Lisp caches, and compiled example files remain
inside the build directory (example FASLs use the project's `build/` directory).

The [CI workflow](../.github/workflows/tests.yml) configures SBCL jobs for Linux,
macOS, and Windows with raylib 6.0. Linux additionally requests real rendering
and all example smoke runs under Xvfb. macOS and Windows run the headless,
ABI, interaction, isolation, and example compilation suites.

For REPL use, the original command still works:

```lisp
(ql:quickload :cl-raygui/tests)
(asdf:test-system :cl-raygui)
```

It reports an absent optional ABI probe explicitly. Set
`CL_RAYGUI_REQUIRE_NATIVE_TESTS=1` to turn that skip into an error, or use the
Python runner, which always requires both native test libraries.
