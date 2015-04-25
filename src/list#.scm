;; Copyright 2014,2015 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.1 or Apache 2.0

(namespace ("list#"
	    copy
	    proper?
	    reverse!
	    first
	    but-first
	    last
	    but-last
	    filter
	    remove
	    fold-left
	    scan-left
	    fold-right
	    flatmap
	    enumerate-interval
	    iota
	    permutations
	    sublists

	    ))

;; don't redefine anything that gambit defined
(include "~~lib/gambit#.scm")
