;;; Run from the project directory: sbcl --load examples/basic.lisp
(require :asdf)
(asdf:load-asd (merge-pathnames "../cl-raygui.asd" *load-truename*))
(ql:quickload :cl-raygui)

(defun cl-raygui-example ()
  (let ((checked t)
        (volume 0.5)
        (editing nil)
        (show-message nil))
    (cl-raylib:with-window (640 420 "Common Lisp + raygui")
      (cl-raylib:set-target-fps 60)
      (raygui:with-text-buffer (name 128 "Common Lisp")
        (loop until (cl-raylib:window-should-close) do
          (cl-raylib:with-drawing
            (cl-raylib:clear-background :raywhite)
            ;; Keep background controls inactive while the dialog is open.
            (when show-message (raygui:gui-lock))
            (raygui:gui-label (cl-raylib:make-rectangle :x 24 :y 20 :width 300 :height 24)
                              "raygui 5.0 / Common Lisp")
            (setf checked
                  (raygui:gui-check-box
                    (cl-raylib:make-rectangle :x 24 :y 64 :width 24 :height 24)
                    "Enable option" checked))
            (setf volume
                  (raygui:gui-slider
                    (cl-raylib:make-rectangle :x 80 :y 112 :width 240 :height 24)
                    "Volume" (format nil "~,2F" volume) volume 0 1))
            (multiple-value-bind (text result)
                (raygui:gui-text-box
                  (cl-raylib:make-rectangle :x 24 :y 160 :width 300 :height 32)
                  name editing)
              (declare (ignore text))
              (when (raygui:result-pressed-p result) (setf editing (not editing))))
            (when (raygui:gui-button
                    (cl-raylib:make-rectangle :x 24 :y 216 :width 180 :height 32)
                    (raygui:gui-icon-text raygui:+icon-info+ "Show message"))
              (setf show-message t))
            (raygui:gui-unlock)
            (when show-message
              (multiple-value-bind (button result)
                  (raygui:gui-message-box
                    (cl-raylib:make-rectangle :x 160 :y 120 :width 320 :height 160)
                    "Hello" (raygui:text-buffer-string name) "OK")
                (declare (ignore button))
                (when (raygui:result-pressed-p result) (setf show-message nil))))))))))

#-cl-raygui-examples-no-run (cl-raygui-example)
