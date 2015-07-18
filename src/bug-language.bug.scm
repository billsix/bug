;; Copyright 2014,2015 - William Emerison Six
;; All rights reserved
;; Distributed under LGPL 2.1 or Apache 2.0


;; BUG INFRASTRUCTURE INTRODUCTION ---------------------------------------------
;;
;; Since BUG is a library, I need to create and export macros, namespaces,
;; data, types, and functions.  The following section of code provides the
;; infrastructure necessary to export these.
;;
;; First, I define "at-compile-time", a macro which ensures that the code
;; evaluates at compile-time only;
;;
;; For instance, if uncommented, the following code
;;
;;   {at-compile-time (pp 5)}
;;
;;   would print 5 at compile time, but would not execute at runtime.
;;
;; Second, I create "at-both-times", which like "at-compile-time", executes
;; at compile time, but also at run-time.
;;
;; Third, at compile time, I create two files, "libbug#.scm" and
;; "libbug-macros.scm".  These files are to be used by external programs which
;; wish to use code from BUG. "libbug#.scm" will contain all of the namespace
;; definitions, and "libbug-macros.scm" will contain all of the macros exported
;; from this file.
;;
;; Fourth, I create custom functions to define functions and macros, which allow
;; definitions within the library and which exports them to the aforementioned
;; files.  These are called "libbug#define-macro" and "libbug#define", to convey
;; that these macros are not exported to external programs.
;;
;; Fifth, I create a macro "lang#if", which takes lambdas.  So (if 5 [1] [2])
;; instead of (if 5 1 2).
;;
;; Six, a "with-tests" macro, which allows definitions to be collocated with the
;; tests which test the definition, which executes only at compile-time, and if
;; failure occurs, no executable is produced.
;;
;; The reader may skip over reading the implemenation, and skip straight to the
;; "MAIN" section.
;;
;;
;; BUG INFRASTRUCTURE  ---------------------------------------------------------
;;
;; I use Gambit's namespaces for all of BUG's code.  From what I understand of
;; them, namespaces instruct Gambit's reader on how it should associate a given
;; string which it has read in into an internal symbol.  The following line
;; indicates that all further symbols read in should have "libbug#" prefixed to
;; them, unless the symbol itself has a "##" prefix.  I put it in here with
;; the intention of avoiding the pollution of the global namespace.  All
;; subsequent functions and macros should be explicitly namespaced, but if not,
;; they will be namespaced as the following.


{namespace ("libbug#")}



;; That's great as a mechanism to minimize namespace collisions with other
;; Gambit projects, but I still want to be able to reference Scheme procedures.
;; If I were to uncomment the following line
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
 {##namespace ("lang#" if)}}
{write-and-eval
 libbug-headers-file
 {##namespace ("lang#" if)}}

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
 {##namespace ("lang#" with-tests)}}
{write-and-eval
 libbug-headers-file
 {##namespace ("lang#" with-tests)}}
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
   ;; write the augmented lambda form out to the macro file for use by external
   ;; projects
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
				      [`((,'unquote ,@(cddr
						       lambda-value)))]))))}}
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
