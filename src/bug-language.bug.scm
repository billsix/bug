;;; %Copyright 2014-2016 - William Emerison Six
;;; %All rights reserved
;;; %Distributed under LGPL 2.1 or Apache 2.0

;;; \break
;;; \chapter{Computation At Compile-Time}
;;;  \label{sec:buglang}
;;; \section{Motivation}
;;;
;;; BUG is a library which contains procedure definitions, but is not
;;; an application on its own.  External
;;; projects will link to BUG and use BUG's procedures; however,
;;; those projects will need additional information such as namespace mappings
;;; and BUG's macro definitions (since those are not present in the library.)
;;;
;;; Many languages, namely C and C++, also must deal with a similar issue with libraries
;;; when dealing with function prototypes.  Whenever a C programmer
;;; creates a new function, he must then copy the parameter list into an ``.h'' file,
;;; so that other files may type check against it at compile-time.
;;;
;;; BUG takes a novel approach; BUG generates this type of information at
;;; compile-time.  At first glance, that sound simple enough.  But what types of computation
;;; can be performed at compile-time, and how can a programmer program I/O to be evaluated at compile-time?
;;; C's macros only allow textual substitution and conditional compilation, is not Turing Complete,
;;; and definitely doesn't do I/O.  C++'s template metaprogramming is Turing Complete, yet is
;;; a drastically different language from ``run-time'' C++; and also lacks I/O capabilities.
;;;
;;; So, what does BUG do that is novel?  BUG provides procedures to do arbitrary computation
;;; at compile-time, where the compile-time ``language'' is the same exact language which
;;; the compiler compiles.  Less verbosely, a programmer can write programs to run at compile time
;;; in the same manner as he'd normally write them.


