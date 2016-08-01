;; Copyright 2016 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.1 or Apache 2.0

(##include "config.scm")

{at-both-times
 (pp "FIRST 10 PRIMES")
 (pp (stream->list
      (stream-take 10 primes)))}
