;;; Run: sbcl --load examples/controls.lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (load (merge-pathnames "support/common.lisp" (or *compile-file-truename* *load-truename*))))
(in-package #:cl-raygui.examples)

(defun controls-example ()
  (let ((enabled t) (toggle nil) (alignment 0) (mode 0)
        (choice 0) (dropdown 0) (dropdown-open nil) (clicks 0))
    (with-example-window (720 470 "raygui - basic controls")
      (loop until (cl-raylib:window-should-close) do
        (cl-raylib:with-drawing
          (cl-raylib:clear-background :raywhite)
          (raygui:gui-label (rect 24 16 660 24)
                            "Keep control values in Lisp between frames.")
          ;; Lock underlying controls while the dropdown overlaps them.
          (when dropdown-open (raygui:gui-lock))
          (setf enabled (raygui:gui-check-box (rect 24 66 22 22)
                                             "Enable action button" enabled))
          (unless enabled (raygui:gui-disable))
          ;; GUI-BUTTON returns a Lisp boolean, so WHEN is appropriate here.
          (when (raygui:gui-button (rect 24 108 220 32) "Click me")
            (incf clicks))
          (raygui:gui-enable)
          (raygui:gui-label (rect 270 108 200 32) (format nil "Clicks: ~D" clicks))
          (setf toggle (raygui:gui-toggle (rect 24 166 220 32) "Toggle" toggle)
                alignment (raygui:gui-toggle-group (rect 24 224 90 30)
                                                   "Left;Center;Right" alignment)
                mode (raygui:gui-toggle-slider (rect 24 282 280 30)
                                               "Edit;Preview" mode)
                choice (raygui:gui-combo-box (rect 24 340 280 30)
                                             "Small;Medium;Large" choice))
          (raygui:gui-status-bar (rect 0 444 720 26)
            (format nil "Toggle: ~A | Alignment: ~D | Mode: ~D | Size: ~D"
                    toggle alignment mode choice))
          ;; Draw the overlapping control last, after unlocking it.
          (raygui:gui-unlock)
          (multiple-value-bind (active result)
              (raygui:gui-dropdown-box (rect 420 66 250 32)
                                       "First;Second;Third;Fourth" dropdown dropdown-open)
            (setf dropdown active)
            ;; Raw result flags are integers: zero is true in Common Lisp.
            ;; Selecting a different entry returns CHANGED; clicking the
            ;; current entry or dismissing the popup returns PRESSED.
            (when (or (raygui:result-pressed-p result)
                      (raygui:result-changed-p result))
              (setf dropdown-open (not dropdown-open)))))))))

#-cl-raygui-examples-no-run (controls-example)
