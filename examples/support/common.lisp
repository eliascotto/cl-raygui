;;; Shared helpers, not a runnable demo. Run ../basic.lisp or ../controls.lisp.
(require :asdf)
(asdf:load-asd (merge-pathnames "../../cl-raygui.asd" *load-truename*))
(ql:quickload :cl-raygui)

(defpackage #:cl-raygui.examples
  (:use #:cl))
(in-package #:cl-raygui.examples)

(defun rect (x y width height)
  "Construct a raylib rectangle with all four fields initialized."
  (cl-raylib:make-rectangle :x x :y y :width width :height height))

(defmacro with-example-window ((width height title) &body body)
  "Keep graphics on the calling thread and restore raygui's global settings."
  `(cl-raylib:with-window (,width ,height ,title)
     (cl-raylib:set-target-fps 60)
     ;; A previous example's window may have owned the old default font.
     (raygui:gui-set-font (cl-raylib:get-font-default))
     (raygui:gui-load-style-default)
     (raygui:gui-enable)
     (raygui:gui-unlock)
     (raygui:gui-set-alpha 1)
     (raygui:gui-set-tooltip nil)
     (unwind-protect
          (progn ,@body)
       ;; Cleanup happens while the window and its font are still alive.
       (raygui:gui-set-tooltip nil)
       (raygui:gui-disable-tooltip)
       (raygui:gui-enable)
       (raygui:gui-unlock)
       (raygui:gui-set-alpha 1)
       (raygui:gui-set-icon-scale 1)
       (raygui:gui-load-style-default))))
