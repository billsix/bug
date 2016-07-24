;;; %Copyright 2014-2016 - William Emerison Six
;;; %All rights reserved
;;; %Distributed under LGPL 2.1 or Apache 2.0
;;;
;;; \break

;;; \part{Foundations Of Libbug}
;;; \chapter{Computation At Compile-Time}
;;;  \label{sec:buglang}
;;;
;;; This chapter, which was evaluated before the previous chapters, provides
;;; the foundation for computation at compile-time.  Although
;;; the most prevalent code which executed at compile-time in the previous chapters
;;; was code for testing, but many other computations occurred during compile-time
;;; transparently to the reader.  These other computations produced output
;;; files for namespace mappings and for macro definitions, the latter to be used by other
;;; programs which link against libbug.
;;;
;;;
;;; \section{at-compile-time}
;;; ``at-compile-time'' is a macro which ``eval'''s the form during macroexpansion,
;;; but evaluates to the symbol ``noop'', thus not affecting
;;; run-time \cite{evalduringmacroexpansion}.
;;; Evaling during macro-expansion is how the compiler may be augmented with new procedures,
;;; thus treating the compiler as an interpreter.
;;;
;;; \index{at-compile-time}
;;; \begin{code}
{##namespace ("bug#" at-compile-time)}
{##define-macro at-compile-time
  [|#!rest forms|
   (eval `{begin
            ,@forms})
   `{quote noop}]}
;;; \end{code}
;;;
;;; \begin{itemize}
;;;   \item On line 4, the unevaluated code which is passed to
;;;  ``at-compile-time'' is evaluated during macro-expansion, thus
;;;  at compile-time.  The macro-expansion expands into ``{quote noop}'', so the
;;;  form will not evaluate at runtime.
;;; \end{itemize}
;;;
;;; \section{at-both-times}
;;; \index{at-both-times}
;;;
;;; ``at-both-times'', like ``at-compile-time'', ``eval'''s the forms
;;; in the compile-time environment, but also in the run-time environment.
;;;
;;; \begin{code}
{##namespace ("bug#" at-both-times)}
{##define-macro at-both-times
  [|#!rest forms|
   (eval `{begin
            ,@forms})
   `{begin
      ,@forms}]}
;;; \end{code}
;;;
;;; \begin{itemize}
;;; \item On line 4, evaluation in the compile-time environment
;;; \item On line 5, evaluation in the run-time environment.  The forms
;;;  are returned unaltered to Gambit's compiler, thus ensuring that
;;;  they are defined in the run-time environment.
;;; \end{itemize}
;;;
;;; \section{at-compile-time-expand}
;;; \index{at-compile-time-expand}
;;;
;;; ``at-compile-time-expand'' allows any procedure to act as a macro.
;;;
;;; \begin{code}
{##namespace ("bug#" at-compile-time-expand)}
{##define-macro at-compile-time-expand
  [|#!rest forms|
   (eval `{begin
            ,@forms})]}
;;; \end{code}
;;;
;;; \section{Create Files for Linking Against Libbug}
;;;
;;; Libbug is a collection of procedures and macros.  Building libbug results
;;; in a dynamic library and a ``loadable'' library (a .o1 file, for loading
;;; in the Gambit interpreter).
;;; But programs which link against libug will require libbug's
;;; macro definitions and namespace declarations, both of which are not
;;; compiled into the libraries.  Rather than manually copying all of them to
;;; external files, why not generate them during compile-time?
;;;
;;; Open one file for the namespaces, ``libbug\#.scm'', and one for the macros,
;;; ``libbug-macros.scm''.  These files will be pure Gambit scheme code, no
;;; libbug-syntax enhancements, and they are not intended to be read by
;;; a person.
;;;
;;; \begin{code}
{at-compile-time
;;; \end{code}
;;;
;;; \subsection{Create File for Namespaces}
;;;
;;;  The previous three macros are currently namespaced within libbug, but
;;;  external projects which will use libbug may need these namespace
;;;  mappings as well.  Towards that goal, open a file
;;;  during compile-time and then write those namespace mappings
;;;  to the file.
;;;
;;; \begin{code}
 {##define libbug-headers-file
   (open-output-file '(path: "libbug#.scm" append: #f))}
 (display
  ";;; Copyright 2014-2016 - William Emerison Six
   ;;;  All rights reserved
   ;;;  Distributed under LGPL 2.1 or Apache 2.0
   {##namespace (\"bug#\" at-compile-time)}
   {##namespace (\"bug#\" at-both-times)}
   {##namespace (\"bug#\" at-compile-time-expand)}
   "
  libbug-headers-file)
;;; \end{code}
;;;
;;; \subsection{Create File for Macro Definitions}
;;;
;;;
;;;  The previous three macros are currently available throughout the
;;;  definition of libbug,
;;;  but not to programs which link against libbug.  To rectify that, open a file
;;;  during compile-time, and write those macro definitions
;;;  to the file.


;;;
;;; \begin{code}
 (##include "config.scm")
 {##define bug-configuration#libbugsharp
   (string-append bug-configuration#prefix "/include/bug/libbug#.scm")}

 {##define libbug-macros-file
   (open-output-file '(path: "libbug-macros.scm" append: #f))}
 (display
  (string-append
   ";;; Copyright 2014-2016 - William Emerison Six
    ;;;  All rights reserved
    ;;;  Distributed under LGPL 2.1 or Apache 2.0
    (##include \"~~lib/gambit#.scm\")
    (##include \"" bug-configuration#libbugsharp "\")
    {##define-macro at-compile-time
      [|#!rest forms|
       (eval `{begin
                ,@forms})
       `{quote noop}]}
    {##define-macro at-both-times
      [|#!rest forms|
       (eval `{begin
                ,@forms})
       `{begin
          ,@forms}]}
    {##define-macro at-compile-time-expand
      [|#!rest forms|
       (eval `{begin
                ,@forms})]}
   ")
  libbug-macros-file)
