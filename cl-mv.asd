;;;; cl-mv.asd

(asdf:defsystem #:cl-mv
  :description "Common Lisp utilities for mulitple values."
  :author "Finn Völkel"
  :version "0.0.1"
  :serial t
  :components ((:file "package")
               (:file "cl-mv")))
