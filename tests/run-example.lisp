(load (merge-pathnames "bootstrap.lisp" *load-truename*))
(setf *features* (remove :cl-raygui-examples-no-run *features*))
(let ((original (symbol-function 'cl-raylib:window-should-close))
      (frames 0)
      (file (or (uiop:getenv "CL_RAYGUI_TEST_EXAMPLE")
                (error "CL_RAYGUI_TEST_EXAMPLE must name a demo."))))
  ;; Bound the existing drawing loop without changing the demo or substituting
  ;; any drawing/control functions. Three frames execute against real graphics.
  (setf (symbol-function 'cl-raylib:window-should-close)
        (lambda () (> (incf frames) 3)))
  (unwind-protect
       (progn
         (cl-raylib:set-config-flags 128) ; FLAG_WINDOW_HIDDEN
         (load file)
         (assert (= frames 4))
         (format t "~&cl-raygui: ~A rendered 3 frames.~%" (file-namestring file)))
    (setf (symbol-function 'cl-raylib:window-should-close) original)))
