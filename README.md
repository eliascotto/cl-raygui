# cl-raygui

Common Lisp bindings for [raygui 5.0](https://github.com/raysan5/raygui/tree/5.0),
built to work with [cl-raylib](https://github.com/longlene/cl-raylib).
Provides Lisp-friendly controls, editable text buffers, and access to the raw C API.

## Quick start

### Installation

Install a Common Lisp implementation, Quicklisp, a C99 compiler, CMake, and
**shared raylib 6.0 or newer** with development headers and CMake configuration.
For Homebrew, see [macOS](#macos) below.

Install cl-raylib in Quicklisp's `local-projects` directory (adjust the path
to match your Quicklisp installation), or register it with ASDF:

```sh
git clone https://github.com/longlene/cl-raylib.git ~/quicklisp/local-projects/cl-raylib
```

From this project directory, build the native raygui library:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

If CMake cannot find raylib, add `-DCMAKE_PREFIX_PATH=/path/to/raylib/prefix`.
cl-raylib and raygui must use the same raylib installation. The build has been
verified on macOS ARM64; Linux and Windows remain unverified locally.

### macOS

Install Apple's command-line tools if needed (`xcode-select --install`).
With Quicklisp and cl-raylib installed as above, use the Homebrew build shortcut:

```sh
brew install sbcl raylib pkgconf
bash tools/build-macos.sh
```

This produces `build/libraygui.dylib` without requiring CMake. Run graphical
examples from Terminal in your logged-in desktop session, on the main thread.

### Run an example

```sh
sbcl --load examples/basic.lisp
```

Initialize a raylib window before using controls, fonts, or drawing functions.
Raygui has global state; keep calls and control buffers on the drawing thread.

### Load in a REPL

In a Lisp session with Quicklisp loaded:

```lisp
(require :asdf)
;; Optional if cl-raygui is already on the ASDF source registry:
(asdf:load-asd #P"/absolute/path/to/cl-raygui/cl-raygui.asd")
(ql:quickload :cl-raygui)
```

### Library discovery and compatibility

The loader searches `build/` (including CMake's Release/Debug directories),
then system library paths. Set `CL_RAYGUI_LIBRARY` to an absolute path to select
an existing **raygui 5.0** library. Raygui 4.x has incompatible signatures.
Use `cffi:*foreign-library-directories*` to help locate raylib itself.

## Examples

The [examples guide](examples/README.md) covers controls, numeric input, text
editing, dialogs, lists/tabs, scrolling, colors, styling, and icons/tooltips.

```sh
sbcl --load examples/controls.lisp
```

Run one demo at a time. No external assets are required.

## Lisp API

### Packages and naming

`cl-raygui` (nickname `raygui`) provides Lisp-friendly wrappers;
`cl-raygui.raw` (nickname `raygui.raw`) exposes the C signatures directly.
Names follow cl-raylib's convention: `GuiCheckBox` becomes `gui-check-box`;
constants include `+state-normal+`, `+text-size+`, and `+icon-file-open+`.
The CFFI/libffi bindings cover all 61 public functions and all enum values,
including icons, and share cl-raylib's Rectangle, Color, Font, and vector types.

### Using controls

Bounds are `raylib:make-rectangle` values. Colors accept cl-raylib color
keywords, RGBA lists, or packed values from `raylib:make-rgba`. Vector2/3
values come from `3d-vectors:vec`. Initialize every Rectangle field: cl-raylib
defaults omitted fields to `NIL`.

```lisp
(let ((bounds (raylib:make-rectangle :x 20 :y 20 :width 24 :height 24)))
  (setf checked (raygui:gui-check-box bounds "Enabled" checked)))
```

### Return values

Mutable controls return the updated Lisp value first, followed by integer
`GuiResult` flags. Store the updated value for the next frame. Controls with
multiple state values return them in this order:

| Control | Return values |
| --- | --- |
| Toggle, check box | boolean, result |
| Toggle group/slider, combo/dropdown | active index, result |
| Spinner, value box, slider/bar, progress bar, color bars | numeric value, result |
| Color picker/panel, including HSV variants | color or Vector3, result |
| Grid | mouse-cell Vector2, result |
| Scroll panel | scroll Vector2, view Rectangle, result |
| List view / tab bar | active index, scroll index, result |
| List view ex / tab bar ex | active index, scroll index, focus index, result |
| Message box | button index, result |
| Text box | text string, result |
| Float value box | numeric value, text string, result |
| Text input box | text string, button index, secret-view boolean, result |

`gui-button`, `gui-label-button`, and `gui-window-box` return a boolean click
or close request first, then result flags. `NIL` means no click. Other
nonmutable controls return the raw integer result.

**Common Lisp treats integer zero as true.** Use `result-pressed-p`,
`result-changed-p`, or `result-tab-close-p` when testing result flags.
Message-box button indices follow raygui: `-1` means no selection, `0` is the
window close button, and action buttons start at `1`.

### Arguments and sequences

The Lisp argument order follows the C declaration except for these conveniences:

```lisp
(raygui:gui-list-view-ex bounds '("First" "Second") scroll active focus)
(raygui:gui-tab-bar-ex bounds #("First" "Second") scroll active focus)
(raygui:gui-scroll-panel bounds text content scroll) ; optional previous view
(raygui:gui-grid bounds text spacing subdivisions)  ; optional previous mouse-cell
(raygui:gui-message-box bounds title message buttons) ; optional button index (-1)
(raygui:gui-text-box bounds buffer edit-mode) ; capacity comes from buffer
(raygui:gui-value-box-float bounds label buffer value edit-mode)
(raygui:gui-text-input-box bounds title message buffer buttons
                           -1 nil) ; optional button index and secret-view state
```

The `ex` controls accept a sequence of strings and calculate the C count.
Text lists in other controls use raygui's semicolon separators.
`NIL` text becomes a null pointer where supported by raygui.
The function declarations in [src/bindings.lisp](src/bindings.lisp) are the
complete raw API reference; high-level wrappers are in [src/api.lisp](src/api.lisp).

### Styling

`gui-set-style` accepts signed integers and unsigned 32-bit RGBA literals;
`gui-get-style` returns an unsigned 32-bit value. Use `+default+` for global
properties, for example:

```lisp
(raygui:gui-set-style raygui:+default+ raygui:+text-size+ 20)
(raygui:gui-set-style raygui:+button+ raygui:+base-color-normal+ #x336699ff)
```

### Editable text

Allocate an editable buffer once, outside the drawing loop. Its capacity is
in **UTF-8 bytes**, including the terminating NUL byte. The buffer stays at
the same native address until freed; this also preserves raygui's cursor state.

```lisp
(raygui:with-text-buffer (buffer 128 "Hello")
  ;; Inside your drawing loop:
  (multiple-value-bind (text result)
      (raygui:gui-text-box bounds buffer editing)
    (when (raygui:result-pressed-p result)
      (setf editing (not editing)))
    (format t "~A~%" text))
  (setf (raygui:text-buffer-string buffer) "New text"))
```

`with-text-buffer` always frees storage on exit. Alternatively use
`make-text-buffer` and `free-text-buffer` explicitly. Oversized initial or
replacement strings signal an error without truncation. Embedded NULs and
access through a freed buffer also signal errors. Keep a separate buffer for
each editable control. `gui-value-box-float` needs at least 33 bytes and
accepts at most 32 text bytes, matching the pinned upstream implementation.

### Tooltips

`gui-set-tooltip` retains its own UTF-8 copy because raygui stores the pointer.
Call `(raygui:gui-set-tooltip nil)` to clear and release it.

### Raw API and ownership

`raygui.raw` functions have the original C return values and argument order.
Mutable pointers require explicitly allocated foreign storage; do not pass
an immutable Lisp string as a writable `char *`. C99 booleans use the
one-byte `cl-raygui.raw::c-bool` type. Text inputs accept Lisp strings, `NIL`,
or foreign pointers; `gui-set-tooltip` takes a persistent foreign pointer.

Functions not adapted by the Lisp API are re-exported unchanged. In
particular, `gui-load-style-from-memory`, `gui-load-icons-from-memory`, and
the icon-loading functions retain their C pointer/count interfaces.
`gui-get-icons` returns borrowed global storage; do not free it. Fonts from
`gui-get-font` borrow raygui/raylib resources. Icon name arrays returned when
loading with names enabled are caller-owned; free each name and then the
array with raylib's `mem-free` (for the pinned build, the icon array has
`RAYGUI_ICON_MAX_ICONS`, 512 entries). Prefer disabling name loading if you
only need to install icons. Use upstream raygui documentation for style/font
resource ownership. `gui-icon-text` copies its borrowed result into a Lisp string.

## Tests

Build and run headless, ABI, interaction, cleanup, and example compilation checks:

```sh
python3 tools/run-tests.py
```

Add `--graphics` to render the smoke test and run every example for three frames:

```sh
python3 tools/run-tests.py --graphics
```

See the [testing guide](tests/README.md) for coverage, REPL commands, CI, and
display setup. Display-independent checks pass locally; rendered checks remain
unverified because macOS window-service access was unavailable.

## Regenerating bindings

Generated bindings and constants are checked in; Python is needed only when
updating the vendored API:

```sh
python3 tools/generate-bindings.py
```

## License

The Lisp wrapper is MIT licensed. The unmodified vendored raygui header is
zlib licensed; see [vendor/README.md](vendor/README.md) for provenance.
