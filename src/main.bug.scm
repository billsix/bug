
;; Copyright 2014,2015 - William Emerison Six
;; All rights reserved
;; Distributed under LGPL 2.1 or Apache 2.0
;;
;; INTRODUCTION ----------------------------------------------------------------------
;;
;; BUG is Bill's Utilities for Gambit-C.  BUG provides a concise syntax for lambdas,
;; utilities for general-purpose evaluation at compile-time, a compile-time unit test
;; framework, and a collection of utility functions that I find useful.  Taken together,
;; these can be used in a "literate programming" style, as most of BUG is contained
;; within this file.
;;
;; PREREQUISITES ---------------------------------------------------------------------
;;
;; The reader is assumed to be familiar with Scheme, and with Common  Lisp-style
;; macros (which Gambit-C provides).  Suggested reading is "The Structure and
;; Interpretation of Computer Programs" by Sussman and Abelson, "ANSI Common Lisp"
;; by Paul Graham, and "On Lisp" by Paul Graham.  Many ideas in BUG are inspired by
;; those books.
;;
;; LAMBDA SYNTAX ---------------------------------------------------------------------
;;
;; BUG provides a literal syntax for lambdas.  BUG converts
;;
;;      [x] into (lambda () x)
;;             and
;;      [|x y ...| (z x y ...)] into (lambda (x y ...) (z x y ...))
;;
;; This syntax serves two purposes; to minimize the need for creating macros
;; when creating a function would suffice, and as such, make clear whether
;; expressions passed as parameters are evaluated once only, or whether it may
;; be evaluated zero or more times.
;;
;; For instance, in "ANSI Common Lisp" on page 154, a macro for "while" is
;; defined.
;;
;; (defmacro while (test &body body)
;;   `(do ()
;;        ((not ,test))
;;      ,@body))
;;
;; An example of usage of the while
;;  (let ((a 0))
;;     (while (< a 5)
;;            (incf a))
;;      a)
;;   => 5
;;
;; In BUG, it would look like this:
;;
;; {define while
;;   [|pred body|
;;    (if (pred)
;;        [(body)
;; 	   (while pred body)]
;;        [(noop)])]}
;;
;; {let ((a 0))
;;     (while [(< a 5)]
;;	      [(set! a (+ a 1))])
;;     a}}
;;   => 5
;;
;; "bug-gscpp" is the program which does the expansion of the lambda literals,
;; "bug-gsi" is an interpreter for BUG code, the equivalent of "gsi".  "bug-gsi"
;; provides no interactive help for inputting commands, but such functionality
;; can be had via using Emacs, or running "rlwrap bug-gsi".
;;
;; Also, note that in Gambit-C, "{}" may be used anywhere where a programmer may
;; use "()".  In BUG, I use "{foo bar baz}" anywhere where "foo" is a macro and the
;; evaluation does not follow typical Scheme evaluation rulse.  (In this case, evaluate
;; "foo" "bar" and "baz" in any order, and apply "foo" to "bar baz").
;;
;; BUG INFRASTRUCTURE INTRODUCTION -----------------------------------------------------
;;
;; Since BUG is a library, I need to create and export macros, namespaces, data, types,
;; and functions.  The following section of code provides the infrastructure necessary
;; to export these.
;;
;; First, I define "at-compile-time", a macro which ensures that the code evaluates
;; at compile-time only;
;;
;; For instance, if uncommented, the following code
;;
;;   {at-compile-time (pp 5)}
;;
;;   would print 5 at compile time, but would not execute at runtime.
;;
;; Second, I create "at-both-times", which like "at-compile-time", executes at compile
;; time, but also at run-time.
;;
;; Third, at compile time, I create two files, "libbug#.scm" and "libbug-macros.scm".
;; These files are to be used by external programs which wish to use code from BUG.
;; "libbug#.scm" will contain all of the namespace definitions, and "libbug-macros.scm"
;; will contain all of the macros exported from this file.
;;
;; Fourth, I create custom functions to define functions and macros, which allow
;; definitions within the library and which exports them to the aforementioned files.
;; These are called "libbug#define-macro" and "libbug#define",
;; to convey that these macros are not exported to external programs.
;;
;; Fifth, I create a macro "lang#if", which takes lambdas.  So (if 5 [1] [2]) instead of
;; (if 5 1 2).
;;
;; Six, a "with-tests" macro, which allows definitions to be collocated with the
;; tests which test the definition, which executes only at compile-time, and if
;; failure occurs, no executable is produced.
;;
;; The reader may skip over reading the implemenation, and skip straight to the
;; "MAIN" section.
;;
;;
;; BUG INFRASTRUCTURE  -------------------------------------------------------------
;;
;; I use Gambit's namespaces for all of BUG's code.  From what I understand of them,
;; namespaces instruct Gambit's reader on how it should associate a given string
;; which it has read in into an internal symbol.  The following line indicates
;; that all further symbols read in should have "libbug#" prefixed to them, unless
;; the symbol itself has a "##" prefix.  I put it in here with the intention
;; of avoiding the pollution of the global namespace.  All subsequent functions
;; and macros should be explicitly namespaced, but if not, they will be namespaced
;; as the following.


{namespace ("libbug#")}



;; That's great as a mechanism to minimize namespace collisions with other Gambit
;; projects, but I still want to be able to reference Scheme procedures.  If
;; I were to uncomment the following line
;;
;; (define baz (+))
;;
;; I would get the following warnings
;;
;;  *** WARNING -- "libbug#+" is not defined,
;;  ***            referenced in: ("/home/wsix/opt/bug/src/main.c")
;;  *** WARNING -- "libbug#baz" is not defined,
;;  ***            referenced in: ("/home/wsix/opt/bug/src/main.c")
;;  *** WARNING -- "libbug#define" is not defined,
;;  ***            referenced in: ("/home/wsix/opt/bug/src/main.c")

;;
;; These warnings appear at compile time, because we specified that the current
;; namespace is "libbug#".  So after Gambit reads it in, it prefixes "libbug#"
;; to each symbol before Gambit evaluates it.
;;
;; By including the following, all of the definitions which Gambit provides
;; will be used, without a "libbug#" prefix.


(##include "~~lib/gambit#.scm")


;; Within BUG, all of the functions and macros should have a namespace
;; associated with them.  I use "lang#" for basic language procedures, "list#"
;; for lists, etc.
;;
;; The aforementioned "at-compile-time" macro is implemented by "eval"ing code
;; during macro-expansion.
;;
;; https://mercure.iro.umontreal.ca/pipermail/gambit-list/2012-April/005917.html
;;

{namespace ("lang#" at-compile-time)}
{define-macro at-compile-time
  [|form|
   (eval form)
   `{quote noop}]} ;; noop is just a symbol, the compiler shouldn't do anything
                   ;; of value with it



