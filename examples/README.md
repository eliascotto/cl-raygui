# Examples

Each demo opens its own window and runs with `sbcl --load`, like the
[cl-raylib examples](https://github.com/longlene/cl-raylib/tree/master/examples).
These examples target this library's pinned **raygui 5.0** API. They are
small Lisp programs covering subjects also demonstrated by the
[upstream raygui examples](https://github.com/raysan5/raygui/tree/master/examples),
rather than direct ports of every upstream application.

## Running

Follow the [project's quick start](../README.md#quick-start) first:
install Quicklisp and cl-raylib, and build the native raygui library. No images,
fonts, style files, or other downloaded assets are needed by these demos.
Run from the project directory, for example:

```sh
sbcl --load examples/controls.lisp
```

All top-level `.lisp` files in `examples/` are runnable demos.
`support/common.lisp` only defines shared helpers; loading it alone does not
open a window.

An absolute filename also works from another directory:

```sh
sbcl --load /absolute/path/to/cl-raygui/examples/scroll-panel.lisp
```

Use Escape or the window close button to finish. SBCL returns to its REPL;
add `--quit` to exit the process after the window closes. On macOS, run from
Terminal in your desktop session: window creation and drawing must run on
the main thread.

## Choose an example

| Example | What to try and learn |
| --- | --- |
| [basic.lisp](basic.lisp) | Start here: a checkbox, slider, text field, and message box in one self-contained file. |
| [controls.lisp](controls.lisp) | Buttons, checkboxes, toggles, toggle groups/sliders, combo boxes, and a dropdown. Disable a button and lock background controls while a dropdown is open. |
| [numeric-input.lisp](numeric-input.lisp) | Edit integers and floats, drag sliders, and display progress. Preserve edit-mode flags and a float's text buffer. |
| [text-editing.lisp](text-editing.lisp) | Two persistent writable UTF-8 buffers. Save their contents into Lisp strings, replace their contents, and inspect byte usage. |
| [dialogs.lisp](dialogs.lisp) | Confirmation and text-input dialogs. Lock the background, interpret button indices, and preserve the input dialog's visibility toggle. |
| [lists-and-tabs.lisp](lists-and-tabs.lisp) | Scroll and select from a Lisp sequence or a semicolon-separated string. Switch tabs and preserve selection, scroll, and focus indices. |
| [scroll-panel.lisp](scroll-panel.lisp) | Draw a grid larger than its panel. Apply scroll offsets yourself and clip the content with raylib's scissor mode. |
| [color-picker.lisp](color-picker.lisp) | Independent RGB and HSV pickers, alpha adjustment, and a raylib color preview. Pass returned packed colors directly to raylib. |
| [styles.lisp](styles.lisp) | Switch between default and custom dark styling, change button borders, and display normal/focused/pressed/disabled states. |
| [icons-and-tooltips.lisp](icons-and-tooltips.lisp) | Add icons to button text, draw icons directly, change icon scale, and attach tooltips to individual controls. |

The Open and Save buttons in the icons demo only report clicks; they do not
access files. The dialogs demo keeps its result in memory as well.

## Reading the code

`basic.lisp` includes all setup inline. The other demos load
[support/common.lisp](support/common.lisp), which loads the library, provides
`(rect x y width height)`, and wraps `cl-raylib:with-window` with a frame-rate
limit and cleanup of raygui's global settings. Each demo still shows its own
drawing loop and keeps its control state in an outer `let`.

Important patterns to look for:

- Assign a mutable control's first return value back to its Lisp variable.
  Use `multiple-value-bind` or `multiple-value-setq` when it returns several
  pieces of state; their order is documented in the [Lisp API](../README.md#lisp-api).
- `gui-button` returns a Lisp boolean. Integer result flags from other
  controls need `result-pressed-p` or `result-changed-p`: integer zero is true
  in Common Lisp.
- Allocate editable text buffers outside the frame loop with
  `with-text-buffer`. Capacity counts UTF-8 bytes including the final NUL.
  Each field needs its own buffer; the macro frees it on exit.
- Lock underlying controls and draw dropdowns/dialogs last. Scissor mode
  clips drawing only; the scroll example uses passive labels in its content
  so invisible controls cannot receive input.
- Style colors use `#xRRGGBBAA`. This differs from cl-raylib's native packed
  color representation on the tested platform; `styles.lisp` extracts the
  four bytes into an RGBA list before passing a style color to raylib.

To load an example in a REPL without opening its window:

```lisp
(pushnew :cl-raygui-examples-no-run *features*)
(load "/absolute/path/to/cl-raygui/examples/controls.lisp")
;; Call on the main thread when ready:
(cl-raygui.examples::controls-example)
```

The other entry points follow their filenames, such as
`cl-raygui.examples::scroll-panel-example` and
`cl-raygui.examples::text-editing-example`. Close one window before starting
another; raygui uses global state. The entry point for the original `basic.lisp`
is `cl-user::cl-raygui-example`.
