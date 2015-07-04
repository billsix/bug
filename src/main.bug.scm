;; Copyright 2014,2015 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.1 or Apache 2.0

|#
Here is a block comment
#|

{##namespace ("libbug#")}
(##include "~~lib/gambit#.scm")

;; at-compile-time
;;  Evaluate the form in the compiler's address space.  When the program is
;;  executed, form will not be evaluated.

{##namespace ("lang#" at-compile-time)}
{define-macro at-compile-time
  [|form|
   (eval form)
   `{quote noop}]}


;; at-both-times
;;  Evaluate the form in the compiler's address space, and also when the
;;  resulting program is executed.

{##namespace ("lang#" at-both-times)}
{define-macro at-both-times
  [|form|
   (eval form)
   form]}



;; create header file for external projects,
;; and a macro file for external projects
{at-compile-time
 {begin
   {define libbug-headers-file
     (open-output-file '(path:
			 "libbug#.scm"
			 append:
			 #f))}
   {define libbug-macros-file
     (open-output-file '(path:
			 "libbug-macros.scm"
			 append:
			 #f))}}}


;;  add copyright to those two files
{at-compile-time
 {begin
   (display
    ";; Copyright 2014,2015 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.1 or Apache 2.0
{##namespace (\"lang#\" at-compile-time)}
{##namespace (\"lang#\" at-both-times)}"
    libbug-headers-file)
   (display
    ";; Copyright 2014,2015 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.1 or Apache 2.0
{##namespace (\"libbug#\")}
(##include \"~~lib/gambit#.scm\")
(##include \"libbug#.scm\")




{define-macro at-compile-time
  [|form|
   (eval form)
   `{quote noop}]}
{define-macro at-both-times
  [|form|
   (eval form)
   form]}"
    libbug-macros-file)}}


{define-macro write-and-eval
  [|port form|
   (newline (eval port))
   (write form (eval port))
   form]}



;;Sets the namespace for during macro-expansion, for
;;run-time, and writes to out to libbug#.scm


