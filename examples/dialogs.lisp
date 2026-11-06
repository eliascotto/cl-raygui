;;; Run: sbcl --load examples/dialogs.lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (load (merge-pathnames "support/common.lisp" (or *compile-file-truename* *load-truename*))))
(in-package #:cl-raygui.examples)

(defun dialogs-example ()
  (let ((dialog nil) (secret-visible t) (status "Open a dialog."))
    (with-example-window (720 440 "raygui - modal dialogs")
      (raygui:with-text-buffer (input 128 "Ada")
        (loop until (cl-raylib:window-should-close) do
          (cl-raylib:with-drawing
            (cl-raylib:clear-background :raywhite)
            ;; Lock background controls before drawing, unlock for the dialog.
            (when dialog (raygui:gui-lock))
            (when (raygui:gui-button (rect 24 40 220 36) "Confirm an action")
              (setf dialog :confirm))
            ;; A newly opened dialog must lock the remaining controls too.
            (when dialog (raygui:gui-lock))
            (when (raygui:gui-button (rect 24 96 220 36) "Enter a name")
              (setf dialog :input))
            (raygui:gui-label (rect 24 350 660 32) status)
            (raygui:gui-unlock)
            (when dialog
              (cl-raylib:draw-rectangle 0 0 720 440 '(0 0 0 100))
              (ecase dialog
                (:confirm
                 (multiple-value-bind (button result)
                     (raygui:gui-message-box (rect 180 120 360 180)
                                             "Confirm" "Apply the change?" "Apply;Cancel")
                   ;; -1: idle, 0: window close, 1/2: action buttons.
                   (when (raygui:result-pressed-p result)
                     (setf status (if (= button 1) "Change applied." "Cancelled.")
                           dialog nil))))
                (:input
                 (multiple-value-bind (text button visible result)
                     (raygui:gui-text-input-box (rect 160 100 400 220)
                       "Name" "Enter a display name:" input "Accept;Cancel"
                       -1 secret-visible)
                   ;; Preserve the eye toggle between frames. T starts visible.
                   (setf secret-visible visible)
                   (when (raygui:result-pressed-p result)
                     (setf status (if (= button 1) (format nil "Hello, ~A!" text)
                                      "Cancelled.")
                           dialog nil))))))))))))

#-cl-raygui-examples-no-run (dialogs-example)
