(asdf:defsystem #:cl-raygui
  :version "0.1.0"
  :license "MIT"
  :description "Common Lisp bindings for raygui 5.0, using cl-raylib types"
  :depends-on (#:cl-raylib #:cffi-libffi #:babel)
  :serial t
  :components ((:file "src/package")
               (:file "src/library")
               (:file "src/types")
               (:file "src/constants")
               (:file "src/bindings")
               (:file "src/api"))
  :in-order-to ((asdf:test-op (asdf:test-op #:cl-raygui/tests))))

(asdf:defsystem #:cl-raygui/tests
  :depends-on (#:cl-raygui)
  :serial t
  :components ((:file "tests/tests")
               (:file "tests/interactions"))
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (uiop:symbol-call '#:cl-raygui.tests '#:run-tests)))
