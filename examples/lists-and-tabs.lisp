;;; Run: sbcl --load examples/lists-and-tabs.lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (load (merge-pathnames "support/common.lisp" (or *compile-file-truename* *load-truename*))))
(in-package #:cl-raygui.examples)

(defun lists-and-tabs-example ()
  (let ((active -1) (scroll 0) (focus -1) (tab 0) (tab-scroll 0)
        (simple-active -1) (simple-scroll 0)
        (items (coerce (loop for i from 1 to 30 collect (format nil "Item ~2,'0D" i))
                       'vector)))
    (with-example-window (760 480 "raygui - lists and tabs")
      ;; This example switches tabs; it does not implement tab closing.
      (raygui:gui-set-style raygui:+tabbar+ raygui:+tab-close-button+ 0)
      (loop until (cl-raylib:window-should-close) do
        (cl-raylib:with-drawing
          (cl-raylib:clear-background :raywhite)
          (multiple-value-setq (tab tab-scroll)
            (raygui:gui-tab-bar (rect 24 20 710 32) "Browse;Details" tab-scroll tab))
          (if (zerop tab)
              (progn
                (raygui:gui-label (rect 24 72 310 24) "Sequence of strings (EX)")
                ;; Return order: active, scroll, focus, result. Store all state.
                (multiple-value-setq (active scroll focus)
                  (raygui:gui-list-view-ex (rect 24 106 310 290) items scroll active focus))
                (raygui:gui-label (rect 380 72 330 24) "Semicolon-separated string")
                (multiple-value-setq (simple-active simple-scroll)
                  (raygui:gui-list-view (rect 380 106 330 180)
                    "Mercury;Venus;Earth;Mars;Jupiter;Saturn;Uranus;Neptune"
                    simple-scroll simple-active)))
              (progn
                (raygui:gui-panel (rect 24 88 710 250) "Selection details")
                ;; -1 means no selection: guard before indexing the sequence.
                (raygui:gui-label (rect 48 140 640 30)
                  (if (minusp active) "Choose an item on the Browse tab."
                      (format nil "Selected: ~A" (aref items active))))
                (raygui:gui-label (rect 48 190 640 30)
                  (format nil "Scroll index: ~D | Focus index: ~D" scroll focus))))
          (raygui:gui-status-bar (rect 0 454 760 26)
            "Scroll the list, select an item, then open Details."))))))

#-cl-raygui-examples-no-run (lists-and-tabs-example)
