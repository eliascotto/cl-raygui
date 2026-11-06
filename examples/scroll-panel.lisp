;;; Run: sbcl --load examples/scroll-panel.lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (load (merge-pathnames "support/common.lisp" (or *compile-file-truename* *load-truename*))))
(in-package #:cl-raygui.examples)

(defun scroll-panel-example ()
  (let ((scroll (3d-vectors:vec 0 0))
        (panel (rect 24 64 500 330))
        (content (rect 0 0 900 700)))
    (with-example-window (760 450 "raygui - scroll panel")
      (loop until (cl-raylib:window-should-close) do
        (cl-raylib:with-drawing
          (cl-raylib:clear-background :raywhite)
          (raygui:gui-label (rect 24 16 710 24)
                            "Scroll with the wheel or drag either scrollbar.")
          (multiple-value-bind (updated-scroll view result)
              (raygui:gui-scroll-panel panel nil content scroll)
            (declare (ignore result))
            (setf scroll updated-scroll)
            ;; The panel calculates the visible area; it does not draw content.
            ;; Clip your drawing to VIEW and translate it by the scroll offset.
            (cl-raylib:begin-scissor-mode
              (ceiling (cl-raylib:rectangle-x view))
              (ceiling (cl-raylib:rectangle-y view))
              (floor (cl-raylib:rectangle-width view))
              (floor (cl-raylib:rectangle-height view)))
            (unwind-protect
                 (let ((origin-x (+ (cl-raylib:rectangle-x panel) (3d-vectors:vx scroll)))
                       (origin-y (+ (cl-raylib:rectangle-y panel) (3d-vectors:vy scroll))))
                   (raygui:gui-grid (rect origin-x origin-y 900 700) nil 40 2)
                   (dotimes (row 12)
                     (dotimes (column 4)
                       ;; Labels are passive: offscreen content cannot take input.
                       (raygui:gui-label
                         (rect (+ origin-x 16 (* column 220))
                               (+ origin-y 16 (* row 54)) 190 28)
                         (format nil "Row ~D / Column ~D" (1+ row) (1+ column))))))
              (cl-raylib:end-scissor-mode)))
          (when (raygui:gui-button (rect 560 64 170 32) "Reset scroll")
            (setf scroll (3d-vectors:vec 0 0)))
          (raygui:gui-label (rect 550 122 200 24)
            (format nil "X: ~,0F   Y: ~,0F" (3d-vectors:vx scroll) (3d-vectors:vy scroll)))
          (raygui:gui-status-bar (rect 0 424 760 26)
                                "900 x 700 content inside a 500 x 330 panel."))))))

#-cl-raygui-examples-no-run (scroll-panel-example)
