;;; Run: sbcl --load examples/text-editing.lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (load (merge-pathnames "support/common.lisp" (or *compile-file-truename* *load-truename*))))
(in-package #:cl-raygui.examples)

(defun text-editing-example ()
  (let ((name-editing nil) (note-editing nil) (saved "Nothing saved yet."))
    (with-example-window (720 420 "raygui - persistent text buffers")
      ;; Allocate once, outside the drawing loop. These macros free on exit.
      ;; Each field has its own stable native address. Capacities are UTF-8 bytes.
      (raygui:with-text-buffer (name 128 "Common Lisp")
        (raygui:with-text-buffer (note 256 "Edit this note")
          (loop until (cl-raylib:window-should-close) do
            (cl-raylib:with-drawing
              (cl-raylib:clear-background :raywhite)
              (raygui:gui-label (rect 24 16 660 24)
                                "Click a field to edit; Enter commits the edit.")
              (raygui:gui-label (rect 24 76 100 32) "Name")
              (multiple-value-bind (text result)
                  (raygui:gui-text-box (rect 130 76 540 32) name name-editing)
                (declare (ignore text))
                (when (raygui:result-pressed-p result)
                  (setf name-editing (not name-editing)
                        note-editing nil)))
              (raygui:gui-label (rect 24 138 100 32) "Note")
              (multiple-value-bind (text result)
                  (raygui:gui-text-box (rect 130 138 540 32) note note-editing)
                (declare (ignore text))
                (when (raygui:result-pressed-p result)
                  (setf note-editing (not note-editing)
                        name-editing nil)))
              (when (raygui:gui-button (rect 130 208 160 32) "Save to Lisp")
                (setf saved (format nil "~A: ~A" (raygui:text-buffer-string name)
                                    (raygui:text-buffer-string note))
                      name-editing nil note-editing nil))
              (when (raygui:gui-button (rect 310 208 160 32) "Reset buffers")
                (setf (raygui:text-buffer-string name) "Common Lisp"
                      (raygui:text-buffer-string note) "Edit this note"
                      name-editing nil note-editing nil))
              (raygui:gui-label (rect 24 278 660 24) saved)
              (raygui:gui-status-bar (rect 0 394 720 26)
                (format nil "Name uses ~D / ~D UTF-8 bytes (plus NUL)."
                        (length (babel:string-to-octets (raygui:text-buffer-string name)
                                                       :encoding :utf-8))
                        (1- (raygui:text-buffer-capacity name)))))))))))

#-cl-raygui-examples-no-run (text-editing-example)
