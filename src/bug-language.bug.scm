;;; %Copyright 2014-2016 - William Emerison Six
;;; %All rights reserved
;;; %Distributed under LGPL 2.1 or Apache 2.0
;;;
;;; \break
;;; \chapter{Computation At Compile-Time}
;;;  \label{sec:buglang}
;;;
;;; The most prevalent code which executed at compile-time in the previous chapter
;;; was code for testing, but many other computations occurred during compile-time
;;; transparently to the reader.  These other computations produced output
;;; files for namespace mappings and for macro definitions, to be used by other
;;; programs which link against libbug.
;;;
;;; Many languages, for example C and C++, also must deal with a similar issue with libraries
;;; when dealing with procedure prototypes.  Whenever a C programmer
;;; creates a new procedure, he must then copy the procedure name and parameter list into
;;; a ``.h'' file,
;;; so that other files may type check against it at compile-time.
;;;
;;; Libbug takes a novel approach to solve that problem; it generates this information at
;;; compile-time.  At first glance, that sound simple enough.  But what types of computation
;;; can be performed at compile-time, and can a programmer program I/O 
;;; at compile-time?
;;; Programs written in C and C++ cannot, as C's macros only allow textual substitution
;;; and conditional compilation, is not Turing Complete,
;;; and has no I/O capabilities.  C++'s template metaprogramming, althogh Turing Complete,
;;; lacks state and I/O.
;;;
;;; So, what does libbug do that is novel?  It provides procedures to do arbitrary computation
;;; at compile-time, where the compile-time language is the same exact language which
;;; the compiler compiles.  A programmer can write programs to run at compile-time
;;; in the same manner as he'd normally write them.
;;;
;;;
;;;
;;;
;;; Reset all namespace mappings for procedures defined by Gambit.
;;;
;;; \begin{code}
(##include "~~lib/gambit#.scm")
;;;\end{code}
;;;
;;;
;;; \section{lang\#at-compile-time}
;;; ``at-compile-time'' macro is implemented by ``eval''ing code
;;; during macro-expansion. \cite{evalduringmacroexpansion}
;;;
;;; Evaling during macro-expansion is how the compiler may be augmented with new procedures,
;;; thus treating the compiler as an interpreter.
;;;
;;; \index{lang\#at-compile-time}
;;; \begin{code}
{##namespace ("lang#" at-compile-time)}
{##define-macro at-compile-time
  [|form|
   (eval form)
   `{quote noop}]}
;;; \end{code}
;;;
;;; \begin{itemize}
;;;   \item On line 4, the unevaluated code which was passed to
;;;  ``at-compile-time'' is evaluated during macro-expansion, thus
;;;  at compile-time.  The macro-expansion expands into ``(quote noop)'', so the
;;;  form will not evaluate at runtime.
;;; \end{itemize}
;;;
;;; \section{lang\#at-both-times}
;;; \index{lang\#at-both-times}
;;; \begin{code}
{##namespace ("lang#" at-both-times)}
{##define-macro at-both-times
  [|form|
   (eval form)
   form]}
;;; \end{code}
;;;
;;; \begin{itemize}
;;; \item On line 4, evaluation in the compile-time environment
;;; \item On line 5, evaluation in the run-time environment
;;; \end{itemize}
;;;
;;; Libbug is a collection of procedures and macros.  Building libbug results
;;; in a library (static or dynamic) and a ``loadable'' library (a .o1 file).
;;; Macro definitions and namespace declarations ae not compiled into such
;;; libraries.
;;;
;;; ``at-compile-time'' allows us to execute arbitrary code at compile-time,
;;; so why not open files and write to them during compile-time?
;;; Open one file for the namespaces, ``libbug\#.scm'', and one for the macros,
;;; ``libbug-macros.scm''.  These files will be pure Gambit scheme code, no
;;; libbug-syntax enhancements, and they are not intended to be read by
;;; a person.  Their documentation is in this file.
;;;
;;; \section{lang\#at-compile-time-expand}
;;; \index{lang\#at-compile-time-expand}
;;;
;;; ``at-compile-time-expand'' allows any procedure to act as a macro.
;;;
;;; \begin{code}
{##namespace ("lang#" at-compile-time-expand)}
{##define-macro at-compile-time-expand
  [|form|
   (eval form)]}
;;; \end{code}
;;;
;;; \subsection{Create File for Namespaces}
;;;
;;;  The previous three macros are namespaced within libbug, but
;;;  external projects which will use libbug may need these namespace
;;;  mappings as well.  To rectify that, open a file
;;;  during compile-time, and write those namespace mappings
;;;  to the file.
;;;
;;; \begin{code}
{at-compile-time
 {begin
   {##define libbug-headers-file
     (open-output-file '(path:
                         "libbug#.scm"
                         append:
                         #f))}
   (display
    ";;; Copyright 2014-2016 - William Emerison Six
     ;;;  All rights reserved
     ;;;  Distributed under LGPL 2.1 or Apache 2.0
     {##namespace (\"lang#\" at-compile-time)}
     {##namespace (\"lang#\" at-both-times)}
     {##namespace (\"lang#\" at-compile-time-expand)}
     "
    libbug-headers-file)
;;; \end{code}
;;;
;;; \subsection{Create File for Macro Definitions}
;;;
;;;
;;;  The previous three macros are currently available throughout libbug,
;;;  but not to programs which use libbug.  To rectify that, open a file
;;;  during compile-time, and write those macro definitions
;;;  to the file.
;;;
;;; \begin{code}
   {##define libbug-macros-file
     (open-output-file '(path: "libbug-macros.scm"
                         append: #f))}
   (display
    ";;; Copyright 2014-2016 - William Emerison Six
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
     {##define-macro at-compile-time-expand
       [|form|
       (eval form)]}
     "
    libbug-macros-file)
   }}
;;; \end{code}
;;;
;;; \begin{itemize}
;;;   \item On line 11, ``libbug\#.scm'' is imported, so that the generated macros are
;;;         namespaced correctly in external projects which import libbug.  In the previous section,
;;;         this file is created at compile-time.  Remember that when ``libbug-macros.scm'' will
;;;         be imported by an external project, ``libbug\#.scm'' will exist with all
;;;         of the namespaces defined in libbug.
;;; \end{itemize}
;;;
;;; The files are closed section~\ref{sec:closefiles}
;;;
;;; \section{libbug\#write-and-eval}
;;;
;;; Now that those files are open, namespaces will be written 
;;; to libbug\#.scm and macro definitions to libbug-macros.scm.  However, the
;;; code shouldn't have be to duplicated for each context, like was done for
;;; the previous three macros.
;;;
;;; So, create a macro named ``write-and-eval'' which will write the
;;; unevaluated form plus a newline to the
;;; file, and the return the form so that the compiler actually evaluate it.
;;;
;;; \index{libbug\#write-and-eval}
;;; \begin{code}
{##define-macro libbug#write-and-eval
  [|port form|
   (eval `(begin
            (write ',form ,port)
            (newline ,port)))
   form]}
;;; \end{code}
;;;
;;;
;;; \section{libbug\#namespace}
;;;
;;; ``write-and-eval'' writes the form to a file, and evaluates the
;;; form in the run-time context.  For namespaces in libbug, that
;;; behavior is desired, but the namespaces should be valid at
;;; compile-time too.
;;;
;;; \index{libbug\#namespace}
;;; \begin{code}
{##define-macro libbug#namespace
  [|namespace-name-pair|
   {begin
     (eval `{##namespace ,namespace-name-pair})
     `{begin
        (libbug#write-and-eval
         libbug-headers-file
         {##namespace ,namespace-name-pair})}}]}
;;; \end{code}
;;;
;;;
;;;
;;; \section{lang\#if}
;;; \label{sec:langif}
;;; In the following, a new version of "if" is defined, which was first used
;;; in section ~\ref{sec:langiffirstuse}
;;;
;;;
;;;
;;; \index{lang\#if}
;;; \begin{code}
{libbug#namespace ("lang#" if)}
(libbug#write-and-eval
 libbug-macros-file
 {at-both-times
  {##define-macro if
    [|pred ifTrue ifFalse|
     ;; check that the person is not using lang#if as if
     ;; it were ##if
     (##if (or (not (list? ifTrue))
               (not (list? ifFalse))
               (not (equal? 'lambda (car ifTrue)))
               (not (equal? 'lambda (car ifFalse))))
           (error "lang#if requires two lambda expressions")
           {let ((single-expression-in-lambda?
                  [|lst| (equal? 3 (length lst))]))
             ;; (single-expression-in-lambda? [5])
             ;;   => true
             ;; (single-expression-in-lambda? [(pp 4) 6])
             ;;   => false
             `{##if ,pred
                    ,{##if (single-expression-in-lambda?
                            ifTrue)
                           (caddr ifTrue)
                           `{begin ,@(cddr ifTrue)}}
                    ,{##if (single-expression-in-lambda?
                            ifFalse)
                           (caddr ifFalse)
                           `{begin ,@(cddr ifFalse)}}}})]}})
;;; \end{code}
;;;
;;;
;;;
;;; \section{lang\#with-tests}
;;;
;;; \index{lang\#with-tests}
;;;
;;; Given that the reader now knows how to evaluate at compile-time, implementing
;;; a macro to execute tests at compile-time is trivial.
;;;
;;; \begin{itemize}
;;;  \item  Make a macro called ``with-tests'', which takes an unevaluated definition
;;;         and an unevaluated list of tests.
;;;  \item  ``eval'' a form which will either error, causing the compilation to
;;;         exit, or will evaluate to the unevaluated definition, thus allowing the
;;;         Gambit compiler to compile the form as usual.
;;; \end{itemize}
;;;
;;;
;;; \begin{code}
{libbug#namespace ("lang#" with-tests)}
(libbug#write-and-eval
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
;;;
;;;
;;; \section{libbug\#define}
;;; Procedure definitions will all have a namespace, name, body,
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
       {##define ,name ,body}
       ,@tests}}]}
;;; \end{code}
;;;
;;; \section{libbug\#define-macro}
;;;
;;; ``libbug\#define-macro'' acts just like ''\#\#define-macro'', but
;;; it also writes the macro definition to a file, and overrides
;;; ``\#\#gensym'' so that macro-expansions may be tested.
;;; But when the macros are loaded by an external project, how
;;; does it load the namespaces for them?  From the namespace file, which
;;; is installed as a relative path to the ``prefix'' argument passed to ``configure''.
;;;
;;; Autoconf takes "config.scm.in" as input, and puts the
;;; relevant configuration/installation information (such as
;;; the installation prefix) into config.scm
;;;
;;; \begin{code}
{at-compile-time
 {begin
   (##include "config.scm")
   {##define bug-configuration#libbugsharp
     (string-append
      bug-configuration#prefix
      "/include/bug/libbug#.scm")}}}
;;; \end{code}
;;;
;;;
;;;
;;;
;;; \label{sec:libbugdefinemacro}
;;;
;;; \index{libbug\#define-macro}
;;; \begin{code}
{##define-macro libbug#define-macro
  [|namespace name lambda-value #!rest tests|
;;; \end{code}
;;; \subsection{Write Macro to File}
;;;
;;; \begin{code}
   (write
    `{begin
;;; \end{code}
;;; \subsubsection{Macro Definition}
;;;   The macro definition written to the file will be imported as
;;;   text by other projects,
;;;   which themselves may have different namespace mappings than libbug.
;;;   To ensure that the macro works correctly in other contexts, the
;;;   appropriate namespace
;;;   mappings must be loaded, but just for this macro definition.
;;;
;;; \begin{code}
       {at-both-times
        {##define-macro
          ,name
          (lambda ,(cadr lambda-value)
            ,(list 'quasiquote
                   `{##let ()
                      (##include "~~lib/gambit#.scm")
                      (##include
                       ,bug-configuration#libbugsharp)
                      ,(if (equal? 'quasiquote
                                   (caaddr lambda-value))
                           [(car (cdaddr lambda-value))]
                           [(append (list 'unquote)
                                    (cddr lambda-value))])}))}}
;;; \end{code}
;;;
;;;
;;;
;;; \begin{itemize}
;;;   \item On line 1, the program which imports this macro shall define the
;;;         macro at both compile-time and run-time.
;;;   \item On line 4, the written-to-file lambda value shall have the same
;;;         argument list as the argument list passed to ``libbug\#define-macro''
;;;   \item On line 5, the unevaluated form in argument ``lambda-value'' may
;;;         or may not be quasiquoted.  Either way, write a quasiquoted form
;;;         to the file.  In the case that the ``lambda-value'' argument was not
;;;         actually intended to be quasiquoted, immediately unquote (which is
;;;         done on line 12-13), thereby negating the quasi-quoting.
;;;   \item On line 5-6, rather than nesting quasiquotes, line 5 uses a technique
;;;         of replacing a would-be nested quasiquote with ``,(list 'quasiquote `(...)''.
;;;         This makes the code more readable \cite[p. 854]{paip}.  Should the reader
;;;         be interested in learning more about nested quasiquotes, Appendix C
;;;         of \cite[p. 960]{cl} is a great reference.
;;;   \item On line 6-8, ensure that the currently unevaluated form will be
;;;         evaluated in a context in which the namespaces resolve consistently
;;;         as they were written in this book.
;;;   \item On line 9-10, check to see if the unevaluated form is quasiquoted.
;;;   \item On line 11, it is quasiquoted, as such, grab the content of the
;;;         list minus the quasiquoting.
;;;   \item On line 12-13, since this is not a quasi-quoted form, just grab
;;;         the form, and ``unquote'' it.
;;; \end{itemize}
;;;
;;;
;;;
;;; \subsubsection{Procedure to expand macro invocations}
;;;
;;; In order to be able to test the macro transformation as unevaluated
;;; code, create a procedure (instead of a macro) with ``-expand''
;;; suffixed to the ``name'', with the same procedure body as
;;; the ``lambda-value'''s body.  Override ``gensym'' in this generated
;;; procedure, so that tests may be written\footnote{``\#\#gensym'', by definition,
;;; creates a unique symbol which the programmer could never input, which is why it
;;; needs to be overridden for testing macro-expansions. }.
;;;
;;; \begin{code}
       {at-both-times
        ;; TODO - namespace this procedure
        {##define-macro
          ,(string->symbol (string-append (symbol->string name)
                                          "-expand"))
          (lambda ,(cadr lambda-value)
            {let ((gensym-count 0))
              {let ((gensym
                     [{begin
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
;;; \subsection{Define Macro and Run Tests}
;;; Now that the macro has been exported to a file, now the macro must
;;; be defined within libbug itself.
;;;
;;; \begin{code}
   {let ((gensym-count (gensym)))
     `{begin
;;; \end{code}
;;;
;;; \noindent Namespace the procedure
;;;
;;; \begin{code}
        {libbug#namespace (,namespace ,name)}
;;; \end{code}
;;;
;;; \noindent Create the expander just like in the previous section.
;;;
;;; \begin{code}
        {at-both-times
         ;; TODO - namespace this procedure
         {##define-macro
           ,(string->symbol
             (string-append (symbol->string name)
                            "-expand"))
           (lambda ,(cadr lambda-value)
             {let ((,gensym-count 0))
               {let ((gensym
                      [{begin
                         {set! ,gensym-count
                               (+ 1 ,gensym-count)}
                         (string->symbol
                          (string-append
                           "gensymed-var"
                           (number->string ,gensym-count)))}]))
                 (list 'quote ,@(cddr lambda-value))}})}}
;;; \end{code}
;;;
;;; \noindent Now that the macroexpander procedure has been defined, define the macro
;;; and execute the compile-time tests.
;;;
;;; \begin{code}
        {with-tests
         {##define-macro
           ,name
           ,lambda-value}
         ,@tests}}}]}
;;;
;;; \end{code}
;;;
;;; \section{lang\#macroexpand-1}
;;;
;;; ``macroexpand-1'' allows the programmer to test macro-expansion by writing
;;;
;;; \begin{examplecode}
;;;(equal? (macroexpand-1 (aif (+ 5 10)
;;;                            (* 2 it)))
;;;       '{let ((it (+ 5 10)))
;;;          (if it
;;;              [(* 2 it)]
;;;              [#f])})
;;; \end{examplecode}
;;;
;;; \noindent instead of
;;;
;;; \begin{examplecode}
;;;(equal? (aif-expand (+ 5 10)
;;;                    (* 2 it)))
;;;       '{let ((it (+ 5 10)))
;;;          (if it
;;;              [(* 2 it)]
;;;              [#f])})
;;; \end{examplecode}
;;;
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
;;;
;;;
;;;