;;;
;;; \section{Eval'ing during Macroexpansion}
;;;
;;; Reset all namespace mappings for procedures defined by Gambit.
;;;
;;; \begin{code}
(##include "~~lib/gambit#.scm")
;;;\end{code}


;;; \subsection*{lang\#at-compile-time}
;;; ``at-compile-time'' macro is implemented by ``eval''ing code
;;; during macro-expansion
;;; \footnote{https://mercure.iro.umontreal.ca/pipermail/gambit-list/2012-April/005917.html}
;;;

;;; \index{lang\#at-compile-time}
;;; \begin{code}
{##namespace ("lang#" at-compile-time)}
{##define-macro at-compile-time
  [|form|
   (eval form)
   `{quote noop}]}
;;; \end{code}

;;; \begin{itemize}
;;;   \item On line 4, the unevaluated code which was passed to
;;;  ``at-compile-time is evaluated during macroexpansion, so it is evaluated
;;;  at compile-time.  The macroexpansion expands into ``(quote noop)'', so the
;;;  code will not evaluate at runtime.
;;; \end{itemize}

;;; \subsection*{lang\#at-both-times}
;;; \index{lang\#at-both-times}
;;; \begin{code}
{##namespace ("lang#" at-both-times)}
{##define-macro at-both-times
  [|form|
   (eval form)
   form]}
;;; \end{code}

;;; \begin{itemize}
;;; \item On line 4, evaluation in the expansion-time environment
;;; \item On line 5, evaluation in the run-time environment
;;; \end{itemize}

;;; BUG is a collection of procedures and macros.  Building bug results
;;; in a shared library and a "loadable" library (as in (load "foo.o1").
;;; Macro definitions and namespace declarations, however do not reside
;;; in such libraries.  I intend to keep the vast majority of BUG code
;;; in this one file (minus the C preprocessor, gsi interpreter glue,
;;; and build files).  As such, I don't want to define the namespaces
;;; or macros definitions in a different file.
;;;
;;; ``at-compile-time'' allows us to execute arbitrary code at compile time,
;;; so why not open files and write to them during compile time?
;;; Open one file for the namespaces, ``libbug\#.scm'', and one for the macros,
;;; ``libbug-macros.scm''.  These files will be pure Gambit scheme code, no
;;; BUG-syntax enhancements, and they are not intended to be read by
;;; a person.  Their documentation is in this file.
;;;
;;; The previous two macros are also written to the libbug-macros.scm file,
;;; and a reference from libbug-macros.scm to libbug\#.scm is made, so
;;; a person can now assume that the files must be collocated.
;;;
;;; At the end of this document, the files are closed during compile time.

;;; \begin{code}
{at-compile-time
 {begin
;;; \end{code}
;;; \subsubsection*{Create File for Namespaces}
;;; \begin{code}
   {##define libbug-headers-file
     (open-output-file '(path:
			 "libbug#.scm"
			 append:
			 #f))}
   (display
    ";; Copyright 2014-2016 - William Emerison Six
     ;;;  All rights reserved
     ;;;  Distributed under LGPL 2.1 or Apache 2.0
     {##namespace (\"lang#\" at-compile-time)}
     {##namespace (\"lang#\" at-both-times)}
     "
    libbug-headers-file)

;;; \end{code}
;;; \subsubsection*{Create File for Macro Definitions}
;;; \begin{code}
   {##define libbug-macros-file
     (open-output-file '(path:
			 "libbug-macros.scm"
			 append:
			 #f))}
   (display
    ";; Copyright 2014-2016 - William Emerison Six
     ;;;  All rights reserved
     ;;;  Distributed under LGPL 2.1 or Apache 2.0
     (##include \"~~lib/gambit#.scm\")
     (##include \"libbug#.scm\")

     {##define-macro at-compile-time
       [|form|
        (eval form)
        `{quote noop}]}

     {##define-macro at-both-times
       [|form|
        (eval form)
        form]}
     "
    libbug-macros-file)}}
;;; \end{code}

;;; The files are closed section~\ref{sec:closefiles}

;;; \subsection*{write-and-eval}

;;; Now that those files are open, I want to write to them.  Namespaces
;;; to libbug\#.scm, and macros to libbug-macros.scm.  However, I don't want
;;; to have to duplicate the code for each context, like I just did for
;;; the previous two macros.
;;;
;;; So, create a new line on the file, write the unevaluated form to the
;;; file, and the return the form so that the compiler actually processes it.

;;; \index{write-and-eval}
;;; \begin{code}
{define-macro write-and-eval
  [|port form|
   (eval `(begin
	    (write ',form ,port)
	    (newline ,port)))
   form]}
;;; \end{code}

;;; Although I'm not quite sure if namespaces work correctly at compile
;;; time, I'm going to namespace every function/macro at compile-time,
;;; at run time, and in the libbug-headers file.

;;; \subsection*{lang\#if}
;;; In the following, I define a new version of "if".  I prefer how
;;; Smalltalk 80 defines an if expression as compared to how Scheme
;;; and common Lisp do.  Scheme and Common Lisp have special evaluation
;;; rules for if.   true and false could be represented as procedures,
;;; with an if function which would just apply the boolean procedure to
;;; the ifTrue and ifFalse procedures
;;;
;;;

;;; \begin{code}
{at-compile-time
 {##namespace ("lang#" if)}}
{write-and-eval
 libbug-headers-file
 {##namespace ("lang#" if)}}
;;; \end{code}
;;; \index{lang\#if}
;;; \begin{code}
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
;;; \end{code}



;;; Just like for the definiton of lang\#if, the subsequent macro
;;; "with-tests" will be namespaced at compile-time, run-time, and
;;; in libbug-macros-file
;;;
;;; \section{Testing at Compile-Time}
;;; Statically-typed programming languages are compiled/interpreted
;;; by programming language implementations which themselves are
;;; programs.  To add new types of compile-time type checks, the compiler
;;; needs to be updated and redistributed.  Changes to the language
;;; need to be documented are communicated.
;;;
;;; Unit tests, since moving away from the image-based SUnit and into
;;; file-based xUnits implementations, are collections of procedures
;;; which test procedures in other files.
;;;
;;; with-tests in a new type of test procedure, which execute at
;;; compile-time, and should they fail, no executable is produced;
;;; just as with a statically typed language.  The initial impetus
;;; for the creation of this macro was the desire to collocate procedures
;;; with their tests, for linear reading, and for clearly seeing which
;;; tests are intended to test which procedures.
;;;
;;; with-tests, combined with the more general purpose at-compile-time,
;;; provide the basis to create BUG programs in a "Literate Programming"
;;; style.


;;; \subsection*{lang\#with-tests}

;;; \index{lang\#with-tests}
;;; \begin{code}
{at-compile-time
 {##namespace ("lang#" with-tests)}}
{write-and-eval
 libbug-headers-file
 {##namespace ("lang#" with-tests)}}
(write-and-eval
 libbug-macros-file
 {##define-macro with-tests
   [|definition #!rest tests|
    (eval
     `{begin
	,definition
	(if (and ,@tests)
	    [',definition]
	    [(for-each pp (list "Test Failed" ',tests ',definition))
	     (error "Tests Failed")])})]})
;;; \end{code}


;;; \subsection{Build configuration}

;;; BUG is compiled using the Autoconf, and when running "make
;;; install", will be installed to the prefix specified to
;;; "configure".  The headers file defined above at compile-time
;;; will be installed relative to prefix, and as such, external
;;; programs which use BUG need to know where to find it.
;;; More importantly, libbug-macros-file needs to have functions
;;; and macros namespaced accordingly, and as such, will need
;;; to know where the headers file is installed.
;;;
;;; The autotools takes "config.scm.in" as input, and puts the
;;; relevant configuration/installation information into config.scm
;;; This information is then used at compile time when both defining
;;; and exporting macros to an external file.

;;; \begin{code}
{at-compile-time
 {begin
   {##include "config.scm"}
   {##define bug-configuration#libbugsharp
     (string-append
      bug-configuration#prefix
      "/include/bug/libbug#.scm")}}}
;;; \end{code}


;;; \subsection*{libbug\#namespace}

;;; For both lang\#if and lang\#with-tests, defining the namespace
;;; at compile-time, run-time, and in the namespace file at compile-
;;; time was tedious.  This is easily extractable into a macro,
;;; as is used heavily throughout BUG.

;;; \index{libbug\#namespace}
;;; \begin{code}
{##define-macro libbug#namespace
  [|namespace-name-pair|
   {begin
     (eval `{##namespace ,namespace-name-pair})
     `{begin
	(write-and-eval
	 libbug-headers-file
	 {##namespace ,namespace-name-pair})}}]}
;;; \end{code}


;;; \subsection*{libbug\#define-macro}
;;; Likewise, defining the macros and exporting them has also
;;; been a repetitive process.
;;;
;;; The macro that libbug\#define-macro creates should
;;; have the same parameter list, augmented with some namespacing,
;;; with otherwise the same macro body. Write the augmented lambda
;;; form out to the macro file for use by external
;;; projects
;;; Note: the compile-time tests are not included

;;; \label{sec:libbugdefinemacro}
;;;
;;; \index{libbug\#define-macro}
;;; \begin{code}
{##define-macro libbug#define-macro
  [|namespace name lambda-value #!rest tests|
;;; \end{code}
;;; \subsubsection*{Write Macro to File}
;;; \begin{code}
   (write
    `{begin
       {at-both-times
	{##define-macro
	  ,name
	  (lambda ,(cadr lambda-value)
	    ,(list 'quasiquote
		   `(##let ()
		      {##include "~~lib/gambit#.scm"}
		      {##include ,bug-configuration#libbugsharp}
		      ,(if (equal? 'quasiquote
				   (caaddr lambda-value))
			   [(car (cdaddr lambda-value))]
			   [(append (list 'unquote)
				    (cddr lambda-value))]))))}}
       {at-both-times
	;; TODO - namespace this procedure
	{##define-macro
	  ,(string->symbol (string-append (symbol->string name)
					  "-expand"))
	  (lambda ,(cadr lambda-value)
	    {let ((gensym-count 0))
	      {let ((gensym [{begin
			       {set! gensym-count
				     (+ 1 gensym-count)}
			       (string->symbol
				(string-append
				 "gensymed-var"
				 (number->string gensym-count)))}]))
		(list 'quote ,@(cddr lambda-value))}})}}}
    libbug-macros-file)
   (newline libbug-macros-file)
;;; \end{code}
;;; \subsubsection*{Define Macro and Run Tests}
;;; \begin{code}
   {let ((gensym-count (gensym)))
     `{begin
	{libbug#namespace (,namespace ,name)}
	{at-both-times
	 ;; TODO - namespace this procedure
	 {##define-macro
	   ,(string->symbol (string-append (symbol->string name)
					   "-expand"))
	   (lambda ,(cadr lambda-value)
	     {let ((,gensym-count 0))
	       {let ((gensym [{begin
				{set! ,gensym-count
				      (+ 1 ,gensym-count)}
				(string->symbol
				 (string-append
				  "gensymed-var"
				  (number->string ,gensym-count)))}]))
		 (list 'quote ,@(cddr lambda-value))}})}}
	{with-tests
	 {##define-macro
	   ,name
	   ,lambda-value}
	 ,@tests}}}]}

;;; \end{code}

;;; \subsubsection*{Macroexpansion}

;;; A convenience wrapper to expand macros.

;;; \index{lang\#macroexpand-1}
;;; \begin{code}
{libbug#define-macro
 "lang#"
 macroexpand-1
 [|form|
  ;; TODO -error check the list
  {let* ((m (car form))
	 (new-name (string->symbol
		    (string-append (symbol->string m)
				   "-expand"))))
    `(,new-name ,@(cdr form))}]}
;;; \end{code}



;;; \subsection*{libbug\#define}
;;; Function definitions will all have a namespace, name, body,
;;; and an optional suite of tests
;;;
;;; \label{sec:libbugdefine}
;;; \index{libbug\#define}
;;; \begin{code}
{##define-macro
  libbug#define
  [|namespace name body #!rest tests|
   `{begin
      {libbug#namespace (,namespace ,name)}
      {with-tests
       {define ,name ,body}
       ,@tests}}]}
;;; \end{code}
