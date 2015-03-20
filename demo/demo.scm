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

(print "Executing (first '(1 2 3 4 5 6))) results in -> ")
(pp (first '(1 2 3 4 5 6)))

(print "Executing (last '(1 2 3 4 5 6))) results in -> ")
(pp (last '(1 2 3 4 5 6)))

(print "Executing (but-first '(1 2 3 4 5 6))) results in -> ")
(pp (but-first '(1 2 3 4 5 6)))

(print "Executing (reverse! (list 1 2 3 4))) results in -> ")
(pp (reverse! (list 1 2 3 4)))


