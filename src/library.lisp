(in-package #:cl-raygui.raw)

(cffi:define-foreign-library libraygui
  (:darwin (:or "libraygui.dylib" "raygui.dynlib" "raygui.dylib"))
  (:unix "libraygui.so")
  (:windows (:or "raygui.dll" "libraygui.dll"))
  (t (:default "libraygui")))

(defvar *raygui-library* nil)

(defun load-raygui (&optional path)
  "Load the native library. PATH or CL_RAYGUI_LIBRARY overrides library search."
  (unless (and *raygui-library* (cffi:foreign-library-loaded-p *raygui-library*))
    (let* ((override (or path (uiop:getenv "CL_RAYGUI_LIBRARY")))
           (root (asdf:system-source-directory :cl-raygui))
           (filenames #+darwin '("libraygui.dylib" "raygui.dynlib" "raygui.dylib")
                      #+(and unix (not darwin)) '("libraygui.so")
                      #+windows '("raygui.dll" "libraygui.dll")
                      #-(or darwin unix windows) '("libraygui"))
           (local (loop for dir in '("build/" "build/Release/" "build/Debug/")
                        thereis (loop for filename in filenames
                                      for candidate = (merge-pathnames filename (merge-pathnames dir root))
                                      when (probe-file candidate) return candidate))))
      (handler-case
          (setf *raygui-library*
                (cond (override (cffi:load-foreign-library override))
                      (local (cffi:load-foreign-library local))
                      (t (cffi:use-foreign-library libraygui))))
        (cffi:load-foreign-library-error (condition)
          (error "Cannot load raygui 5.0: ~A~%~A Alternatively, set CL_RAYGUI_LIBRARY to the library's absolute path."
                 condition
                 #+darwin (format nil "Build it with bash ~S."
                                  (namestring (merge-pathnames "tools/build-macos.sh" root)))
                 #-darwin (format nil "Build it with cmake -S ~S -B ~S && cmake --build ~S."
                                  (namestring root)
                                  (namestring (merge-pathnames "build/" root))
                                  (namestring (merge-pathnames "build/" root))))))))
  t)

(load-raygui)
