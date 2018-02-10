;; Copyright 2017-2018 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.1 or Apache 2.0

(##include "config.scm")

;; "define" is namespaced in "config.scm"
;; It will evaluate definitions both at
;; compile time and at runtime.
{define first-ten-primes
  (stream->list
   (stream-take 10 primes))}

;; "unit-test" runs at compile-time
{unit-test
 (equal? first-ten-primes
         '(2 3 5 7 11 13 17 19 23 29))}

{at-both-times
 (pp "FIRST 10 PRIMES")
 (pp first-ten-primes)}

;; "##define" is Gambit's normal "define",
;; which is not evaluated during compile-time.
{##define foo (command-line)}
(pp foo)
(pp ((compose [|x| (+ x 1)] [|y| (* y 2)]) 10))