;;; \end{code}


;;; \begin{itemize}
;;;   \item On line 1-3, include the ``config.scm'' file which was preprocessed
;;;     by Autconf, so that the installation directory of libbug is known
;;;     at compile-time.
;;;   \item On line 11, ``libbug\#.scm'' is imported, so that the generated macros are
;;;         namespaced correctly in external projects which import libbug.  In the previous section,
;;;         this file is created at compile-time.  Remember that when ``libbug-macros.scm'' will
;;;         be imported by an external project, ``libbug\#.scm'' will exist with all
;;;         of the namespaces defined in libbug\footnote{Marty: ``Well Doc, we can
;;;    scratch that idea. I mean we can't wait around a year and a half for this
;;;    thing to get finished.''  Doc Brown:  ``Marty it's perfect, you're just not
;;;    thinking fourth-dimensionally.  Don't you see, the bridge will exist in 1985.''
;;;    -Back to the Future 3}.
;;; \end{itemize}
;;;

;;;
;;; \subsection{Close Files At Compile-Time}
;;;
;;; At the end of compilation, these open files will need to be
;;; closed, and the namespace needs to be reset.
;;;
;;; \begin{code}
 {define at-end-of-compilation
   [(display
     "
     (##namespace (\"\"))"
     libbug-macros-file)
    (force-output libbug-headers-file)
    (close-output-port libbug-headers-file)
    (force-output libbug-macros-file)
    (close-output-port libbug-macros-file)]}
 ;; close the call to at-compile-time
 }
