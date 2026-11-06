;;; Run: sbcl --load examples/color-picker.lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (load (merge-pathnames "support/common.lisp" (or *compile-file-truename* *load-truename*))))
(in-package #:cl-raygui.examples)

(defun color-picker-example ()
  (let ((color '(80 140 220 255)) (alpha 1.0)
        (hsv (3d-vectors:vec 180.0 0.5 0.8)))
    (with-example-window (760 450 "raygui - RGB and HSV colors")
      (loop until (cl-raylib:window-should-close) do
        (cl-raylib:with-drawing
          (cl-raylib:clear-background :raywhite)
          (raygui:gui-label (rect 24 16 320 24) "RGB picker and alpha")
          (raygui:gui-label (rect 414 16 320 24) "Independent HSV picker")
          ;; Color accepts an RGBA list, keyword, or cl-raylib packed value.
          ;; The returned packed color can be passed directly to raylib drawing.
          (setf color (raygui:gui-color-picker (rect 24 64 240 220) nil color)
                alpha (raygui:gui-color-bar-alpha (rect 24 314 240 24) nil alpha)
                hsv (raygui:gui-color-picker-hsv (rect 414 64 240 220) nil hsv))
          (cl-raylib:draw-rectangle 24 362 280 38 :lightgray)
          (cl-raylib:draw-rectangle 24 362 280 38 (cl-raylib:fade color alpha))
          (raygui:gui-label (rect 414 310 320 28)
            (format nil "H: ~,0F  S: ~,2F  V: ~,2F"
                    (3d-vectors:vx hsv) (3d-vectors:vy hsv) (3d-vectors:vz hsv)))
          (raygui:gui-status-bar (rect 0 424 760 26)
            (format nil "cl-raylib packed color: #x~8,'0X | Alpha: ~,2F" color alpha)))))))

#-cl-raygui-examples-no-run (color-picker-example)
