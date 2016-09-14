;; Copyright 2016 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.1 or Apache 2.0

(##include "config.scm")

{define first-ten-primes
  (stream->list
   (stream-take 10 primes))}

{unit-test
 (equal? first-ten-primes
         '(2 3 5 7 11 13 17 19 23 29))}

{at-both-times
 (pp "FIRST 10 PRIMES")
 (pp first-ten-primes)}
