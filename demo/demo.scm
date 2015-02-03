;; Copyright 2014,2015 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.0 or Apache 2.0

(include "../src/lang#.scm")
(include "../src/lang-macros.scm")
(include "../src/collections/list#.scm")


(at-compile-time
 (begin
   (include "../src/lang#.scm")
   (include "../src/lang.scm")
   (include "../src/lang-macros.scm")
   (include "../src/collections/list#.scm")))
   ;;(include "../src/collections/list.scm")))

(with-tests
 (define (bar a)
   (aif a
	(list it it)))
 (equal? (bar #f) #f)
 (equal? (bar 3) '(3 3)))

(define (main)
  (pp (bar "demo ")))

(main)
