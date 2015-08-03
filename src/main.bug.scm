;; Copyright 2014,2015 - William Emerison Six
;; All rights reserved
;; Distributed under LGPL 2.1 or Apache 2.0
;;
;; INTRODUCTION ----------------------------------------------------------------
;;
;; BUG is Bill's Utilities for Gambit-C.  BUG provides a concise syntax for
;; lambdas,  utilities for general-purpose evaluation at compile-time, a
;; compile-time unit test framework, and a collection of utility functions that
;; I find useful.  Taken together, these can be used in a "literate programming"
;; style.
;;
;; PREREQUISITES ---------------------------------------------------------------
;;
;; The reader is assumed to be familiar with Scheme, and with Common  Lisp-style
;; macros (which Gambit-C provides).  Suggested reading is "The Structure and
;; Interpretation of Computer Programs" by Sussman and Abelson, "ANSI Common
;; Lisp" by Paul Graham, and "On Lisp" by Paul Graham.  Many ideas in BUG are
;; inspired by those books.
;;
;; LANGUAGE DEFINITIONS -------------------------------------------------------
;;
;; BUG defines quite a few extensions to the Scheme language, implemented via
;; macros.  Rather than overwhelming the reader with the details of the
;; implementanion, the reader is encouraged to defer reading
;; "bug-language.bug.scm" until the rest of this file is read, as I will
;; explain the language incrementally.

(include "bug-language.scm")

;; MAIN  ----------------------------------------------------------------------
;;
;; The first definition is "noop", a procedure which takes no arguments, and
;; only returns the symbol 'noop.  noop is defined using "libbug#define"
;; instead of Scheme's regular define.

