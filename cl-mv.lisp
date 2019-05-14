;;;; cl-mv.lisp

(in-package #:cl-mv)

(defmacro mvlet* ((&rest bindings) &body body)
  (mvlet*-helper bindings body))

(defun mvlet*-helper (bindings body)
  (if (endp bindings)
      `(progn ,@body)
      (let* ((binding (car bindings))
             (var (car binding))
             (form (cadr binding))
             (rec (mvlet*-helper (cdr bindings) body)))
        (if (consp var)
            `(multiple-value-bind ,var ,form
               ,rec)
            `(let (,binding)
               ,rec)))))

(defmacro mvlet ((&rest bindings) &body body)
  (mvlet-helper bindings body))

(defun split-bindings (bindings)
  (labels ((rec (rest acc)
             (if (endp rest)
                 (list (nreverse (car acc)) (nreverse (cadr acc)))
                 (rec (cdr rest) (list (cons (caar rest) (car acc))
                                       (cons (cadar rest) (cadr acc)))))))
    (rec bindings (list '() '()))))


(defun mk-gensym-list (lst)
  (mapcar #'(lambda (x)
              (declare (ignore x))
              (gensym)) lst))

(defun mvlet-helper (bindings body)
  (let* ((vars-forms (split-bindings bindings))
         (vars (car vars-forms))
         (forms (cadr vars-forms))
         (var-gensyms (mapcar #'(lambda (var)
                                  (if (consp var)
                                      (mk-gensym-list var)
                                      (gensym)))
                              vars)))
    (labels ((helper (local-var-gensyms forms)
               ;; end case
               (cond ((endp local-var-gensyms)
                      `(let ,(mapcar #'(lambda (var gensym)
                                         (list var gensym))
                                     (flatten vars)
                                     (flatten var-gensyms))
                         ,@body))
                     ;; mv case
                     ((consp (car local-var-gensyms))
                      `(multiple-value-bind ,(car local-var-gensyms)
                         ,(car forms)
                         ,(helper (cdr local-var-gensyms) (cdr forms))))
                     ;; simple case
                     (t
                      `(let ((,(car local-var-gensyms) ,(car forms)))
                         ,(helper (cdr local-var-gensyms) (cdr forms))))) ))
      (helper var-gensyms forms))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Start of Code from Paul Graham's on lisp
;;;

(defun mklist (obj)
  (if (listp obj) obj (list obj)))

(defun group (source n)
  (if (zerop n) (error "zero length"))
  (labels ((rec (source acc)
             (let ((rest (nthcdr n source)))
               (if (consp rest)
                   (rec rest (cons (subseq source 0 n) acc))
                   (nreverse (cons source acc))))))
    (if source (rec source nil) nil)))

(defun flatten (x)
  (labels ((rec (x acc)
             (cond ((null x) acc)
                   ((atom x) (cons x acc))
                   (t (rec (car x) (rec (cdr x) acc))))))
    (rec x nil)))

(defun mappend (fn &rest lsts)
  (apply #'append (apply #'mapcar fn lsts)))

(defmacro mvdo* (parm-cl test-cl &body body)
  (mvdo-gen parm-cl parm-cl test-cl body))

(defun mvdo-gen (binds rebinds test body)
  (if (null binds)
      (let ((label (gensym)))
        `(prog nil
               ,label
               (if ,(car test)
                   (return (progn ,@(cdr test))))
               ,@body
               ,@(mvdo-rebind-gen rebinds)
               (go ,label)))
      (let ((rec (mvdo-gen (cdr binds) rebinds test body)))
        (let ((var/s (caar binds)) (expr (cadar binds)))
          (if (atom var/s)
              `(let ((,var/s ,expr)) ,rec)
              `(multiple-value-bind ,var/s ,expr ,rec))))))

(defun mvdo-rebind-gen (rebinds)
  (cond ((null rebinds) nil)
        ((< (length (car rebinds)) 3)
         (mvdo-rebind-gen (cdr rebinds)))
        (t
         (cons (list (if (atom (caar rebinds))
                         'setq
                         'multiple-value-setq)
                     (caar rebinds)
                     (third (car rebinds)))
               (mvdo-rebind-gen (cdr rebinds))))))

(defmacro mvpsetq (&rest args)
  (let* ((pairs (group args 2))
         (syms  (mapcar #'(lambda (p)
                            (mapcar #'(lambda (x) (gensym))
                                    (mklist (car p))))
                        pairs)))
    (labels ((rec (ps ss)
               (if (null ps)
                   `(setq
                      ,@(mapcan #'(lambda (p s)
                                    (shuffle (mklist (car p))
                                             s))
                                pairs syms))
                   (let ((body (rec (cdr ps) (cdr ss))))
                     (let ((var/s (caar ps))
                           (expr (cadar ps)))
                       (if (consp var/s)
                           `(multiple-value-bind ,(car ss)
                              ,expr
                              ,body)
                           `(let ((,@(car ss) ,expr))
                              ,body)))))))
      (rec pairs syms))))

(defun shuffle (x y)
  (cond ((null x) y)
        ((null y) x)
        (t (list* (car x) (car y)
                  (shuffle (cdr x) (cdr y))))))

(defmacro mvdo (binds (test &rest result) &body body)
  (let ((label (gensym))
        (temps (mapcar #'(lambda (b)
                           (if (listp (car b))
                               (mapcar #'(lambda (x)
                                           (gensym))
                                       (car b))
                               (gensym)))
                       binds)))
    `(let ,(mappend #'mklist temps)
       (mvpsetq ,@(mapcan #'(lambda (b var)
                              (list var (cadr b)))
                          binds
                          temps))
       (prog ,(mapcar #'(lambda (b var) (list b var))
                      (mappend #'mklist (mapcar #'car binds))
                      (mappend #'mklist temps))
             ,label
             (if ,test
                 (return (progn ,@result)))
             ,@body
             (mvpsetq ,@(mapcan #'(lambda (b)
                                    (if (third b)
                                        (list (car b)
                                              (third b))))
                                binds))
             (go ,label)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; End of Code from Paul Graham's On Lisp
;;;
