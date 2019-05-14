;;;; package.lisp

(defpackage #:cl-mv
  (:use #:cl)
  (:nicknames #:mv)
  (:export #:cl-mv
           #:mvpsetq
           #:mvdo*
           #:mvdo
           #:mvlet*
           #:mvlet))
