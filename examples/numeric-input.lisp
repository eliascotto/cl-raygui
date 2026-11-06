;;; Run: sbcl --load examples/numeric-input.lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (load (merge-pathnames "support/common.lisp" (or *compile-file-truename* *load-truename*))))
(in-package #:cl-raygui.examples)

(defun numeric-input-example ()
  (let ((count 5) (count-editing nil) (limit 50) (limit-editing nil)
        (amount 1.5) (amount-editing nil) (volume 0.5) (progress 0.25))
    (with-example-window (680 460 "raygui - numeric input")
      ;; Float editing needs persistent text as well as a numeric value.
      ;; At least 33 bytes are required by GUI-VALUE-BOX-FLOAT.
      (raygui:with-text-buffer (amount-text 33 "1.5")
        (loop until (cl-raylib:window-should-close) do
          (cl-raylib:with-drawing
            (cl-raylib:clear-background :raywhite)
            (raygui:gui-label (rect 24 16 620 24)
                              "Click a number to edit; Enter or click outside to finish.")
            (raygui:gui-label (rect 24 74 120 30) "Spinner")
            (multiple-value-bind (value result)
                (raygui:gui-spinner (rect 160 74 200 30) nil count 0 100 count-editing)
              (setf count value)
              (when (raygui:result-pressed-p result)
                (setf count-editing (not count-editing))))
            (raygui:gui-label (rect 24 128 120 30) "Integer")
            (multiple-value-bind (value result)
                (raygui:gui-value-box (rect 160 128 200 30) nil limit 0 100 limit-editing)
              (setf limit value)
              (when (raygui:result-pressed-p result)
                (setf limit-editing (not limit-editing))))
            (raygui:gui-label (rect 24 182 120 30) "Float")
            (multiple-value-bind (value text result)
                (raygui:gui-value-box-float (rect 160 182 200 30) nil
                                           amount-text amount amount-editing)
              (declare (ignore text))
              (setf amount value)
              (when (raygui:result-pressed-p result)
                (setf amount-editing (not amount-editing))))
            (setf volume (raygui:gui-slider (rect 160 254 300 24) "Volume"
                                            (format nil "~,2F" volume) volume 0 1)
                  progress (raygui:gui-slider-bar (rect 160 310 300 24) "Progress"
                                                  nil progress 0 1))
            (raygui:gui-progress-bar (rect 160 366 300 24) nil
                                     (format nil "~D%" (round (* progress 100)))
                                     progress 0 1)
            (raygui:gui-status-bar (rect 0 434 680 26)
              (format nil "Count: ~D | Integer: ~D | Float: ~,3F" count limit amount))))))))

#-cl-raygui-examples-no-run (numeric-input-example)
