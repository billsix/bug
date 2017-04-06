libbug - Bill's Utilities For Gambit
====================================

Libbug provides a concise syntax for lambdas, utilities for general-purpose
computation at compile-time, a compile-time unit test framework, and a
collection of utility functions that Bill finds useful.  Taken together,
these can be used in a "literate programming" style.

The World's Best Unit-Test Framework
------------------------------------

Objectively the world's best unit-test framework.

Look, here it is:
~~~~
{##define-macro unit-test
   [|#!rest tests|
    (eval
     `(if {and ,@tests}
          [''noop]
          [(for-each pp '("Test Failed" ,@tests))
           (error "Tests Failed")]))]}}
~~~~

The most featureful
(unit-tests execute at compile-time, failure results
in no creation of executable/library), while also one
of the shortest (7 lines total).

Open Source
-----------
Copyright 2014-2017 William Emerison Six

All rights reserved

Licensed under either LGPL v2.1 (LGPL.txt), or Apache 2.0 (LICENSE-2.0.txt).


