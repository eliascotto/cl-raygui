(in-package #:cl-raygui)

(defun result-pressed-p (result) (logtest +result-pressed+ result))
(defun result-changed-p (result) (logtest +result-changed+ result))
(defun result-tab-close-p (result) (logtest +result-tab-close+ result))

(defun gui-set-alpha (alpha)
  (cl-raygui.raw:gui-set-alpha (float alpha 1.0f0)))

(defun gui-set-style (control property value)
  "Accept signed property values or unsigned 32-bit RGBA color bit patterns."
  (check-type value (integer #.(- (expt 2 31)) #.(1- (expt 2 32))))
  (cl-raygui.raw:gui-set-style control property
    (if (logbitp 31 value) (- (ldb (byte 32 0) value) (expt 2 32)) value)))

(defun gui-get-style (control property)
  "Return the unsigned 32-bit style value (including RGBA color properties)."
  (ldb (byte 32 0) (cl-raygui.raw:gui-get-style control property)))

(defmacro define-control (name args mutable call)
  "Marshal in/out values. Return updated values in MUTABLE order, then result."
  (let* ((pointers (loop for (var type) in mutable
                         collect (list var (gensym (symbol-name var)) type)))
         (result (gensym "RESULT")))
    `(defun ,name ,args
       ,(format nil "Return ~{~A~^, ~}, then the integer GuiResult flags."
                (mapcar (lambda (entry) (string-downcase (symbol-name (first entry)))) mutable))
       (cffi:with-foreign-objects
           ,(loop for (var ptr type) in pointers collect (list ptr `',type))
         ,@(loop for (var ptr type) in pointers
                 collect `(setf (cffi:mem-ref ,ptr ',type)
                                ,(if (eq type :float) `(float ,var 1.0f0) var)))
         (let ((,result ,(sublis (loop for (var ptr type) in pointers
                                      collect (cons var ptr)) call)))
           (values ,@(loop for (var ptr type) in pointers
                           collect `(cffi:mem-ref ,ptr ',type))
                   ,result))))))

(defun gui-button (bounds text)
  "Return true when clicked, and the raw GuiResult flags as a second value."
  (let ((result (cl-raygui.raw:gui-button bounds text)))
    (values (result-pressed-p result) result)))

(defun gui-label-button (bounds text)
  (let ((result (cl-raygui.raw:gui-label-button bounds text)))
    (values (result-pressed-p result) result)))

(defun gui-window-box (bounds title)
  "Return true when the close button is clicked, then the result flags."
  (let ((result (cl-raygui.raw:gui-window-box bounds title)))
    (values (result-pressed-p result) result)))

(define-control gui-toggle (bounds text active)
  ((active cl-raygui.raw::c-bool))
  (cl-raygui.raw:gui-toggle bounds text active))
(define-control gui-check-box (bounds text checked)
  ((checked cl-raygui.raw::c-bool))
  (cl-raygui.raw:gui-check-box bounds text checked))
(define-control gui-toggle-group (bounds text active)
  ((active :int)) (cl-raygui.raw:gui-toggle-group bounds text active))
(define-control gui-toggle-slider (bounds text active)
  ((active :int)) (cl-raygui.raw:gui-toggle-slider bounds text active))
(define-control gui-combo-box (bounds text active)
  ((active :int)) (cl-raygui.raw:gui-combo-box bounds text active))
(define-control gui-dropdown-box (bounds text active edit-mode)
  ((active :int)) (cl-raygui.raw:gui-dropdown-box bounds text active edit-mode))
(define-control gui-spinner (bounds text value min-value max-value edit-mode)
  ((value :int))
  (cl-raygui.raw:gui-spinner bounds text value min-value max-value edit-mode))
(define-control gui-value-box (bounds text value min-value max-value edit-mode)
  ((value :int))
  (cl-raygui.raw:gui-value-box bounds text value min-value max-value edit-mode))

;; Coerce input scalar floats, including in/out values, for normal Lisp numbers.
(defmacro define-float-control (name &optional range-p)
  `(define-control ,name
       (bounds text ,@(when range-p '(text-right)) value
               ,@(when range-p '(min-value max-value)))
     ((value :float))
     (,(intern (symbol-name name) :cl-raygui.raw)
      bounds text ,@(when range-p '(text-right)) value
      ,@(when range-p '((float min-value 1.0f0) (float max-value 1.0f0))))))

(define-float-control gui-slider t)
(define-float-control gui-slider-bar t)
(define-float-control gui-progress-bar t)
(define-float-control gui-color-bar-alpha)
(define-float-control gui-color-bar-hue)

(define-control gui-color-picker (bounds text color)
  ((color (:struct cl-raylib::%color)))
  (cl-raygui.raw:gui-color-picker bounds text color))
(define-control gui-color-panel (bounds text color)
  ((color (:struct cl-raylib::%color)))
  (cl-raygui.raw:gui-color-panel bounds text color))
(define-control gui-color-picker-hsv (bounds text color-hsv)
  ((color-hsv (:struct cl-raylib::%vector3)))
  (cl-raygui.raw:gui-color-picker-hsv bounds text color-hsv))
(define-control gui-color-panel-hsv (bounds text color-hsv)
  ((color-hsv (:struct cl-raylib::%vector3)))
  (cl-raygui.raw:gui-color-panel-hsv bounds text color-hsv))

(define-control gui-grid (bounds text spacing subdivs &optional (mouse-cell (3d-vectors:vec 0 0)))
  ((mouse-cell (:struct cl-raylib::%vector2)))
  (cl-raygui.raw:gui-grid bounds text (float spacing 1.0f0) subdivs mouse-cell))
(define-control gui-scroll-panel (bounds text content scroll
                                &optional (view (cl-raylib:make-rectangle
                                                  :x 0 :y 0 :width 0 :height 0)))
  ((scroll (:struct cl-raylib::%vector2)) (view (:struct cl-raylib::%rectangle)))
  (cl-raygui.raw:gui-scroll-panel bounds text content scroll view))
(define-control gui-list-view (bounds text scroll-index active)
  ((active :int) (scroll-index :int))
  (cl-raygui.raw:gui-list-view bounds text scroll-index active))
(define-control gui-tab-bar (bounds text hscroll active)
  ((active :int) (hscroll :int))
  (cl-raygui.raw:gui-tab-bar bounds text hscroll active))
(define-control gui-message-box (bounds title message btn-text &optional (btn-active -1))
  ((btn-active :int))
  (cl-raygui.raw:gui-message-box bounds title message btn-text btn-active))

(defun call-with-string-array (strings function)
  "Keep every UTF-8 string alive until FUNCTION returns, including on errors."
  (let* ((items (coerce strings 'vector))
         (count (length items))
         (allocated nil))
    (cffi:with-foreign-object (array :pointer (max 1 count))
      (unwind-protect
           (progn
             (dotimes (i count)
               (let ((ptr (cffi:foreign-string-alloc (aref items i) :encoding :utf-8)))
                 (push ptr allocated)
                 (setf (cffi:mem-aref array :pointer i) ptr)))
             (funcall function array count))
        (mapc #'cffi:foreign-string-free allocated)))))

(defun gui-list-view-ex (bounds text scroll-index active focus)
  "TEXT is a sequence of strings. Return active, scroll-index, focus, result."
  (call-with-string-array text
    (lambda (array count)
      (%list-view-ex bounds array count scroll-index active focus))))
(define-control %list-view-ex (bounds text count scroll-index active focus)
  ((active :int) (scroll-index :int) (focus :int))
  (cl-raygui.raw:gui-list-view-ex bounds text count scroll-index active focus))

(defun gui-tab-bar-ex (bounds text hscroll active focus)
  "TEXT is a sequence of strings. Return active, hscroll, focus, result."
  (call-with-string-array text
    (lambda (array count)
      (%tab-bar-ex bounds array count hscroll active focus))))
(define-control %tab-bar-ex (bounds text count hscroll active focus)
  ((active :int) (hscroll :int) (focus :int))
  (cl-raygui.raw:gui-tab-bar-ex bounds text count hscroll active focus))

(defstruct (text-buffer (:constructor %make-text-buffer (pointer capacity)))
  (pointer (cffi:null-pointer))
  (capacity 1 :type (integer 1 #.most-positive-fixnum) :read-only t))

(defun checked-text-pointer (buffer)
  (let ((ptr (text-buffer-pointer buffer)))
    (when (cffi:null-pointer-p ptr) (error "Text buffer has been freed."))
    ptr))

(defun (setf text-buffer-string) (string buffer)
  "Copy STRING as UTF-8. Capacity includes the terminating zero byte."
  (check-type string string)
  (when (find #\Null string) (error "Text buffers cannot contain NUL characters."))
  (let ((bytes (babel:string-to-octets string :encoding :utf-8))
        (ptr (checked-text-pointer buffer)))
    (when (>= (length bytes) (text-buffer-capacity buffer))
      (error "Text requires ~D bytes including NUL; buffer capacity is ~D."
             (1+ (length bytes)) (text-buffer-capacity buffer)))
    (dotimes (i (text-buffer-capacity buffer))
      (setf (cffi:mem-aref ptr :unsigned-char i)
            (if (< i (length bytes)) (aref bytes i) 0))))
  string)

(defun text-buffer-string (buffer)
  (let* ((ptr (checked-text-pointer buffer))
         (end (loop for i below (text-buffer-capacity buffer)
                    when (zerop (cffi:mem-aref ptr :unsigned-char i)) return i)))
    (unless end (error "Text buffer has no NUL terminator within its capacity."))
    (cffi:foreign-string-to-lisp ptr :count end :encoding :utf-8)))

(defun make-text-buffer (&optional (capacity 256) (initial-string ""))
  "Allocate a persistent writable UTF-8 buffer. Free with FREE-TEXT-BUFFER."
  (check-type capacity (integer 1 #.most-positive-fixnum))
  (let ((buffer (%make-text-buffer (cffi:foreign-alloc :unsigned-char :count capacity) capacity)))
    (handler-case (progn (setf (text-buffer-string buffer) initial-string) buffer)
      (error (condition) (free-text-buffer buffer) (error condition)))))

(defun free-text-buffer (buffer)
  "Release a buffer; safe to call repeatedly."
  (unless (cffi:null-pointer-p (text-buffer-pointer buffer))
    (cffi:foreign-free (text-buffer-pointer buffer))
    (setf (text-buffer-pointer buffer) (cffi:null-pointer)))
  nil)

(defmacro with-text-buffer ((name &optional (capacity 256) (initial-string "")) &body body)
  `(let ((,name (make-text-buffer ,capacity ,initial-string)))
     (unwind-protect (progn ,@body) (free-text-buffer ,name))))

(defun gui-text-box (bounds buffer edit-mode)
  "Return updated text and result flags. BUFFER must be a live text-buffer."
  (let ((result (cl-raygui.raw:gui-text-box bounds (checked-text-pointer buffer)
                                          (text-buffer-capacity buffer) edit-mode)))
    (values (text-buffer-string buffer) result)))

(defun gui-value-box-float (bounds text buffer value edit-mode)
  "Return value, updated text, result. BUFFER needs at least 33 bytes."
  (when (< (text-buffer-capacity buffer) 33)
    (error "GuiValueBoxFloat requires at least 33 bytes of writable storage."))
  (when (> (length (babel:string-to-octets (text-buffer-string buffer) :encoding :utf-8)) 32)
    (error "GuiValueBoxFloat accepts at most 32 text bytes."))
  (cffi:with-foreign-object (ptr :float)
    (setf (cffi:mem-ref ptr :float) (float value 1.0f0))
    (let ((result (cl-raygui.raw:gui-value-box-float bounds text
                   (checked-text-pointer buffer) ptr edit-mode)))
      (values (cffi:mem-ref ptr :float) (text-buffer-string buffer) result))))

(defun gui-text-input-box (bounds title message buffer btn-text
                         &optional (btn-active -1) (secret-view-active nil))
  "Return updated text, button index, secret-view-active, result flags."
  (cffi:with-foreign-objects ((button :int) (secret 'cl-raygui.raw::c-bool))
    (setf (cffi:mem-ref button :int) btn-active
          (cffi:mem-ref secret 'cl-raygui.raw::c-bool) secret-view-active)
    (let ((result (cl-raygui.raw:gui-text-input-box bounds title message
                    (checked-text-pointer buffer) (text-buffer-capacity buffer)
                    btn-text button secret)))
      (values (text-buffer-string buffer) (cffi:mem-ref button :int)
              (cffi:mem-ref secret 'cl-raygui.raw::c-bool) result))))

(defvar *tooltip-pointer* (cffi:null-pointer))

(defun gui-set-tooltip (text)
  "Keep a UTF-8 copy alive until the next tooltip; NIL clears and frees it."
  (let ((ptr (if text (cffi:foreign-string-alloc text :encoding :utf-8) (cffi:null-pointer)))
        (old *tooltip-pointer*))
    (cl-raygui.raw:gui-set-tooltip ptr)
    (setf *tooltip-pointer* ptr)
    (unless (cffi:null-pointer-p old) (cffi:foreign-string-free old)))
  text)