{libbug#define              ; (1)
 "lang#"                    ; (2)
 noop                       ; (3)
 ['noop]                    ; (4)
 (equal? (noop) 'noop)}     ; (5)
;; (1) the libbug#define macro form bug-language.bug.scm is invoked.
;;
;; (2) a namespace is declared
;;
;; (3), the variable name is declared, which will be declared in the
;; namespace defined on (2).  Because BUG is a library, and these procedures
;; will be exported, libbug#define not only creates the variable in the
;; namespace defined by (2), but it also writes the namespace definition to
;; "libbug#.scm" during compiliation, so that external programs may use these
;; namespaces.  The alert reader may ask, "what? BUG writes a string to a file
;; during _compile time_????"  Yes, BUG defines general purpose computation,
;; including IO, at compile time.
;;
;; (4), the value to be stored into the variable is declared.  BUG
;; includes a Scheme preprocessor "bug-gscpp", which expands lambda literals
;; into lambdas.  In this case "['noop]" is expanded into "(lambda () 'noop)"
;;
;; (5), an expression which returns a boolean is defined.  This is a
;; test which will be evaluated at compile-time, and should the test fail,
;; the build process will fail and no shared library will be created.  The
;; test runs at compile time, but is not present in the resulting shared
;; library.

{libbug#define
 "lang#"
 identity
 [|x| x]                   ; (1)
 (equal? "foo" (identity "foo"))}
;; (1) "bug-gscpp" expands "[|x| x]" to "(lambda (x) x)".  This expansion
;; works with multiple arguments, as long as they are between the '|'s.


;; Kind of like and?, but takes a list instead of a var-args
{libbug#define
 "list#"
 all?
 [|lst|
  (if (null? lst)                ; (1)
      [#t]
      [(if (not (car lst))
	  [#f]
	  [(all? (cdr lst))])])]
 (all? '())
 (all? '(1))                     ; (2)
 (all? '(#t))
 (all? '(#t #t))
 (not (all? '(#f)))
 (not (all? '(#t #t #t #f)))
 }
;; (1) if, which is currently namespaced to lang#if, takes lambda expressions
;; for the two parameters. I like to think of #t, #f, and if as the following:
;;     (define #t [|t f| (t)])
;;     (define #f [|t f| (f)])
;;     (define lang#if [|b t f| (b t f)])
;; As such, if would not be a special form, and is more consistent with the
;; rest of BUG.
;; (2)  libbug#define can take more than one test as parameters



;; Since libbug#define can take multiple tests, I'd rather not invoke
;; the prodcedure under test by name repeatedly.  Instead, I'd like to define
;; the procedure, and input the list of pairs of inputs with expected outputs.
;; Writing tests in this style also informs the reader that the function under
;; test is likely side-effect free.
{libbug#define
 "lang#"
 satisfies-relation
 [|fn list-of-pairs|
  (all? (map [|pair| {let ((independent-variable (car pair))
			   (dependent-variable (cadr pair)))
		       (equal? (fn independent-variable)
			       dependent-variable)}]
	     list-of-pairs))]
 (satisfies-relation [|x| (+ x 1)]
		     `(
		       (0 1)
		       (1 2)
		       (2 3)
		       ))}


;; BUG also provides a new procedure for creating macros.  Just as libbug#define
;; exports the namespace to a file during compilation time, libbug#define-macro
;; exports the namespace to "libbug#.scm", and also exports the definition of
;; the macro to "libbug-macros.scm" during compile time.  Since external
;; projects will actually load those macros as input files, much care was needed
;; in defining libbug#define-macro to ensure that the macros work externally in
;; the same manner as they work in this file.  The details of how this works
;; outside the current scope; it is defined in "bug-language.bug.scm"

;; aif evaluates bool, binds it to the variable "it", which is accessible in
;; body.
{libbug#define-macro
 "lang#"
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

;; I've now explained everything about the BUG extensions to the language!
;; I will not document the purpose of the procedures below if the test does
;; an adequate job of demonstrating the purpose of the code.




{libbug#define
"lang#"
 complement
 [|f|
  [|#!rest args| (not (apply f args))]]
 (satisfies-relation
  (complement pair?)
  `(
    (1 #t)
    ((1 2) #f)
    ))}




;;   Creates a copy of the list data structure
{libbug#define
 "list#"
 copy
 [|l| (map identity l)]
 (satisfies-relation
  copy
  `(
    ((1 2 3 4 5) (1 2 3 4 5))
    ))}


;;   Tests that the argument is a list that is properly
;;   termitated.
{libbug#define
 "list#"
 proper?
 [|l| {cond ((null? l) #t)
	    ((pair? l) (proper? (cdr l)))
	    (else #f)}]
 (satisfies-relation
  proper?
  `(
    (4 #f)
    ((1 2) #t)
    ((1 2 . 5) #f)
    ))}



;;   reverses the list quickly by reusing cons cells
{libbug#define
 "list#"
 reverse!
 [|lst|
  (if (null? lst)
      ['()]
      [{let reverse! ((lst lst) (prev '()))
	 (if (null? (cdr lst))
	     [(set-cdr! lst prev)
	      lst]
	     [{let ((rest (cdr lst)))
		(set-cdr! lst prev)
		(reverse! rest lst)}])}])]
 (satisfies-relation
  reverse!
  `(
    (() ())
    ((1 2 3 4 5 6) (6 5 4 3 2 1))
    ))}

;;   first returns the first element of the list, 'noop if the list
;;   is empty and no thunk is passed
{libbug#define
 "list#"
 first
 [|lst #!key (onNull noop)|
  (if (null? lst)
      [(onNull)]
      [(car lst)])]
 ;; test without the onNull handler
 (satisfies-relation
  first
  `(
    (() noop)
    ((1 2 3) 1)
    ((2 3 1 1 1) 2)
    ))
 ;; test the onNull handler
 (satisfies-relation
  [|l| (first l onNull: [5])]
  `(
    (() 5)
    ((1 2 3) 1)
    ))}

;;   but-first returns all of the elements of the list, except for the first
{libbug#define
 "list#"
 but-first
 [|lst #!key (onNull noop)|
  (if (null? lst)
      [(onNull)]
      [(cdr lst)])]
 (satisfies-relation
  but-first
  `(
    (() noop)
    ((1 2 3) (2 3))
    ))
 (satisfies-relation
  [|l| (but-first l onNull: [5])]
  `(
    (() 5)
    ))}

;;    last returns the last element of the list
{libbug#define
 "list#"
 last
 [|lst #!key (onNull noop)|
  (if (null? lst)
      [(onNull)]
      [{let last ((lst lst))
	 (if (null? (cdr lst))
	     [(car lst)]
	     [(last (cdr lst))])}])]
 (satisfies-relation
  last
  `(
    (() noop)
    ((1) 1)
    ((1 2) 2)
    ))
 (satisfies-relation
  [|l| (last l onNull: [5])]
  `(
    (() 5)
    ((1) 1)
    ))}

;;    but-last returns all but the last element of the list
{libbug#define
 "list#"
 but-last
 [|lst #!key (onNull noop)|
  (if (null? lst)
      [(onNull)]
      [(reverse!
	(but-first
	 (reverse! lst)))])]
 (satisfies-relation
  but-last
  `(
    (() noop)
    ((1) ())
    ((1 2) (1))
    ((1 2 3) (1 2))
    ))
 (satisfies-relation
  [|l| (but-last l onNull: [5])]
  `(
    (() 5)
    ((1) ())
    ))}

;;   return a new list, consisting only the elements where the predicate p?
;;   returns true
{libbug#define
 "list#"
 filter
 [|p? lst|
  (reverse!
   {let filter ((lst lst) (acc '()))
     (if (null? lst)
	 [acc]
	 [{let ((head (car lst)))
	    (filter (cdr lst)
		    (if (p? head)
			[(cons head acc)]
			[acc]))}])})]
 (satisfies-relation
  [|l| (filter [|x| (not (= 4 (expt x 2)))]
	       l)]
  `(
    ((1 2 3 4 5 -2) (1 3 4 5))
    ))}

;;   returns a new list with all occurances of x removed
{libbug#define
 "list#"
 remove
 [|x lst|
  (filter [|y| (not (equal? x y))]
	  lst)]
 (satisfies-relation
  [|l| (remove 5 l)]
  `(
    ((1 5 2 5 3 5 4 5 5) (1 2 3 4))
    ))}


;;    reduce the list to a scalar by applying the reducing function repeatedly,
;;    starting from the "left" side of the list
{libbug#define
 "list#"
 fold-left
 [|fn initial lst|
  {let fold-left ((acc initial) (lst lst))
    (if (null? lst)
	[acc]
	[(fold-left (fn acc
			(car lst))
		    (cdr lst))])}]
 (satisfies-relation
  [|l| (fold-left + 0 l)]
  `(
    (() 0)
    ((1) 1)
    ((1 2) 3)
    ((1 2 3 4 5 6) 21)
    ))}

;;   scan-left is like fold-left, but every intermediate value
;;   of fold-left's acculumalotr is put onto a list, which
;;   is the value of scan-left
{libbug#define
 "list#"
 scan-left
 [|fn initial lst|
  {let scan-left ((acc-list (list initial)) (lst lst))
    (if (null? lst)
	[(reverse! acc-list)]
	[{let ((newacc (fn (first acc-list)
			   (car lst))))
	   (scan-left (cons newacc acc-list)
		      (cdr lst))}])}]
 (satisfies-relation
  [|l| (scan-left + 0 l)]
  `(
    (() (0))
    ((1 1 1 2 20 30) (0 1 2 3 5 25 55))
    ))}



;;    reduce the list to a scalar by applying the reducing function repeatedly,
;;    starting from the "right" side of the list
{libbug#define
 "list#"
 fold-right
 [|fn initial lst|
  {let fold-right ((acc initial) (lst lst))
    (if (null? lst)
	[acc]
	[(fn (car lst)
	     (fold-right acc (cdr lst)))])}]
 (satisfies-relation
  [|l| (fold-right - 0 l)]
  `(
    (() 0)
    ((1 2 3 4) -2)
    ((2 2 5 4) 1)
    ))}

;;  map a prodecure to a list, but the result of the
;;  prodecure will be a list itself.  Aggregate all
;;  of those lists together
{libbug#define
 "list#"
 flatmap
 [|fn lst|
  (fold-left append '() (map fn lst))]
 (satisfies-relation
  [|l| (flatmap [|x| (list x x x)]
		l)]
  `(
    ((1) (1 1 1))
    ((1 2) (1 1 1 2 2 2))
    ((1 2 3) (1 1 1 2 2 2 3 3 3))
    ))
 (satisfies-relation
  [|l| (flatmap [|x| (list x
			   (+ x 1)
			   (+ x 2))]
		l)]
  `(
    ((10 20) (10 11 12 20 21 22))
    ))}

;;  I think the tests explain it
{libbug#define
 "list#"
 enumerate-interval
 [|low high #!key (step 1)|
  (if (> low high)
      ['()]
      [(cons low (enumerate-interval (+ low step) high step: step))])]
 (equal? (enumerate-interval 1 10)
	 '(1 2 3 4 5 6 7 8 9 10))
 (equal? (enumerate-interval 1 10 step: 2)
	 '(1 3 5 7 9))}

;; iota - from common lisp
{libbug#define
 "list#"
 iota
 [|n #!key (start 0) (step 1)|
  (enumerate-interval start n step: step)]
 (equal? (iota 5 start: 0)
	 '(0 1 2 3 4 5))
 (equal? (iota 5 start: 2 step: (/ 3 2))
	 '(2 7/2 5))}



;;   returns all permutations of the list
{libbug#define
 "list#"
 permutations
 [|lst|
  (if (null? lst)
      ['()]
      [{let permutations ((lst lst))
	 (if (null? lst)
	     [(list '())]
	     [(flatmap [|x|
			(map [|y| (cons x y)]
			     (permutations (remove x lst)))]
		       lst)])}])]
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
	      (3 2 1)))
    ))}

;;   Returns a list of every sub-list
{libbug#define
 "list#"
 sublists
 [|lst|
  (if (null? lst)
      ['()]
      [(cons lst (sublists (cdr lst)))])]
 (satisfies-relation
  sublists
  `(
    (() ())
    ((1) ((1)))
    ((1 2) ((1 2) (2)))
    ((1 2 3) ((1 2 3) (2 3) (3)))
    ))}


;; Inverse of list-ref
{libbug#define 
 "list#"
 ref-of
 [|lst x #!key (onMissing noop)|
  (if (null? lst)
      [(onMissing)]
      [{let ref-of ((lst lst) (acc 0))
	 (if (equal? (car lst) x)
	     [acc]
	     [(if (null? (cdr lst))
		  [(onMissing)]
		  [(ref-of (cdr lst) (+ acc 1))])])}])]
 (satisfies-relation
  [|x| (ref-of '(a b c d e f g) x)]
  `(
    (z noop)
    (a 0)
    (b 1)
    (g 6)
    ))
 (satisfies-relation
  [|x| (ref-of '(a b c d e f g)
		    x
		    onMissing: ['missing])]
  `(
    (z missing)
    (a 0)
    ))}


{libbug#define 
 "list#"
 partition
 [|lst pred?|
  {let partition ((lst lst)
		  (falseList '())
		  (trueList '()))
    (if (null? lst)
	[(list trueList falseList)]
	[(if (pred? (car lst))
	     [(partition (cdr lst)
			 falseList
			 (cons (car lst) trueList))]
	     [(partition (cdr lst)
			 (cons (car lst) falseList)
			 trueList)])])}]
 (satisfies-relation
  [|lst| (let* ((p (partition lst [|x| (<= x 3)]))
		(lesser (car p))
		(greater (cadr p)))
	   (list lesser greater))]
  `(
    (() (()
	 ()))
    ((3 2 5 4 1) ((1 2 3)
		  (4 5)))
    ))}


{libbug#define 
 "list#"
 append!
 [|lst x|
  (if (null? lst)
      [x]
      [(let ((head lst))
	 (let append! ((lst lst))
	   (if (null? (cdr lst))
	       [(set-cdr! lst x)]
	       [(append! (cdr lst))]))
	 head)])]
 (equal? (append! '() (list 5)) (list 5))
 (equal? (append! '(1 2 3) (list 5)) (list 1 2 3 5))
 {let ((a '(1 2 3)))
   (append! a (list 5))
   (not (equal? (list 1 2 3) a))}
 }


{libbug#define
 "list#"
 sort
 [|lst comparison|
  (if (null? lst)
      ['()]
      [{let* ((current-node (car lst)))
	 (let* ((p (partition (cdr lst)
			      [|x| (comparison x
					       current-node)]))
		(less-than (car p))
		(greater-than (cadr p)))
	   (append! (sort less-than
			  comparison)
		    (cons current-node
			  (sort greater-than
				comparison))))}])]
 (satisfies-relation
  [|lst| (sort lst <)]
  `(
    (() ())
    ((1 3 2 5 4 0) (0 1 2 3 4 5))
    ))}

;;  Apply a series of functions to an input.  Much
;;  like the . operator in math
{libbug#define
 "lang#"
 compose
 [|#!rest fns|
  [|#!rest args|
   (if (null? fns)
       [(apply identity args)]
       [(fold-right [|fn acc| (fn acc)]
		    (apply (last fns) args)
		    (but-last fns))])]]
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

{libbug#define-macro
 "stream#"
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


{libbug#define
 "stream#"
 stream-car
 car
 {let ((s {stream-cons 1 2}))
   (equal? (stream-car s)
	   1)}}

{libbug#define
 "stream#"
 stream-cdr
 [|s| {force (cdr s)}]
 {let ((s {stream-cons 1 2}))
   (equal? (stream-cdr s)
	   2)}}



{libbug#define
 "stream#"
 stream-ref
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
      [(refPrime s n)])]
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


;; setf!
;;   Sets a value using its getter, as done in Common Lisp.
;;
;;   Implementation inspired by http://okmij.org/ftp/Scheme/setf.txt

;; this dummy structure is used in a test
{at-compile-time
 {define-structure foo bar baz}}

{libbug#define-macro
 "lang#"
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





;; with-gensyms
;;   Utility for macros to minimize explicit use of gensym.
;;   Gensym creates a symbol at compile time which is guaranteed
;;   to be unique.  Macros which intentionally capture variables,
;;   such as aif, are the anomaly.
;;   Usually, variables local to a macro should not clash
;;   with variables local to the macro caller.
;;
{libbug#define-macro
 "lang#"
 with-gensyms
 [|symbols #!rest body|
  `{let ,(map [|symbol| `(,symbol {gensym})]
	      symbols)
     ,@body}]}


;; Sometimes you need an imperative loop
{libbug#define
 "lang#"
 while
 [|pred body|
  (if (pred)
      [(body)
       (while pred body)]
      [(noop)])]
 {let ((a 0))
   (while [(< a 5)]
	  [(set! a (+ a 1))])
   (equal? a 5)}}

;;   An if expression for numbers, based on their sign.
{libbug#define
 "lang#"
 numeric-if
 [|expr #!key (ifPositive noop) (ifZero noop)(ifNegative noop)|
  {cond ((> expr 0) (ifPositive))
	((= expr 0) (ifZero))
	(else (ifNegative))}]
 (satisfies-relation
  [|n|
   (numeric-if n
	       ifPositive: ['pos]
	       ifZero: ['zero]
	       ifNegative: ['neg])]
  `(
    (5 pos)
    (0 zero)
    (-5 neg)
    ))}


(include "bug-language-end.scm")
