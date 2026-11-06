;;; Run: sbcl --load examples/styles.lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (load (merge-pathnames "support/common.lisp" (or *compile-file-truename* *load-truename*))))
(in-package #:cl-raygui.examples)

(defun styles-example ()
  (let ((theme 0) (previous-theme -1) (checked t) (value 0.5) (border 0))
    (with-example-window (720 440 "raygui - styling and states")
      (loop until (cl-raylib:window-should-close) do
        (when (/= theme previous-theme)
          ;; Start from defaults so themes do not inherit previous overrides.
          (raygui:gui-load-style-default)
          (when (= theme 1)
            ;; Style colors are RRGGBBAA integers, unlike cl-raylib:MAKE-RGBA.
            (dolist (entry (list (cons raygui:+background-color+ #x202830ff)
                                (cons raygui:+base-color-normal+ #x344454ff)
                                (cons raygui:+border-color-normal+ #x7890a8ff)
                                (cons raygui:+text-color-normal+ #xe8eef4ff)))
              (raygui:gui-set-style raygui:+default+ (car entry) (cdr entry))))
          (setf previous-theme theme))
        (cl-raylib:with-drawing
          ;; Extract RGBA bytes explicitly: style integers and cl-raylib's
          ;; native packed colors use different byte orders on this platform.
          (let ((rgba (raygui:gui-get-style raygui:+default+ raygui:+background-color+)))
            (cl-raylib:clear-background
              (list (ldb (byte 8 24) rgba) (ldb (byte 8 16) rgba)
                    (ldb (byte 8 8) rgba) (ldb (byte 8 0) rgba))))
          (raygui:gui-label (rect 24 16 660 24) "Change global properties and individual control states.")
          (setf theme (raygui:gui-combo-box (rect 24 64 260 32) "Default;Custom dark" theme)
                border (raygui:gui-combo-box (rect 390 64 290 32) "Thin border;Thick border" border))
          (raygui:gui-set-style raygui:+button+ raygui:+border-width+ (if (zerop border) 1 3))
          (setf checked (raygui:gui-check-box (rect 24 130 22 22) "Styled checkbox" checked)
                value (raygui:gui-slider (rect 120 188 300 24) "Value"
                                         (format nil "~,2F" value) value 0 1))
          (raygui:gui-group-box (rect 24 258 656 108) "Control states")
          ;; State is global: restore NORMAL before drawing other controls.
          (loop for state in (list raygui:+state-normal+ raygui:+state-focused+
                                  raygui:+state-pressed+ raygui:+state-disabled+)
                for label in '("Normal" "Focused" "Pressed" "Disabled")
                for x from 40 by 160 do
                  (raygui:gui-set-state state)
                  (raygui:gui-button (rect x 296 144 32) label))
          (raygui:gui-set-state raygui:+state-normal+)
          (raygui:gui-status-bar (rect 0 414 720 26)
                                "Styles affect subsequent draw calls; no external assets needed."))))))

#-cl-raygui-examples-no-run (styles-example)