;;; \end{code}
;;;
;;;
;;; \section{libbug-private\#write-and-eval}
;;;
;;; Now that those files are open, namespaces will be written
;;; to ``libbug\#.scm'' and macro definitions to ``libbug-macros.scm''.  However, the
;;; code shouldn't have be to duplicated for each context, as was done for
;;; the previous three macros.
;;;
;;; Create a macro named ``write-and-eval'' which will write the
;;; unevaluated form plus a newline to the
;;; file, and then return the form so that the compiler actually evaluate
;;; it\footnote{any procedure which is namespaced to ``libbug-private'' is
;;;  not exported to the namespace file nor the macro file}.
;;;
;;; \index{libbug-private\#write-and-eval}
;;; \begin{code}
{##define-macro libbug-private#write-and-eval
  [|port form|
   (eval `{begin
            (write ',form ,port)
            (newline ,port)})
   form]}
;;; \end{code}
;;;
;;; ``write-and-eval'' writes the form to a file, and only evaluates the
;;; form in the run-time context.  For namespaces in libbug, namespaces
;;; should be valid at
;;; compile-time too.
;;;
;;; \section{libbug-private\#namespace}
;;;
;;; Namespaces for procedures in libbug need to be available at
;;; compile-time, run-time, and in the namespace file
;;; for inclusion in projects which link to libbug.
;;;
;;; \index{libbug-private\#namespace}
;;; \begin{code}
{##define-macro libbug-private#namespace
  [|#!rest to-namespace|
   {begin
     (eval `{##namespace ("bug#" ,@to-namespace)})
     `{begin
        {libbug-private#write-and-eval
         libbug-headers-file
         {##namespace ("bug#" ,@to-namespace)}}}}]}
;;; \end{code}
;;;

;;;
;;; \section{if}
;;; \label{sec:langif}
;;; In the following, a new version of "if" is defined named
;;; ``bug\#if'', where
;;; ``bug\#if'' takes two zero-argument procedures, treating them
;;; as Church Booleans.  bug\#if was first used and described
;;; in section ~\ref{sec:langiffirstuse}
;;;
;;;
;;;
;;; \index{bug\#if}
;;; \begin{code}
{libbug-private#namespace if}
{libbug-private#write-and-eval
 libbug-macros-file
 {at-both-times
  {##define-macro if
    [|pred ifTrue ifFalse|
     {##if {and (list? ifTrue)
                (list? ifFalse)
                (equal? 'lambda (car ifTrue))
                (equal? 'lambda (car ifFalse))}
           (list '##if pred
                 `{begin ,@(cddr ifTrue)}
                 `{begin ,@(cddr ifFalse)})
           (error "bug#if requires two lambda expressions")}]}}}
;;; \end{code}
;;;
;;; \begin{itemize}
;;;  \item
;;;     On line 7, ``\#\#if'' is called.  In Gambit's system of namespacing, ``\#\#'
;;;     is prefixed to a variable name to specify to use the global namespace for
;;;     that variable.
;;;     ``bug\#if'' is built on Gambit's implementation of ``if'', but since
;;;     line 1 set the namespace of ``if'' to ``bug\#if'', ``\#\#if'' must be
;;;     used.
;;;  \item
;;;   On lines 7-10, check that the caller of ``bug\#if'' is passing
;;;   lambdas, i.e. has not forgetten that ``if'' is namespaced to ``bug''.
;;;  \item
;;;    On line 11, if the caller of ``bug\#if'' has not passed lambdas,
;;;    error at compile-time.
;;;  \item
;;;   On line 12-14, evaluate the body of the appropriate lambda, depending
;;;   on whether the predicate is true or false.
;;;
;;; \end{itemize}
;;;
;;;
;;; \section{with-tests}
;;;
;;; \index{with-tests}
;;;
;;; Given that the reader now knows how to evaluate at compile-time, implementing
;;; a macro to execute tests at compile-time is trivial.
;;;
;;; \begin{itemize}
;;;  \item  Make a macro called ``with-tests'', which takes an unevaluated definition
;;;         and an unevaluated list of tests.
;;;  \item  ``eval'' the definiton at compile-time, ``eval'' the tests at compile-time.
;;;     If any test evaluates to false, force the compiler to exit in error, producing
;;;     and appropriate error message.  If all of the tests pass, the Gambit compiler
;;;     will proceed with compiling the definition.
;;; \end{itemize}
;;;
;;;
;;; \begin{code}
{libbug-private#namespace with-tests}
{libbug-private#write-and-eval
 libbug-macros-file
 {##define-macro with-tests
   [|definition #!rest tests|
    (eval
     `{begin
        ,definition
        (if {and ,@tests}
            [',definition]
            [(for-each pp (list "Test Failed" ',tests ',definition))
             (error "Tests Failed")])})]}}
;;; \end{code}
;;;
;;;
;;; \section{libbug-private\#define}
;;;  ``libbug-private\#define'' is the main procedure-defining procedure used
;;;  throughout libbug.  ``libbug-private\#define'' takes a variable name,
;;;  a value to be stored in the variable, and an optional suite of tests.
;;;
;;; \label{sec:libbugdefine}
;;; \index{libbug-private\#define}
;;; \begin{code}
{##define-macro
  libbug-private#define
  [|name body #!rest tests|
   `{begin
      {libbug-private#namespace ,name}
      {with-tests
       {##define ,name ,body}
       ,@tests}}]}
;;; \end{code}
;;;
;;; ``libbug-private\#define'' defines the procedure/data at compile-time
;;; at run-time, and exports the namespace mapping to the appropriate file.
;;;
;;; ``libbug-private\#define'' itself is not exported to the macros file.
;;;
;;;  On line 5-7, ``with-tests'' is applied to test at compile-time, thus
;;;  also ensuring that the definition is available to other procedures
;;;  both at compile-time and at run-time.
;;;
;;; \section{libbug-private\#define-macro}
;;;  Like ``libbug-private\#define'' is built upon ``\#\#define'',
;;;  ``libbug-private\#define-macro'' is built upon ``\#\#define-macro''.
;;;  Like ``libbug-private\#define'', ``libbug-private\#define-macro'' uses
;;;  ``with-tests'', thus ensuring that the macro is available both at
;;;  run-time and at compile-time. But, macros do not get compiled into
;;;  libraries, so for other projects to use them, they must be exported
;;;  to file.
;;;
;;; The steps will be as follows:
;;; \begin{itemize}
;;;   \item Write the macro to file
;;;   \item Write the macro-expander to file
;;;   \item Define the macro-expaneer within libbug
;;;   \item Define the macro using ``with-tests''.
;;; \end{itemize}
;;;
;;;
;;; \label{sec:libbugdefinemacro}
;;;
;;; \index{libbug-private\#define-macro}
;;; \begin{code}
{##define-macro libbug-private#define-macro
  [|name lambda-value #!rest tests|
;;; \end{code}
;;; \subsection{Write Macros to File}
;;;
;;; \begin{code}
   (write
    `{at-both-times
;;; \end{code}
;;; \subsubsection{Macro Definition}
;;;   The macro definition written to the file will be imported as
;;;   text by other projects,
;;;   which themselves may have different namespace mappings than libbug.
;;;   To ensure that the macro works correctly in other contexts, the
;;;   appropriate namespace
;;;   mappings must be loaded for the definition of this macro definition.
;;;
;;; \begin{code}
      {##define-macro
        ,name
        (lambda ,(cadr lambda-value)
          ,(list 'quasiquote
                 `{##let ()
                    (##include "~~lib/gambit#.scm")
                    (##include ,bug-configuration#libbugsharp)
                    ,(if {and (pair? (caddr lambda-value))
                              (equal? 'quasiquote
                                      (caaddr lambda-value))}
                         [(car (cdaddr lambda-value))]
                         [(append (list 'unquote)
                                  (cddr lambda-value))])}))}
;;; \end{code}
;;;
;;;
;;;
;;; \begin{itemize}
;;;   \item On line 1, the program which imports this macro shall define the
;;;         macro at both compile-time and run-time.
;;;   \item On line 4, the written-to-file lambda value shall have the same
;;;         argument list as the argument list passed to ``libbug-private\#define-macro''
;;;
;;; \begin{examplecode}
;;;    > (cadr '[|foo bar| (quasiquote 5)])
;;;    (foo bar)
;;; \end{examplecode}
;;;
;;; \noindent (Remember, all REPL sessions in this book assume that ``bug-gsi'' is running,
;;;  and as such, the lambda literals will be preprocessed.
;;;
;;; \begin{examplecode}
;;;    (cadr '[|foo bar| (quasiquote 5)])
;;; \end{examplecode}
;;;
;;;  expands to
;;;
;;; \begin{examplecode}
;;;    (cadr '(lambda (foo bar) (quasiquote 5)))
;;; \end{examplecode}
;;;
;;;   \item On line 5, the unevaluated form in argument ``lambda-value'' may
;;;         or may not be quasiquoted.  Either way, write a quasiquoted form
;;;         to the file.  In the case that the ``lambda-value'' argument was not
;;;         actually intended to be quasiquoted, unquote the lambda's body (which is
;;;         done on line 13-14), thereby negating the quasi-quoting from line 5.
;;;   \item On line 5-6, rather than nesting quasiquotes, line 5 uses a technique
;;;         of replacing a would-be nested quasiquote with ``,(list 'quasiquote `(...)''.
;;;         This makes the code more readable \cite[p. 854]{paip}.  Should the reader
;;;         be interested in learning more about nested quasiquotes, Appendix C
;;;         of \cite[p. 960]{cl} is a great reference.
;;;   \item On line 6-8, ensure that the currently unevaluated form will be
;;;         evaluated in a context in which the namespaces resolve consistently
;;;         as they were written in this book.  Line 6 create a bounded
;;;         context for namespace mapping.  Line 7 setst standad Gambit namespace
;;;         mappings, line 8 sets libbug's mappings.
;;;   \item On line 9-11, check to see if the unevaluated form is quasiquoted.
;;;
;;; \begin{examplecode}
;;;    > (caaddr '[|foo bar| (quasiquote 5)])
;;;    quasiquote
;;; \end{examplecode}
;;;
;;;   \item On line 12, it is quasiquoted, as such, grab the content of the
;;;         list minus the quasiquoting.
;;;
;;; \begin{examplecode}
;;;    > (car (cdaddr '[|foo bar| (quasiquote 5)]))
;;;    5
;;; \end{examplecode}
;;;
;;;  Remember that this value gets wrapped in a quasiquote from line 5
;;;
;;; \begin{examplecode}
;;;    > (list 'quasiquote (car (cdaddr '[|foo bar|
;;;                                         (quasiquote 5)])))
;;;    `5
;;; \end{examplecode}

;;;   \item On line 13-14, since this is not a quasi-quoted form, just grab
;;;         the form, and ``unquote'' it.
;;;
;;; \begin{examplecode}
;;;    > (append (list 'unquote ) (cddr '[|foo bar| (+ 5 5)]))
;;;    ,(+ 5 5)
;;; \end{examplecode}
;;;
;;;  Remember, that this value gets wrapped in a quasiquote from line 5
;;;
;;; \begin{examplecode}
;;;    > (list 'quasiquote (append (list 'unquote )
;;;                                (cddr '[|foo bar|
;;;                                          (+ 5 5)])))
;;;    `,(+ 5 5)
;;; \end{examplecode}


;;; \end{itemize}
;;;
;;;
;;;
;;; \subsubsection{Procedure to expand macro invocations}
;;;
;;; In order to be able to test the macro transformation before evaluation of the
;;; expanded
;;; code, create a procedure (instead of a macro) with ``-expand''
;;; suffixed to the ``name'', with the same procedure body as
;;; the ``lambda-value'''s body.  Locally define ``gensym'' in this generated
;;; procedure, so that tests may be written\footnote{``\#\#gensym'', by definition,
;;; creates a unique symbol which the programmer could never input, which is why it
;;; needs to be overridden for testing macro-expansions. }.
;;;
;;; \begin{code}
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
              (list 'quote ,@(cddr lambda-value))}})}}
;;; \end{code}
;;;
;;; \begin{code}
    libbug-macros-file)
   (newline libbug-macros-file)
;;; \end{code}
;;; \subsection{Define Macro and Run Tests}
;;; Now that the macro has been exported to a file, now the macro must
;;; be defined within libbug itself.  Firstly, create the expander.
;;;
;;; \begin{code}
   {let ((gensym-count (gensym)))
     `{begin
;;; \end{code}
;;;
;;; \noindent Namespace the procedure and the expander.
;;;
;;; \begin{code}
        {libbug-private#namespace ,name}
        {libbug-private#namespace
         ,(string->symbol
           (string-append (symbol->string name)
                          "-expand"))}
;;; \end{code}
;;;
;;; \noindent Create the expander similarly to the previous section.
;;;
;;; \begin{code}
        {at-both-times
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
;;; \section{macroexpand-1}
;;;
;;; ``macroexpand-1'' allows the programmer to test macro-expansion by writing
;;;
;;; \begin{examplecode}
;;;(equal? {macroexpand-1 (aif (+ 5 10)
;;;                            (* 2 it))}
;;;       '{let ((it (+ 5 10)))
;;;          (if it
;;;              [(* 2 it)]
;;;              [#f])})
;;; \end{examplecode}
;;;
;;; \noindent instead of
;;;
;;; \begin{examplecode}
;;;(equal? {aif-expand (+ 5 10)
;;;                    (* 2 it))}
;;;       '{let ((it (+ 5 10)))
;;;          (if it
;;;              [(* 2 it)]
;;;              [#f])})
;;; \end{examplecode}
;;;
;;; \index{macroexpand-1}
;;; \begin{code}
{libbug-private#define-macro
 macroexpand-1
 [|form|
  {let* ((m (car form))
         (the-expander (string->symbol
                        (string-append (symbol->string m)
                                       "-expand"))))
    `(,the-expander ,@(cdr form))}]}
;;; \end{code}
;;;

;;; \section{libbug-private\#define-structure}
;;;  \label{sec:definestructure}
;;; \index{libbug-private\#define-structure}
;;;
;;; Like ``\#\#define-structure'', but additionally writes the namespaces
;;; to file.
;;;
;;; \begin{code}
{##define-macro
  libbug-private#define-structure
  [|name #!rest members|
   {libbug-private#namespace
    ,(string->symbol
      (string-append "make-"
                     (symbol->string name)))
    ,(string->symbol
      (string-append (symbol->string name)
                     "?"))
    ,@(map [|m|
            (string->symbol
             (string-append (symbol->string name)
                            "-"
                            (symbol->string m)))]
           members)
    ,@(map [|m|
            (string->symbol
             (string-append (symbol->string name)
                            "-"
                            (symbol->string m)
                            "-set!"))]
           members)}
   {at-both-times
    {##namespace (""
                  define
                  define-structure
                  )}
    {define-structure ,name ,@members}
    {##namespace ("libbug-private#"
                  define
                  )}
    {##namespace ("bug#"
                  define-structure
                  )}}]}
;;; \end{code}
;;;
