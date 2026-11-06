;;; Shared startup for isolated test processes. Quicklisp must be installed.
(require :asdf)
(unless (find-package :ql)
  (load (or (uiop:getenv "CL_RAYGUI_QUICKLISP_SETUP")
            (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))))
(asdf:load-asd (merge-pathnames "../cl-raygui.asd" *load-truename*))
(ql:quickload :cl-raygui/tests)