{##namespace ("lang#" at-both-times)}
{define-macro at-both-times
  [|form|
   (eval form)       ;; evaluation (1) in the expansion-time environment
   `(begin
      (eval ',form)  ;; evaluation (2) in the expansion-time environment
                     ;;   of the run-time environment
      ,form)]}       ;; evaluation (3) in the run-time environment




;; BUG is a collection of procedures and macros.  Building bug results
;; in a shared library and a "loadable" library (as in (load "foo.o1").
;;
;; Macro definitions and namespace declarations, however do not reside
;; in such libraries.  I intend to keep the vast majority of BUG code
;; in this one file (minus the C preprocessor, gsi interpreter glue,
;; and build files).  As such, I don't want to define the namespaces
;; or macros definitions in a different file.
;;
;; "at-compile-time" allows us to execute arbitrary code at compile time,
;; so why not open files and write to them during compile time?
;;
;; Open one file for the namespaces, "libbug#.scm", and one for the macros,
;; "libbug-macros.scm"  These files will be pure Gambit scheme code, no
;; BUG-syntax enhancements, and they are not intended to be read by
;; a person.  Their documentation is in this file.
;;
;; The previous two macros are also written to the libbug-macros.scm file,
;; and a reference from libbug-macros.scm to libbug#.scm is made, so
;; a person can now assume that the files must be collocated.
;;
;; At the end of this document, the files are closed during compile time.



{at-compile-time
 {begin
   ;; file for namespaces
   {define libbug-headers-file
     (open-output-file '(path:
			 "libbug#.scm"
			 append:
			 #f))}
   (display
    ";; Copyright 2014,2015 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.1 or Apache 2.0
{##namespace (\"lang#\" at-compile-time)}
{##namespace (\"lang#\" at-both-times)}"
    libbug-headers-file)

   ;; file for macros
   {define libbug-macros-file
     (open-output-file '(path:
			 "libbug-macros.scm"
			 append:
			 #f))}
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
   `(begin
      (eval ',form)
      ,form)]}"
    libbug-macros-file)}}




