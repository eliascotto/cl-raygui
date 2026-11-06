(in-package #:cl-raygui.raw)

;; Use our own one-byte C99 bool type: older CFFI releases expand :boolean
;; arguments to scalar 0/1 even when libffi needs a pointer to an argument slot.
(cffi:define-foreign-type c-bool-type () ()
  (:actual-type :unsigned-char)
  (:simple-parser c-bool))

(defmethod cffi:translate-to-foreign (value (type c-bool-type))
  (declare (ignore type))
  (if value 1 0))

(defmethod cffi:translate-into-foreign-memory (value (type c-bool-type) pointer)
  (declare (ignore type))
  (setf (cffi:mem-ref pointer :unsigned-char) (if value 1 0)))

(defmethod cffi:translate-from-foreign (value (type c-bool-type))
  (declare (ignore type))
  ;; libffi returns an address for struct calls; ordinary calls and MEM-REF
  ;; supply the scalar byte. Support both without changing other CFFI types.
  (not (zerop (if (cffi:pointerp value)
                  (cffi:mem-ref value :unsigned-char)
                  value))))

(cffi:define-foreign-type nullable-string () ()
  (:actual-type :pointer)
  (:simple-parser nullable-string))

(defmethod cffi:translate-to-foreign (value (type nullable-string))
  (declare (ignore type))
  (cond ((null value) (values (cffi:null-pointer) nil))
        ((stringp value)
         (values (cffi:foreign-string-alloc value :encoding :utf-8) t))
        ((cffi:pointerp value) (values value nil))
        (t (error "Expected a string, NIL, or a foreign pointer, got ~S" value))))

(defmethod cffi:free-translated-object (pointer (type nullable-string) allocated-p)
  (declare (ignore type))
  (when allocated-p (cffi:foreign-string-free pointer)))

;; libffi marshals every argument indirectly when a call includes a struct by
;; value (e.g. GuiLabel's Rectangle). Translate the string first, then store its
;; pointer in the argument slot. EXPAND-TO-FOREIGN-DYN keeps the allocation alive
;; through the call and runs FREE-TRANSLATED-OBJECT on normal and nonlocal exits.
;; This is the same extension point CFFI uses for its built-in :string type.
(defmethod cffi::expand-to-foreign-dyn-indirect
    (value var body (type nullable-string))
  (let ((pointer (gensym "STRING-POINTER")))
    (cffi:expand-to-foreign-dyn
     value pointer
     (list `(cffi:with-foreign-object (,var :pointer)
              (setf (cffi:mem-ref ,var :pointer) ,pointer)
              ,@body))
     type)))

(cffi:defcstruct gui-style-prop
  (control-id :unsigned-short)
  (property-id :unsigned-short)
  (property-value :int))
