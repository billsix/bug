;; Copyright 2014,2015 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.1 or Apache 2.0

(include "../src/lang#.scm")
(include "../src/lang-macros.scm")

(at-both-times
 (begin
   (my-include "lang#.scm")
   (my-include "collections/list#.scm")))

(at-compile-time
 (begin
   (my-include "lang.scm")
   (my-include "lang-macros.scm")
   (my-include "collections/list.scm")))



(print "Executing (pp (identity 5)) results in -> ")
(pp (identity 5))

(print "Executing (aif 5 3) results in -> ")
(pp (aif 5 3))

(print "Executing (reverse! (list 1 2 3 4))) results in -> ")
(pp (reverse! (list 1 2 3 4)))


;; showing off the unit test framework
(with-tests
 ;; this definition happens at compile-time and runtime
 (define foobarbaz 5)
 ;; the following lines only happen at compile time.
 ;; therefore, any mutations to foobarbaz are not reflected in runtime
 (equal? (* 2 foobarbaz) 10)
 (begin
   (set! foobarbaz 20)
   (print "At compile time foobarbaz => ")
   (pp foobarbaz)
   (equal? (* 2 foobarbaz) 40))
 (equal? foobarbaz 20))

(print "At runtime foobarbaz => ")
;; This will print 5
(pp foobarbaz)