;; Now that those files are open, I want to write to them.  Namespaces
;; to libbug#.scm, and macros to libbug-macros.scm.  However, I don't want
;; to have to duplicate the code for each context, like I just did for
;; the previous two macros.
;;
;; So, create a new line on the file, write the unevaluated form to the
;; file (I'm not quite sure why I need to eval the port, but it works),
;; and the return the form so that the compiler actually processes it.


{define-macro write-and-eval
  [|port form|
   (newline (eval port))
   (write form (eval port))
   form]}



;; Although I'm not quite sure if namespaces work correctly at compile
;; time, I'm going to namespace every function/macro at compile-time,
;; at run time, and in the libbug-headers file.

;; In the following, I define a new version of "if".  I prefer how
;; Smalltalk 80 defines an if expression as compared to how Scheme
;; and common Lisp do.  Scheme and Common Lisp have special evaluation
;; rules for if.   true and false could be represented as procedures,
;; with an if function which would just apply the boolean procedure to
;; the ifTrue and ifFalse procedures
;;
;;

{at-compile-time
 {namespace ("lang#" if)}}
{write-and-eval
 libbug-headers-file
 {namespace ("lang#" if)}}

(write-and-eval
 libbug-macros-file
 {at-both-times
  {define-macro if
    [|pred ifTrue ifFalse|
     ;; (single-expression? [5]) => true
     ;; (single-expression? [(pp 4) 6]) => false
     {let ((single-expression?
	    [|lst| (equal? 3 (length lst))]))
       `{##if ,pred
	      ,{##if (single-expression? ifTrue)
		     (caddr ifTrue)
		     `{begin ,@(cddr ifTrue)}}
	      ,{##if (single-expression? ifFalse)
		     (caddr ifFalse)
		     `{begin ,@(cddr ifFalse)}}}}]}})



;; Just like for the definiton of lang#if, the subsequent macro
;; "with-tests" will be namespaced at compile-time, run-time, and
;; in libbug-macros-file
;;
;; Statically-typed programming languages are compiled/interpreted
;; by programming language implementations which themselves are
;; programs.  To add new types of compile-time type checks, the compiler
;; needs to be updated and redistributed.  Changes to the language
;; need to be documented are communicated.
;;
;; Unit tests, since moving away from the image-based SUnit and into
;; file-based xUnits implementations, are collections of procedures
;; which test procedures in other files.
;;
;; with-tests in a new type of test procedure, which execute at
;; compile-time, and should they fail, no executable is produced;
;; just as with a statically typed language.  The initial impetus
;; for the creation of this macro was the desire to collocate procedures
;; with their tests, for linear reading, and for clearly seeing which
;; tests are intended to test which procedures.
;;
;; with-tests, combined with the more general purpose at-compile-time,
;; provide the basis to create BUG programs in a "Literate Programming"
;; style.


{at-compile-time
 {namespace ("lang#" with-tests)}}
{write-and-eval
 libbug-headers-file
 {namespace ("lang#" with-tests)}}
(write-and-eval
 libbug-macros-file
 {define-macro with-tests
   [|definition #!rest tests|
    (eval
     `{begin
	,definition
	(if (and ,@tests)
	    ['no-op]
	    [(pp "Test Failed")
	     (pp {quote ,tests})
	     (pp (quote ,definition))
	     (error "Tests Failed")])})
    ;;the actual macro expansion is just the definition
    definition]})



;; BUG is compiled using the Autotools, and when running "make
;; install", will be installed to the prefix specified to
;; "configure".  The headers file defined above at compile-time
;; will be installed relative to prefix, and as such, external
;; programs which use BUG need to know where to find it.
;; More importantly, libbug-macros-file needs to have functions
;; and macros namespaced accordingly, and as such, will need
;; to know where the headers file is installed.
;;
;; The autotools takes "config.scm.in" as input, and puts the
;; relevant configuration/installation information into config.scm
;; This information is then used at compile time when both defining
;; and exporting macros to an external file.
{at-compile-time
 {begin
   {##include "config.scm"}
   {define bug-configuration#libbugsharp
     (string-append bug-configuration#prefix "/include/bug/libbug#.scm")}}}



;; For both lang#if and lang#with-tests, defining the namespace
;; at compile-time, run-time, and in the namespace file at compile-
;; time was tedious.  This is easily extractable into a macro,
;; as is used heavily throughout BUG.
{define-macro libbug#namespace
  [|namespace-name-pair|
   {begin
     (eval `{##namespace ,namespace-name-pair})
     `{begin
	(write-and-eval
	 libbug-headers-file
	 {##namespace ,namespace-name-pair})}}]}


;; Likewise, defining the macros and exporting them has also
;; been a repetitive process.
{define-macro libbug#define-macro
  [|namespace name lambda-value #!rest tests|
   ;; the macro that libbug#define-macro creates should
   ;; have the same parameter list, augmented with some namespacing,
   ;; with otherwise the same macro body
   ;; write the augmented lambda form out to the macro file for use by external projects
   ;; Note: the compile-time tests are not included
   (newline libbug-macros-file)
   (write `{at-both-times
	    {define-macro
	      ,name
	      (lambda ,(cadr lambda-value) ;; arguments to the macro
		(,'quasiquote (##let ()
				{##include "~~lib/gambit#.scm"}
				{##include ,bug-configuration#libbugsharp}
				,@(if (equal? 'quasiquote
					      (caaddr lambda-value))
				      [(cdaddr lambda-value)]
				      [`((,'unquote ,@(cddr lambda-value)))]))))}}
	  libbug-macros-file)
;; define the macro, with the unit tests, for this file
   `{begin
      {libbug#namespace (,namespace ,name)}
      {with-tests
       {define-macro
	 ,name
	 ,lambda-value}
       ,@tests}}]}

;; Function definitions will all have a namespace, name, body,
;; and an optional suite of tests
{define-macro
 libbug#define
 [|namespace name body #!rest tests|
  `{begin
     {libbug#namespace (,namespace ,name)}
     {with-tests
      {define ,name ,body}
      ,@tests}}]}

;;  MAIN  --------------------------------------------------------------
;;
;;  Enough with the boring infrastructer, onto the meat!
;;
;;  Sometimes, you need to pass a procedure to another procedure, but you
;;  don't want to change the input.  Although at first this may sound odd,
;;  but remember that in calculus, the fact that d/dx f(x) is 1 when
;;  f(x) = x is necessary for determining d/dx g(x) is 2x when g(x) = x^2.
;;  And f(x) = x is just the identity function.


{libbug#define
 "lang#"
 identity
 [|x| x]
 (equal? "foo" (identity "foo"))}

;;  Sometimes you just need a procedure to be passed to another procedure,
;;  but you just don't need it to do a damn thing.

{libbug#define
 "lang#"
 noop
 ['noop]
 (equal? (noop) 'noop)}


;; Kind of list and?, but takes a list
{libbug#define
 "list#"
 all?
 [|lst|
  {cond ((null? lst) #t)
	((not (car lst)) #f)
	(else (all? (cdr lst)))}]
 (all? '())
 (all? '(1))
 (all? '(#t))
 (all? '(#t #t))
 (not (all? '(#f)))
 (not (all? '(#t #t #t #f)))}




;; We shouldn't have to keep typing the function name in tests,
;; should just be able to specify inputs and outputs

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
		     `((0 1)
		       (1 2)
		       (2 3)))}


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
  `((5 pos)
    (0 zero)
    (-5 neg)))}


{libbug#define
"lang#"
 complement
 [|f|
  [|#!rest args| (not (apply f args))]]
 (satisfies-relation
  [|x| ((complement pair?) x)]
  `(
    (1 #t)
    ((1 2) #f)))}




;;   Creates a copy of the list data structure
{libbug#define
 "list#"
 copy
 [|l| (map identity l)]
 (satisfies-relation
  copy
  `(
    ((1 2 3 4 5) (1 2 3 4 5))))}


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
  `((4 #f)
    ((1 2) #t)
    ((1 2 . 5) #f)))}



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
    ((1 2 3 4 5 6) (6 5 4 3 2 1))))}

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
    ((2 3 1 1 1) 2)))
 ;; test the onNull handler
 (satisfies-relation
  [|l| (first l onNull: [5])]
  `(
    (() 5)
    ((1 2 3) 1)))}

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
    ((1 2 3) (2 3))))
 (satisfies-relation
  [|l| (but-first l onNull: [5])]
  `(
    (() 5)))}

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
    ((1 2) 2)))
 (satisfies-relation
  [|l| (last l onNull: [5])]
  `(
    (() 5)
    ((1) 1)))}

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
    ((1 2 3) (1 2))))
 (satisfies-relation
  [|l| (but-last l onNull: [5])]
  `(
    (() 5)
    ((1) ())))}

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
    ((1 2 3 4 5 -2) (1 3 4 5))))}

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
    ((1 5 2 5 3 5 4 5 5) (1 2 3 4))))}


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
    ((1 2 3 4 5 6) 21)))}

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
    ((1 1 1 2 20 30) (0 1 2 3 5 25 55))))}



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
    ((2 2 5 4) 1)))}

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
    ((1 2 3) (1 1 1 2 2 2 3 3 3))))
 (satisfies-relation
  [|l| (flatmap [|x| (list x
			   (+ x 1)
			   (+ x 2))]
		l)]
  `(
    ((10 20) (10 11 12 20 21 22))))}

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
	      (3 2 1)))))}

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
    ((1 2 3) ((1 2 3) (2 3) (3)))))}


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


;;  The following are macros defined in other books, and are not
;;  extracted from syntactic patterns from within BUG.  Consult
;;  the prerequisites to understand why they are important.

;; aif
;;   anaphoric-if evaluates bool, binds it to the variable "it",
;;   which is accessible in body.
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
