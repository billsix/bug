;; %Copyright 2014,2015 - William Emerison Six
;; %All rights reserved
;; %Distributed under LGPL 2.1 or Apache 2.0

;; \break
;; \section{Bug Language}
;;  \label{sec:buglang}
;; \subsection{Bug Infrastructure Introduction}
;;
;; Since BUG is a library, I need to create and export macros, namespaces,
;; data, types, and functions.  The following section of code provides the
;; infrastructure necessary to export these.  First, I define
;; ``at-compile-time'', a macro which ensures that the code
;; evaluates at compile-time only.  For instance, if uncommented, the
;; ``{at-compile-time (pp 5)}'' would print 5 at compile time, but would
;; not execute at runtime. Second, I create ``at-both-times'', which is
;; like ``at-compile-time'', executes at compile time, but also at run-time.
;; Third, at compile time, I create two files, ``libbug\#.scm'' and
;; "libbug-macros.scm".  These files are to be used by external programs which
;; wish to use code from BUG. "libbug\#.scm" will contain all of the namespace
;; definitions, and "libbug-macros.scm" will contain all of the macros exported
;; from this file. Fourth, I create custom functions to define functions and macros, which allow
;; definitions within the library and which exports them to the aforementioned
;; files.  These are called "libbug\#define-macro" and "libbug\#define", to convey
;; that these macros are not exported to external programs. Fifth, I create a
;; macro "lang\#if", which takes lambdas.  So (if 5 [1] [2])
;; instead of (if 5 1 2).  Six, a "with-tests" macro, which allows
;; definitions to be collocated with the
;; tests which test the definition, which executes only at compile-time, and if
;; failure occurs, no executable is produced.
;;
;;
;; \subsection{Bug Infrastructure}
;;
;; \begin{code}
(##include "~~lib/gambit#.scm")
;;\end{code}


;; Within BUG, all of the functions and macros should have a namespace
;; associated with them.  I use "lang\#" for basic language procedures, "list\#"
;; for lists, etc.  ``at-compile-time'' macro is implemented by ``eval''ing code
;; during macro-expansion
;; \footnote{https://mercure.iro.umontreal.ca/pipermail/gambit-list/2012-April/005917.html}
;;

;; \begin{code}
{namespace ("lang#" at-compile-time)}
{define-macro at-compile-time
  [|form|
   (eval form)
   `{quote noop}]}

{##namespace ("lang#" at-both-times)}
{define-macro at-both-times
  [|form|
   (eval form)
   `(begin
      (eval ',form)
      ,form)]}
;; \end{code}

;; \begin{itemize}
;;   \item On line 4, the unevaluated code which was passed to
;;  ``at-compile-time is evaluated during macroexpansion, so it is evaluated
;;  at compile-time.  The macroexpansion expands into ``(quote noop)'', so the
;;  code will not evaluate at runtime.
;; \item On line 10, evaluation in the expansion-time environment
;; \item On line 12, evaluation in the expansion-time environment of
;; the run-time environment
;; \item On line 13, evaluation in the run-time environment
;; \end{itemize}

;; BUG is a collection of procedures and macros.  Building bug results
;; in a shared library and a "loadable" library (as in (load "foo.o1").
;; Macro definitions and namespace declarations, however do not reside
;; in such libraries.  I intend to keep the vast majority of BUG code
;; in this one file (minus the C preprocessor, gsi interpreter glue,
;; and build files).  As such, I don't want to define the namespaces
;; or macros definitions in a different file.
;;
;; ``at-compile-time'' allows us to execute arbitrary code at compile time,
;; so why not open files and write to them during compile time?
;; Open one file for the namespaces, ``libbug\#.scm'', and one for the macros,
;; ``libbug-macros.scm''.  These files will be pure Gambit scheme code, no
;; BUG-syntax enhancements, and they are not intended to be read by
;; a person.  Their documentation is in this file.
;;
;; The previous two macros are also written to the libbug-macros.scm file,
;; and a reference from libbug-macros.scm to libbug\#.scm is made, so
;; a person can now assume that the files must be collocated.
;;
;; At the end of this document, the files are closed during compile time.

;; \begin{code}
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
;; \end{code}




;; Now that those files are open, I want to write to them.  Namespaces
;; to libbug\#.scm, and macros to libbug-macros.scm.  However, I don't want
;; to have to duplicate the code for each context, like I just did for
;; the previous two macros.
;;
;; So, create a new line on the file, write the unevaluated form to the
;; file, and the return the form so that the compiler actually processes it.


;; \begin{code}
{define-macro write-and-eval
  [|port form|
   (eval `(begin
	    (newline ,port)
	    (write ',form ,port)))
   form]}
;; \end{code}

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

;; \begin{code}
{at-compile-time
 {##namespace ("lang#" if)}}
{write-and-eval
 libbug-headers-file
 {##namespace ("lang#" if)}}
;; \end{code}

;; \begin{code}
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
;; \end{code}



;; Just like for the definiton of lang\#if, the subsequent macro
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


;; \begin{code}
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
;; \end{code}



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

;; \begin{code}
{at-compile-time
 {begin
   {##include "config.scm"}
   {define bug-configuration#libbugsharp
     (string-append bug-configuration#prefix "/include/bug/libbug#.scm")}}}
;; \end{code}



;; For both lang\#if and lang\#with-tests, defining the namespace
;; at compile-time, run-time, and in the namespace file at compile-
;; time was tedious.  This is easily extractable into a macro,
;; as is used heavily throughout BUG.

;; \begin{code}
{define-macro libbug#namespace
  [|namespace-name-pair|
   {begin
     (eval `{##namespace ,namespace-name-pair})
     `{begin
	(write-and-eval
	 libbug-headers-file
	 {##namespace ,namespace-name-pair})}}]}
;; \end{code}


;; Likewise, defining the macros and exporting them has also
;; been a repetitive process.
;;
;; \begin{code}
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
;; \end{code}


;; Function definitions will all have a namespace, name, body,
;; and an optional suite of tests
;;
;; \begin{code}
{define-macro
 libbug#define
 [|namespace name body #!rest tests|
  `{begin
     {libbug#namespace (,namespace ,name)}
     {with-tests
      {define ,name ,body}
      ,@tests}}]}
;; \end{code}


;;\end{document}  %End of document.