{define-macro libbug-internal#namespace
  [|namespace-name-pair|
   {begin
     (eval `{##namespace ,namespace-name-pair})
     `(write-and-eval
       libbug-headers-file
       {##namespace ,namespace-name-pair})}]}


{libbug-internal#namespace ("lang#" if)}
(write-and-eval
 libbug-macros-file
 {at-both-times
  {define-macro if
    [|pred ifTrue ifFalse|
     ;; (expression? [5]) => true
     ;; (expression? [(pp 4) 6]) => false
     {let ((expression?
	    [|lst| (equal? 3 (length lst))]))
       `{##if ,pred
	      ,{##if (expression? ifTrue)
		     (caddr ifTrue)
		     `{begin ,@(cddr ifTrue)}}
	      ,{##if (expression? ifFalse)
		     (caddr ifFalse)
		     `{begin ,@(cddr ifFalse)}}}}]}})




{libbug-internal#namespace ("lang#" with-test)}

;; with-test
;;   Collocates a definiton with a test.  The test is run at compile-time
;;   only.
(write-and-eval
 libbug-macros-file
 {define-macro with-test
   [|definition test|
    (eval
     `{begin
	,definition
	(if ,test
	    ['no-op]
	    [(pp "Test Failed")
	     (pp {quote ,test})
	     (pp (quote ,definition))
	     (error "Test Failed")])})
    ;;the actual macro expansion is just the definition
    definition]})

{libbug-internal#namespace ("lang#" with-tests)}
;; with-tests
;;   Collocates a definition with a collection of tests.  Tests are
;;   run sequentially, and are expected to return true or false
(write-and-eval
 libbug-macros-file
 {define-macro with-tests
   [|definition #!rest test|
    `{with-test ,definition {and ,@test}}]})



;; At compile time, we need to know where where certain files
;; will be located after they are installed.  For instace,
;; the subsequent function needs to know how to reference
;; the namespace scheme file.  This data currently is only
;; needed at compile-time
{at-compile-time
 {##include "config.scm"}}



;;Define a macro, both at macro-expansion time, and run-time.
;;Also write it out to libbug-macros.scm for use in other projects.

;;This code is not as easy to follow, and only works for macros
;;which are quasiquoted.  This needs to be rewritten.


(write-and-eval
 libbug-macros-file
 {define-macro libbug-internal#define-macro
   [|name lambda-value #!rest tests|
    {let ((augmented-lambda-value
	   (append (list 'lambda
			 (cadr lambda-value))
		   (list (cons 'quasiquote
			       (list
				(append
				 (cons '##let (cons (list)
						    (append
						     (list
						      `{##include "~~lib/gambit#.scm"}
						      `{##include ,(string-append bug-configuration#prefix
										  "/include/bug/libbug#.scm")})
						     (cdaddr lambda-value))))))))))
	  (newval lambda-value))
      (newline libbug-macros-file)
      (write `{define-macro
		,name
		,augmented-lambda-value}
	     libbug-macros-file)
      `{begin
	 {with-tests
	  {define-macro
	    ,name
	    ,lambda-value}
	  ,@tests}}}]})



;; aif
;;   anaphoric-if evaluates bool, binds it to the variable "it",
;;   which is accessible in body.
(libbug-internal#namespace ("lang#" aif))
;;(libbug-internal#namespace ("lang#" it))
{libbug-internal#define-macro
 aif
 [|bool body|
  `{let ((it ,bool))
     (if it
	 [,body]
	 [#f])}]
 (equal? {aif (+ 5 10) (* 2 it)}
	 30)
 (equal? {aif #f (* 2 it)}
	 #f)}

;; with-gensyms
;;   Utility for macros to minimize explicit use of gensym.
;;   Gensym creates a symbol at compile time which is guaranteed
;;   to be unique.  Macros which intentionally capture variables,
;;   such as aif, are the anomaly.
;;   Usually, variables local to a macro should not clash
;;   with variables local to the macro caller.
;;
{libbug-internal#namespace ("lang#" with-gensyms)}
{libbug-internal#define-macro
 with-gensyms
 [|symbols #!rest body|
  `{let ,(map [|symbol| `(,symbol {gensym})]
	      symbols)
     ,@body}]}


;; setf!
;;   Sets a value using its getter, as done in Common Lisp.
;;
;;   Implementation inspired by http://okmij.org/ftp/Scheme/setf.txt

;; this dummy structure is used in a test
{libbug-internal#namespace ("lang#" setf!)}
(write-and-eval
 libbug-macros-file
 {at-compile-time
  {define-structure foo bar baz}})

{libbug-internal#define-macro
 setf!
 [|get-expression val|
  (if (not (pair? get-expression))
      [`{set! ,get-expression ,val}]
      [{case (car get-expression)
	 ((car) `{set-car! ,@(cdr get-expression) ,val})
	 ((cdr) `{set-cdr! ,@(cdr get-expression) ,val})
	 ((cadr) `{setf! (car (cdr ,@(cdr get-expression))) ,val})
	 ((cddr) `{setf! (cdr (cdr ,@(cdr get-expression))) ,val})
	 ;; TODO - handle other atypical cases
	 (else `(,(string->symbol (string-append (symbol->string (car get-expression))
						 "-set!"))
		 ,@(cdr get-expression)
		 ,val))}])]
 ;; test variable
 {let ((a 5))
   {setf! a 10}
   (equal? a 10)}
 {begin
   {let ((a (make-foo 1 2)))
     {setf! (foo-bar a) 10}
     (equal? (make-foo 10 2)
	     a)}}
 ;; test car
 {let ((a (list 1 2)))
   {setf! (car a) 10}
   (equal? a '(10 2))}
 ;; test cdr
 {let ((a (list 1 2)))
   {setf! (cdr a) (list 10)}
   (equal? a '(1 10))}
 ;; test cadr
 {let ((a (list (list 1 2) (list 3 4))))
   {setf! (cadr a) 10}
   (equal? a '((1 2) 10))}
 ;; test cddr
 {let ((a (list (list 1 2) (list 3 4))))
   {setf! (cddr a) (list 10)}
   (equal? a '((1 2) (3 4) 10))}}



;; identity
;;   identity :: a -> a
;;
;;   Return the input
{libbug-internal#namespace ("lang#" identity)}
{with-test
 {define identity [|x| x]}
 (equal? "foo" (identity "foo"))}

;; noop
;;   noop :: () -> Symbol
;;
;;   Return the symbol 'noop. Useful when
;;   a procedure expects a procedure as an
;;   argument, but the caller has no need
;;   for worthwhile procedure to actually be
;;   called

{libbug-internal#namespace ("lang#" noop)}
{with-test
 {define noop  ['noop]}
 (equal? (noop) 'noop)}


;; all?

{libbug-internal#namespace ("lang#" all?)}
{at-both-times
 {define all?
   [|lst|
    {cond ((null? lst) #t)
	  ((not (car lst)) #f)
	  (else (all? (cdr lst)))}]}}


;; satisfies-relation
;;   satisfies-relation :: (a -> b) -> [(a,b)] -> Bool
;;
;;   For a given relation (i.e. function), and a
;;   list of 2-element lists, evaluatie whether the function
;;   when applied to the first element of the list
;;   evaluates to the second element of the list
;;
;;   Reference: http://en.wikipedia.org/wiki/Binary_relation
{libbug-internal#namespace ("lang#" satisfies-relation)}
{with-tests
 {define satisfies-relation
   [|fn list-of-pairs|
    (all? (map [|pair| {let ((independent-variable (car pair))
			     (dependent-variable (cadr pair)))
			 (equal? (fn independent-variable)
				 dependent-variable)}]
	       list-of-pairs))]}
 (satisfies-relation [|x| (+ x 1)]
		     `((0 1)
		       (1 2)
		       (2 3)))}


;; numeric-if
;;   numeric-if :: (Num a) =>  a -> Thunk -> Thunk -> Thunk
;;
;;   An if expression for numbers, based on their sign.
{libbug-internal#namespace ("lang#" numeric-if)}
{with-test
 {define numeric-if
   [|expr #!key (ifPositive noop) (ifZero noop)(ifNegative noop)|
    {cond ((> expr 0) (ifPositive))
	  ((= expr 0) (ifZero))
	  (else (ifNegative))}]}
 (satisfies-relation
  [|n|
   (numeric-if n
	       ifPositive: ['pos]
	       ifZero: ['zero]
	       ifNegative: ['neg])]
  `((5 pos)
    (0 zero)
    (-5 neg)))}


;; complement
;;   complement :: (a -> Bool) -> (a -> Bool)
;;
;;   Negates a predicate
{libbug-internal#namespace ("lang#" complement)}
{with-test
 {define complement
   [|f|
    [|#!rest args| (not (apply f args))]]}
 (satisfies-relation
  [|x| ((complement pair?) x)]
  `(
    (1 #t)
    ((1 2) #f)))}


;; while
;;   while :: Thunk -> Thunk -> Symbol
;;
;;   Imperative while loop.
{libbug-internal#namespace ("lang#" while)}
{with-tests
 {define while
   [|pred body|
    (if (pred)
	[(body)
	 (while pred body)]
	[(noop)])]}
 {let ((a 0))
   {begin
     (while [(< a 5)]
	    [(set! a (+ a 1))])
     (equal? a 5)}}}


;; copy
;;   copy :: [a] -> [a]
;;   Creates a copy of the list data structure, but does
{libbug-internal#namespace ("list#" copy)}
{with-tests
 {define copy
   [|l| (map identity l)]}
 (satisfies-relation
  copy
  `(
    ((1 2 3 4 5) (1 2 3 4 5))))}


;; proper?
;;   proper? :: [a] -> Bool
;;   Tests that the argument is a list that is properly
;;   termitated.
{libbug-internal#namespace ("list#" proper?)}
{with-tests
 {define proper?
   [|l| {cond ((null? l) #t)
	      ((pair? l) (proper? (cdr l)))
	      (else #f)}]}
 (satisfies-relation
  proper?
  `((4 #f)
    ((1 2) #t)
    ((1 2 . 5) #f)))}



;; reverse!
;;   reverse! :: [a] -> [a]
;;   reverses the list, possibly destructively.
{libbug-internal#namespace ("list#" reverse!)}
{with-tests
 {define reverse!
   [|lst|
    (if (null? lst)
	['()]
	[{let reverse! ((lst lst) (prev '()))
	   (if (null? (cdr lst))
	       [(set-cdr! lst prev)
		lst]
	       [{let ((rest (cdr lst)))
		  (set-cdr! lst prev)
		  (reverse! rest lst)}])}])]}
 (satisfies-relation
  reverse!
  `(
    (() ())
    ((1 2 3 4 5 6) (6 5 4 3 2 1))))}

;; first :: [a] -> Optional (() -> b) -> Either a b
;;   first returns the first element of the list, 'noop if the list is empty and no
;;   thunk is passed
{libbug-internal#namespace ("list#" first)}
{with-tests
 {define first
   [|lst #!key (onNull noop)|
    (if (null? lst)
	[(onNull)]
	[(car lst)])]}
 ;; test without the onNull handler
 (satisfies-relation
  first
  `(
    (() noop)
    ((1 2 3) 1)
    ((2 3 1 1 1) 2)))
 ;; test the onNull handler
 (satisfies-relation
  [|l| (first l onNull: [5])]
  `(
    (() 5)
    ((1 2 3) 1)))}

;; but-first :: [a] -> Optional (() -> b) -> Either [a] b
;;   but-first returns all of the elements of the list, except for the first
{libbug-internal#namespace ("list#" but-first)}
{with-tests
 {define but-first
   [|lst #!key (onNull noop)|
    (if (null? lst)
	[(onNull)]
	[(cdr lst)])]}
 (satisfies-relation
  but-first
  `(
    (() noop)
    ((1 2 3) (2 3))))
 (satisfies-relation
  [|l| (but-first l onNull: [5])]
  `(
    (() 5)))}

;;  last :: [a] -> Optional (() -> b) -> Either a b
;;    last returns the last element of the list
{libbug-internal#namespace ("list#" last)}
{with-tests
 {define last
   [|lst #!key (onNull noop)|
    (if (null? lst)
	[(onNull)]
	[{let last ((lst lst))
	   (if (null? (cdr lst))
	       [(car lst)]
	       [(last (cdr lst))])}])]}
 (satisfies-relation
  last
  `(
    (() noop)
    ((1) 1)
    ((1 2) 2)))
 (satisfies-relation
  [|l| (last l onNull: [5])]
  `(
    (() 5)
    ((1) 1)))}

;;  but-last :: [a] -> Optional (() -> b) -> Either [a] b
;;    but-last returns all but the last element of the list
{libbug-internal#namespace ("list#" but-last)}
{with-tests
 {define but-last
   [|lst #!key (onNull noop)|
    (if (null? lst)
	[(onNull)]
	[(reverse!
	  (but-first
	   (reverse! lst)))])]}
 (satisfies-relation
  but-last
  `(
    (() noop)
    ((1) ())
    ((1 2) (1))
    ((1 2 3) (1 2))))
 (satisfies-relation
  [|l| (but-last l onNull: [5])]
  `(
    (() 5)
    ((1) ())))}

;; filter
;;   filter :: (a -> Bool) -> [a] -> [a]
;;   return a new list, consisting only the elements where the predicate p?
;;   returns true
{libbug-internal#namespace ("list#" filter)}
{with-tests
 {define filter
   [|p? lst|
    (reverse!
     {let filter ((lst lst) (acc '()))
       (if (null? lst)
	   [acc]
	   [{let ((head (car lst)))
	      (filter (cdr lst)
		      (if (p? head)
			  [(cons head acc)]
			  [acc]))}])})]}
 (satisfies-relation
  [|l| (filter [|x| (not (= 4 (expt x 2)))]
	       l)]
  `(
    ((1 2 3 4 5 -2) (1 3 4 5))))}

;; remove
;;   remove :: a -> [a] -> [a]
;;   returns a new list with all occurances of x removed
{libbug-internal#namespace ("list#" remove)}
{with-tests
 {define remove
   [|x lst|
    (filter [|y| (not (equal? x y))]
	    lst)]}
 (satisfies-relation
  [|l| (remove 5 l)]
  `(
    ((1 5 2 5 3 5 4 5 5) (1 2 3 4))))}


;; fold-left
;;    fold-left :: (a -> b -> a) -> a -> [b] -> a
;;    reduce the list to a scalar by applying the reducing function repeatedly,
;;    starting from the "left" side of the list
{libbug-internal#namespace ("list#" fold-left)}
{with-tests
 {define fold-left
   [|fn initial lst|
    {let fold-left ((acc initial) (lst lst))
      (if (null? lst)
	  [acc]
	  [(fold-left (fn acc
			  (car lst))
		      (cdr lst))])}]}
 (satisfies-relation
  [|l| (fold-left + 0 l)]
  `(
    (() 0)
    ((1) 1)
    ((1 2) 3)
    ((1 2 3 4 5 6) 21)))}

;; scan-left :: (a -> b -> a) -> a -> [b] -> [a]
;;   scan-left is like fold-left, but every intermediate value
;;   of fold-left's acculumalotr is put onto a list, which
;;   is the value of scan-left
{libbug-internal#namespace ("list#" scan-left)}
{with-tests
 {define scan-left
   [|fn initial lst|
    {let scan-left ((acc-list (list initial)) (lst lst))
      (if (null? lst)
	  [(reverse! acc-list)]
	  [{let ((newacc (fn (first acc-list)
			     (car lst))))
	     (scan-left (cons newacc acc-list)
			(cdr lst))}])}]}
 (satisfies-relation
  [|l| (scan-left + 0 l)]
  `(
    (() (0))
    ((1 1 1 2 20 30) (0 1 2 3 5 25 55))))}



;; fold-right
;;    fold-right :: (b -> a -> a) -> a -> [b] -> a
;;    reduce the list to a scalar by applying the reducing function repeatedly,
;;    starting from the "right" side of the list
{libbug-internal#namespace ("list#" fold-right)}
{with-tests
 {define fold-right
   [|fn initial lst|
    {let fold-right ((acc initial) (lst lst))
      (if (null? lst)
	  [acc]
	  [(fn (car lst)
	       (fold-right acc (cdr lst)))])}]}
 (satisfies-relation
  [|l| (fold-right - 0 l)]
  `(
    (() 0)
    ((1 2 3 4) -2)
    ((2 2 5 4) 1)))}

;; flatmap
;;   flatmap :: (a -> [b]) -> [a] -> [b]
{libbug-internal#namespace ("list#" flatmap)}
{with-tests
 {define flatmap
   [|fn lst|
    (fold-left append '() (map fn lst))]}
 (satisfies-relation
  [|l| (flatmap [|x| (list x x x)]
		l)]
  `(
    ((1) (1 1 1))
    ((1 2) (1 1 1 2 2 2))
    ((1 2 3) (1 1 1 2 2 2 3 3 3))))
 (satisfies-relation
  [|l| (flatmap [|x| (list x
			   (+ x 1)
			   (+ x 2))]
		l)]
  `(
    ((10 20) (10 11 12 20 21 22))))}

;; enumerate-interval
;;   enumerate-interval :: (Num a) => a -> a -> Optional a -> a
{libbug-internal#namespace ("list#" enumerate-interval)}
{with-tests
 {define enumerate-interval
   [|low high #!key (step 1)|
    (if (> low high)
	['()]
	[(cons low (enumerate-interval (+ low step) high step: step))])]}
 (equal? (enumerate-interval 1 10)
	 '(1 2 3 4 5 6 7 8 9 10))
 (equal? (enumerate-interval 1 10 step: 2)
	 '(1 3 5 7 9))}

;; iota - from common lisp
;;   iota :: (Num a) => a -> Optional a -> Optional a -> a
{libbug-internal#namespace ("list#" iota)}
{with-tests
 {define iota
   [|n #!key (start 0) (step 1)|
    (enumerate-interval start n step: step)]}
 (equal? (iota 5 start: 0)
	 '(0 1 2 3 4 5))
 (equal? (iota 5 start: 2 step: (/ 3 2))
	 '(2 7/2 5))}


;; permutations
;;   permutations :: [a] -> [[a]]
;;   returns all permutations of the list
{libbug-internal#namespace ("list#" permutations)}
{with-tests
 {define permutations
   [|lst|
    (if (null? lst)
	['()]
	[{let permutations ((lst lst))
	   (if (null? lst)
	       [(list '())]
	       [(flatmap [|x|
			  (map [|y| (cons x y)]
			       (permutations (remove x lst)))]
			 lst)])}])]}
 (satisfies-relation
  permutations
  `(
    (() ())
    ((1) ((1)))
    ((1 2) ((1 2)
	    (2 1)))
    ((1 2 3) ((1 2 3)
	      (1 3 2)
	      (2 1 3)
	      (2 3 1)
	      (3 1 2)
	      (3 2 1)))))}

;; sublists
;;   sublists :: [a] -> [[a]]
;;   Returns a list of every sub-list
{libbug-internal#namespace ("list#" sublists)}
{with-tests
 {define sublists
   [|lst|
    (if (null? lst)
	['()]
	[(cons lst (sublists (cdr lst)))])]}
 (satisfies-relation
  sublists
  `(
    (() ())
    ((1) ((1)))
    ((1 2) ((1 2) (2)))
    ((1 2 3) ((1 2 3) (2 3) (3)))))}


{libbug-internal#namespace ("lang#" compose)}
{with-tests
 {define compose
   [|#!rest fns|
    [|#!rest args|
     (if (null? fns)
	 [(apply identity args)]
	 [(fold-right [|fn acc| (fn acc)]
		      (apply (last fns) args)
		      (but-last fns))])]]}
 (equal? ((compose) 5)
	 5)
 (equal? ((compose [|x| (* x 2)])
	  5)
	 10)
 (equal? ((compose [|x| (+ x 1)]
		   [|x| (* x 2)])
	  5)
	 11)
 (equal? ((compose [|x| (/ x 13)]
		   [|x| (+ x 1)]
		   [|x| (* x 2)])
	  5)
	 11/13)}


{libbug-internal#namespace ("stream#" stream-cons)}
{libbug-internal#define-macro
 stream-cons
 [|a b|
  `(cons ,a {delay ,b})]
 {begin
   {let ((s {stream-cons 1 2}))
     {and
      (equal? (car s)
	      1)
      (equal? {force (cdr s)}
	      2)}}}}


{libbug-internal#namespace ("stream#" stream-car)}
{with-tests
 {define stream-car car}
 {let ((s {stream-cons 1 2}))
   (equal? (stream-car s)
	   1)}}

{libbug-internal#namespace ("stream#" stream-cdr)}
{with-tests
 {define stream-cdr
   [|s| {force (cdr s)}]}
 {let ((s {stream-cons 1 2}))
   (equal? (stream-cdr s)
	   2)}}



{libbug-internal#namespace ("stream#" stream-ref)}
{with-tests
 {define stream-ref
   [|s n #!key (onOutOfBounds noop)|
    {define refPrime
      [|s n|
       (if (equal? n 0)
	   [(stream-car s)]
	   [(if (not (null? (stream-cdr s)))
		[(refPrime (stream-cdr s) (- n 1))]
		[(onOutOfBounds)])])]}
    (if (< n 0)
	[(onOutOfBounds)]
	[(refPrime s n)])]}
 {let ((s {stream-cons 5
		       {stream-cons 4
				    {stream-cons 3
						 {stream-cons 2
							      {stream-cons 1 '()}}}}}))
   (all?
    (list
     (equal? (stream-ref s -1)
	     'noop)
     (equal? (stream-ref s 0)
	     5)
     (equal? (stream-ref s 4)
	     1)
     (equal? (stream-ref s 5)
	     'noop)
     (equal? (stream-ref s 5 onOutOfBounds: ['out])
	     'out)))}}



;;  clear the namespace of the macro file
(at-compile-time
 (begin
   (display
    "
(##namespace (\"\"))"
    libbug-macros-file)))


(at-compile-time
 (begin
   (force-output libbug-headers-file)
   (close-output-port libbug-headers-file)
   (force-output libbug-macros-file)
   (close-output-port libbug-macros-file)))
