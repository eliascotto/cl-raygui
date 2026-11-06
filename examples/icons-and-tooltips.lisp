;;; Run: sbcl --load examples/icons-and-tooltips.lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (load (merge-pathnames "support/common.lisp" (or *compile-file-truename* *load-truename*))))
(in-package #:cl-raygui.examples)

(defun icons-and-tooltips-example ()
  (let ((status "Hover over a button to see its tooltip.") (large nil))
    (with-example-window (720 400 "raygui - icons and tooltips")
      (raygui:gui-enable-tooltip)
      (loop until (cl-raylib:window-should-close) do
        (cl-raylib:with-drawing
          (cl-raylib:clear-background :raywhite)
          (raygui:gui-label (rect 24 16 660 24) "Use icon constants instead of embedding numeric icon IDs.")
          ;; Set the tooltip immediately before the control it describes.
          ;; The wrapper owns a persistent UTF-8 copy until replaced or cleared.
          (raygui:gui-set-tooltip "This demo reports an action; it does not open a file.")
          (when (raygui:gui-button (rect 24 72 200 36)
                  (raygui:gui-icon-text raygui:+icon-file-open+ "Open"))
            (setf status "Open clicked."))
          (raygui:gui-set-tooltip "Save button with an icon and a Lisp string.")
          (when (raygui:gui-button (rect 252 72 200 36)
                  (raygui:gui-icon-text raygui:+icon-file-save+ "Save"))
            (setf status "Save clicked."))
          (raygui:gui-set-tooltip "Display an informational status message.")
          (when (raygui:gui-button (rect 480 72 200 36)
                  (raygui:gui-icon-text raygui:+icon-info+ "Info"))
            (setf status "raygui icons are bundled in the native library."))
          ;; Clear retained text so unrelated controls do not inherit a tooltip.
          (raygui:gui-set-tooltip nil)
          (setf large (raygui:gui-check-box (rect 24 150 22 22) "Large button icons" large))
          (raygui:gui-set-icon-scale (if large 2 1))
          (raygui:gui-label (rect 24 212 400 24) "Draw icons directly with a size and color:")
          (loop for icon in (list raygui:+icon-file-open+ raygui:+icon-file-save+ raygui:+icon-info+)
                for x from 24 by 90 do
                  (raygui:gui-draw-icon icon x 260 3 :darkblue))
          (raygui:gui-status-bar (rect 0 374 720 26) status))))))

#-cl-raygui-examples-no-run (icons-and-tooltips-example)
