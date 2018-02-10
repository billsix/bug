;;;//Copyright 2014-2018 - William Emerison Six
;;;//All rights reserved
;;;//Distributed under LGPL 2.1 or Apache 2.0
;;;
;;;
;;;
;;;= Foundations Of Libbug
;;;
;;;== Computation At Compile-Time
;;;[[buglang]]
;;;
;;;This chapterfootnote:[The contents of which is found in
;;;"src/bug-language.bug.scm''.], which was evaluated before the previous chapters, provides
;;;the foundation for computation at compile-time.  Although
;;;the most prevalent code in the previous chapters which executed at compile-time
;;;was for testing, many other computations occurred during compile-time
;;;transparently to the reader.  These other computations produced output
;;;files for namespace mappings and for macro definitions, to be used by other
;;;programs which link against libbug.
;;;
;;;
;;;=== at-compile-time
;;;"at-compile-time" is a macro which "eval"s the form during macro-expansion,
;;;but evaluates to the symbol "noop", thus not affecting
;;;run-time <<<evalduringmacroexpansion>>>.
;;;"Eval"ing during macro-expansion is how the compiler may be augmented with new procedures,
;;;thus treating the compiler as an interpreter.
;;;
;;;(((at-compile-time)))
;;;[source,Scheme,linenums]
;;;----
{##namespace ("bug#" at-compile-time)}
{##define-macro at-compile-time
  [|#!rest forms|
   (eval `{begin
            ,@forms})
   '{quote noop}]}
;;;----
;;;
;;;- On lines 4-5, the unevaluated code which is passed to
;;;"at-compile-time" is evaluated during macro-expansion, thus
;;;at compile-time.  The macro-expansion expands into "\{quote noop\}", so the
;;;form will not evaluate at run-time.
;;;
;;;=== at-both-times
;;;(((at-both-times)))
;;;
;;;"at-both-times", like "at-compile-time", "eval"s the forms
;;;in the compile-time environment, but also in the run-time environment.
;;;
;;;[source,Scheme,linenums]
;;;----
{##namespace ("bug#" at-both-times)}
{##define-macro at-both-times
  [|#!rest forms|
   (eval `{begin
            ,@forms})
   `{begin
      ,@forms}]}
;;;----
;;;
;;;- On lines 4-5, evaluation in the compile-time environment
;;;- On lines 6-7, evaluation in the run-time environment.  The forms
;;;are returned unaltered to Gambit's compiler, thus ensuring that
;;;they are defined in the run-time environment.
;;;
;;;=== at-compile-time-expand
;;;(((at-compile-time-expand)))
;;;
;;;"at-compile-time-expand" allows any procedure to act as a macro.
;;;
;;;[source,Scheme,linenums]
;;;----
{##namespace ("bug#" at-compile-time-expand)}
{##define-macro at-compile-time-expand
  [|#!rest forms|
   (eval `{begin
            ,@forms})]}
;;;----
;;;
;;;This allows the programmer to create "anonymous" macros.
;;;
;;;[source,Scheme]
;;;----
;;;> ({at-compile-time-expand
;;;    (if #t
;;;        ['car]
;;;        ['cdr])}
;;;  '(1 2))
;;;1
;;;> ({at-compile-time-expand
;;;    (if #f
;;;        ['car]
;;;        ['cdr]))
;;;  '(1 2)}
;;;(2)
;;;----
;;;
;;;
;;;
;;;=== Create Files for Linking Against Libbug
;;;
;;;Libbug is a collection of procedures and macros.  Building libbug results
;;;in a dynamic library and a "loadable" library (a .o1 file, for loading
;;;in the Gambit interpreter).
;;;But programs which link against libug will require libbug's
;;;macro definitions and namespace declarations, both of which are not
;;;compiled into the library.  Rather than manually copying all of them to
;;;external files, why not generate them during compile-time?
;;;
;;;At compile time, open one file for the namespaces ("libbug#.scm") and one for the macros
;;;("libbug-macros.scm").  These files will be pure Gambit scheme code, no
;;;libbug syntax enhancements.
;;;
;;;[source,Scheme,linenums]
;;;----
{at-compile-time
;;;----
;;;
;;;footnote:[All of the code through section <<endOfLinkAgainstLibbug>>
;;;is done at compile-time.  The author chose to use subsection numbers to indicate
;;;scope for code which spans multiple pages.]
;;;
;;;==== Create File for Namespaces
;;;
;;;The previous three macros are currently namespaced within libbug, but
;;;external projects which link against libbug may need these namespace
;;;mappings as well.  Towards that goal, open a file
;;;during compile-time and write the namespace mappings
;;;to the file.
;;;
;;;[source,Scheme,linenums]
;;;----
 {##define libbug-headers-file
   (open-output-file '(path: "libbug#.scm" append: #f))}
 (display
  ";;;Copyright 2014-2018 - William Emerison Six
   ;;; All rights reserved
   ;;; Distributed under LGPL 2.1 or Apache 2.0
   {##namespace (\"bug#\" at-compile-time)}
   {##namespace (\"bug#\" at-both-times)}
   {##namespace (\"bug#\" at-compile-time-expand)}
   "
  libbug-headers-file)
;;;----
;;;
;;;==== Create File for Macro Definitions
;;;
;;;
;;;The previous three macros are available within libbug,
;;;but not to programs which link against libbug.  To rectify that, open a file
;;;during compile-time, and write the macro definitions
;;;to the file.
;;;
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
 (##include "config.scm")
 {##define bug-configuration#libbugsharp
   (string-append bug-configuration#prefix "/include/libbug/libbug#.scm")}
;;;
 {##define libbug-macros-file
   (open-output-file '(path: "libbug-macros.scm" append: #f))}
 (display
  (string-append
   ";;;Copyright 2014-2018 - William Emerison Six
    ;;; All rights reserved
    ;;; Distributed under LGPL 2.1 or Apache 2.0
    (##include \"~~lib/gambit#.scm\")
    (##include \"" bug-configuration#libbugsharp "\")
    {##define-macro at-compile-time
      [|#!rest forms|
       (eval `{begin
                ,@forms})
       '{quote noop}]}
    {at-compile-time (##include \"" bug-configuration#libbugsharp "\")}
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
;;;----
;;;
;;;
;;;- On line 1-3, include the "config.scm" file which was preprocessed
;;;by Autoconf, so that the installation directory of libbug is known
;;;at compile-time.
;;;
;;;- On line 13, "libbug#.scm" is imported, so that the generated macros are
;;;namespaced correctly in external projects which import libbug.  In the previous section,
;;;this file is created at compile-time.  Remember that when "libbug-macros.scm" will
;;;be imported by an external project, "libbug#.scm" will exist with all
;;;of the namespaces defined in libbugfootnote:[Marty: "Well Doc, we can
;;;scratch that idea. I mean we can't wait around a year and a half for this
;;;thing to get finished."  Doc Brown:  "Marty it's perfect, you're just not
;;;thinking fourth-dimensionally.  Don't you see, the bridge will exist
;;;in 1985." -Back to the Future 3].
;;;
;;;
;;;
;;;==== Close Files At Compile-Time
;;;
;;;Create a procedure to be invoked
;;;at the end of compilation, to close the compile-time generated
;;;files. Also, the namespace within the generated macro file
;;;is reset to the default namespacefootnote:[This procedure
;;;is called in section <<call-end-of-compilation>>].
;;;
;;;[source,Scheme,linenums]
;;;----
 {define at-end-of-compilation
   [(display
     "
     (##namespace (\"\"))"
     libbug-macros-file)
    (force-output libbug-headers-file)
    (close-output-port libbug-headers-file)
    (force-output libbug-macros-file)
    (close-output-port libbug-macros-file)]}
 }
;;;----
;;;
;;;[[endOfLinkAgainstLibbug]]
;;;
;;;
;;;=== libbug-private#write-and-eval
;;;
;;;Now that those files are open, namespaces will be written
;;;to "libbug#.scm" and macro definitions to "libbug-macros.scm".  However, the
;;;code shouldn't have be to duplicated for each context, as was done for
;;;the previous three macros.
;;;
;;;Create a macro named "write-and-eval" which will write the
;;;unevaluated form plus a newline to the
;;;file, and then return the form so that the compiler actually evaluate
;;;itfootnote:[any procedure which is namespaced to "libbug-private" is
;;;not exported to the namespace file nor the macro file].
;;;
;;;(((libbug-private#write-and-eval)))
;;;[source,Scheme,linenums]
;;;----
{##define-macro libbug-private#write-and-eval
  [|port form|
   (eval `{begin
            (write ',form ,port)
            (newline ,port)})
   form]}
;;;----
;;;
;;;"write-and-eval" writes the form to a file, and evaluates the
;;;form only in the run-time context.  For namespaces in libbug, namespaces
;;;should be valid at
;;;compile-time too.
;;;
;;;
;;;=== libbug-private#namespace
;;;
;;;Namespaces for procedures in libbug need to be available at
;;;compile-time, run-time, and in the namespace file
;;;for inclusion in projects which link to libbug.
;;;
;;;(((libbug-private#namespace)))
;;;[source,Scheme,linenums]
;;;----
{##define-macro libbug-private#namespace
  [|#!rest to-namespace|
   {begin
     (eval `{##namespace ("bug#" ,@to-namespace)})
     `{begin
        {libbug-private#write-and-eval
         libbug-headers-file
         {##namespace ("bug#" ,@to-namespace)}}}}]}
;;;----
;;;
;;;
;;;
;;;
;;;=== if
;;;[[langif]]
;;;In the following, a new version of "if" is defined named
;;;"bug#if", where
;;;"bug#if" takes two zero-argument procedures, treating them
;;;as Church Booleans.  bug#if was first used and described
;;;in section <<langiffirstuse>>.
;;;
;;;
;;;
;;;(((bug#if)))
;;;[source,Scheme,linenums]
;;;----
{libbug-private#namespace if}
{libbug-private#write-and-eval
 libbug-macros-file
 {at-both-times
  {##define-macro if
    [|pred ifTrue ifFalse|
     {##if {and (list? ifTrue)
                (list? ifFalse)
                (not (null? ifTrue))
                (not (null? ifFalse))
                (equal? 'lambda (car ifTrue))
                (equal? 'lambda (car ifFalse))}
           (list '##if pred
                 `{begin ,@(cddr ifTrue)}
                 `{begin ,@(cddr ifFalse)})
           (error "bug#if requires two lambda expressions")}]}}}
;;;----
;;;
;;;- On line 7, "##if" is called.  In Gambit's system of namespacing, "##'
;;;is prefixed to a variable name to specify to use the global namespace for
;;;that variable.
;;;"bug#if" is built on Gambit's implementation of "if", but since
;;;line 1 set the namespace of "if" to "bug#if", "##if" must be
;;;used.
;;;
;;;- On lines 7-12, check that the caller of "bug#if" is passing
;;;lambdas, i.e. has not forgotten that "if" is namespaced to "bug".
;;;
;;;- On line 16, if the caller of "bug#if" has not passed lambdas,
;;;error at compile-time.
;;;
;;;- On line 13-15, evaluate the body of the appropriate lambda, depending
;;;on whether the predicate is true or false.
;;;
;;;
;;;
;;;
;;;=== unit-test
;;;
;;;(((unit-test)))
;;;
;;;Given that the reader now knows how to evaluate at compile-time, implementing
;;;a macro to execute tests at compile-time is trivial.
;;;
;;;- Make a macro called "unit-test", which takes
;;;an unevaluated list of tests.
;;;
;;;- "eval" the tests at compile-time.
;;;If any test evaluates to false, force the compiler to exit in error, producing
;;;an appropriate error message.  If all of the tests pass, the Gambit compiler
;;;continues compiling subsequent definitions.
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
{libbug-private#namespace unit-test}
{libbug-private#write-and-eval
 libbug-macros-file
 {##define-macro unit-test
   [|#!rest tests|
    (eval
     `(if {and ,@tests}
          [''noop]
          [(for-each pp '("Test Failed" ,@tests))
           (error "Tests Failed")]))]}}
;;;----
;;;
;;;
;;;
;;;=== libbug-private#define
;;;"libbug-private#define" is the main procedure-defining procedure used
;;;throughout libbug.  "libbug-private#define" takes a variable name and
;;;a value to be stored in the variable.
;;;
;;;[[libbugdefine]]
;;;(((libbug-private#define)))
;;;[source,Scheme,linenums]
;;;----
{##define-macro
  libbug-private#define
  [|name body|
   `{begin
      {libbug-private#namespace ,name}
      {at-both-times
       {##define ,name ,body}}}]}
;;;----
;;;
;;;"libbug-private#define" defines the procedure/data both at both compile-time
;;;and run-time, and exports the namespace mapping to the appropriate file.
;;;"libbug-private#define" itself is not exported to the macros file.
;;;
;;;On line 6-7, the definition occurs at both compile-time and run-time,
;;;ensuring that the procedure is available for evaluation of tests during compile-time.
;;;
;;;
;;;=== libbug-private#define-macro
;;;Like "libbug-private#define" is built upon "##define",
;;;"libbug-private#define-macro" is built upon "##define-macro".
;;;"libbug-private#define-macro"
;;;ensures that the macro is available both at
;;;run-time and at compile-time. Macros do not get compiled into
;;;libraries however, so for other projects to use them they must be exported
;;;to file.
;;;
;;;The steps will be as follows:

;;;- Write the macro to file
;;;
;;;- Write the macro-expander to file
;;;
;;;- Define the macro-expander within libbug
;;;
;;;- Define the macro.
;;;
;;;
;;;[[libbugdefinemacro]]
;;;
;;;(((libbug-private#define-macro)))
;;;[source,Scheme,linenums]
;;;----
{##define-macro libbug-private#define-macro
  [|name lambda-value|
;;;----
;;;==== Write the Macro to File
;;;
;;;[[writemacrotofile]]
;;;
;;;[source,Scheme,linenums]
;;;----
   (write
    `{at-both-times
;;;----
;;;===== Macro Definition
;;;The macro definition written to file will be imported as
;;;text by other projects
;;;which may have different namespace mappings than libbug.
;;;To ensure that the macro works correctly in other contexts, the
;;;appropriate namespace
;;;mappings must be loaded for the definition of this macro definition.
;;;
;;;[source,Scheme,linenums]
;;;----
      {##define-macro
        ,name
        {lambda ,(cadr lambda-value)
          ,(list 'quasiquote
                 `{##let ()
                    (##include "~~lib/gambit#.scm")
                    (##include ,bug-configuration#libbugsharp)
                    ,(if {and (pair? (caddr lambda-value))
                              (equal? 'quasiquote
                                      (caaddr lambda-value))}
                         [(car (cdaddr lambda-value))]
                         [(append (list 'unquote)
                                  (cddr lambda-value))])})}}
;;;----
;;;
;;;
;;;
;;;- On line 3, the lambda value written to file shall have the same
;;;argument list as the argument list passed to "libbug-private#define-macro"
;;;
;;;[source,Scheme]
;;;----
;;;   > (cadr '[|foo bar| (quasiquote 5)])
;;;   (foo bar)
;;;----
;;;
;;;
;;;- On line 4, the unevaluated form in argument "lambda-value" may
;;;or may not be quasiquoted.  Either way, write a quasiquoted form
;;;to the file.  In the case that the "lambda-value" argument was not
;;;actually intended to be quasiquoted, unquote the lambda's body (which is
;;;done on line 12-13), thereby negating the quasi-quoting from line 4.
;;;
;;;- On lines 4-5, rather than nesting quasiquotes, use the technique
;;;of replacing a would-be nested quasiquote with ",(list 'quasiquote `(...)".
;;;This makes the code more readable <<<paip>>>.  Should the reader
;;;be interested in learning more about nested quasiquotes, Appendix C
;;;of <<<cl>>> is a great reference.
;;;
;;;- On lines 5-7, ensure that the currently unevaluated form will be
;;;evaluated using libbug's namespaces.
;;;Line 5 create a bounded
;;;context for namespace mapping.  Line 6 sets standard Gambit namespace
;;;mappings, line 7 sets libbug's mappings.
;;;
;;;- On line 8-10, check to see if the unevaluated form is quasiquoted.
;;;
;;;[source,Scheme]
;;;----
;;;   > (caaddr '[|foo bar| (quasiquote 5)])
;;;   quasiquote
;;;----
;;;
;;;- On line 11, since it is quasiquoted, grab the content of the
;;;list minus the quasiquoting.
;;;
;;;[source,Scheme]
;;;----
;;;   > (car (cdaddr '[|foo bar| (quasiquote 5)]))
;;;   5
;;;----
;;;
;;;Remember that this value gets wrapped in a quasiquote from line 5
;;;
;;;[source,Scheme]
;;;----
;;;   > (list 'quasiquote (car (cdaddr '[|foo bar|
;;;                                        (quasiquote 5)])))
;;;   `5
;;;----
;;;
;;;- On line 12-13, since this is not a quasiquoted form, just grab
;;;the form, and "unquote" it.
;;;
;;;[source,Scheme]
;;;----
;;;   > (append (list 'unquote) (cddr '[|foo bar| (+ 5 5)]))
;;;   ,(+ 5 5)
;;;----
;;;
;;;Remember, this value gets wrapped in a quasiquote from line 4
;;;
;;;[source,Scheme]
;;;----
;;;   > (list 'quasiquote (append (list 'unquote)
;;;                               (cddr '[|foo bar|
;;;                                         (+ 5 5)])))
;;;   `,(+ 5 5)
;;;   > (eval (list 'quasiquote (append (list 'unquote)
;;;                                     (cddr '[|foo bar|
;;;                                               (+ 5 5)])))
;;;   10
;;;----
;;;
;;;
;;;
;;;
;;;
;;;===== Define a Macro-Expander
;;;
;;;In order to be able to test the macro-expansions effectively, a programmer
;;;needs to be able to access the code generated from the macro as a data structure.
;;;For each macro defined, create a new macro with the same name suffixed with "-expand",
;;;whose body is the same procedure as
;;;"lambda-value"s body, but the result of evaluating that body is "quoted".
;;;In this new procedure's local environment, define "gensym"
;;;so that tests may be writtenfootnote:["##gensym" by definition
;;;creates a unique symbol which the programmer can not directly input, making testing of the macro-expansion
;;;impossible.
;;;Thus, the problem is solved by locally defining a new "gensym" procedure.].
;;;
;;;[source,Scheme,linenums]
;;;----
      {##define-macro
        ,(string->symbol (string-append (symbol->string name)
                                        "-expand"))
        {lambda ,(cadr lambda-value)
          {let ((gensym {let ((gensym-count 0))
                          [{set! gensym-count
				 (+ 1 gensym-count)}
			   (string->symbol
			    (string-append
			     "gensymed-var"
			     (number->string gensym-count)))]}))
            (list 'quote ,@(cddr lambda-value))}}}}
;;;----
;;;
;;;Finish writing the macro to file which was started in section <<writemacrotofile>>.
;;;
;;;[source,Scheme,linenums]
;;;----
    libbug-macros-file)
   (newline libbug-macros-file)
;;;----
;;;==== Define Macro and Run Tests Within Libbug
;;;The macro has been exported to a file for use by projects which link against libbug,
;;;but it must also be defined during compilation.
;;;
;;;[source,Scheme,linenums]
;;;----
   `{begin
;;;----
;;;
;;;Namespace the procedure and the expander.
;;;
;;;[source,Scheme,linenums]
;;;----
      {libbug-private#namespace ,name}
      {libbug-private#namespace ,(string->symbol
				  (string-append (symbol->string name)
						 "-expand"))}
;;;----
;;;
;;;Create the expander similarly to the previous section.
;;;
;;;[source,Scheme,linenums]
;;;----
      {at-both-times
       {##define-macro
         ,(string->symbol
           (string-append (symbol->string name)
                          "-expand"))
         {lambda ,(cadr lambda-value)
           {let ((gensym {let ((gensym-count 0))
                           [{set! gensym-count
				  (+ 1 gensym-count)}
			    (string->symbol
			     (string-append
			      "gensymed-var"
			      (number->string gensym-count)))]}))
             (list 'quote ,@(cddr lambda-value))}}}}
;;;----
;;;
;;;Define the macro.
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
      {at-both-times
       {##define-macro
         ,name
         ,lambda-value}}}]}
;;;
;;;----
;;;
;;;
;;;=== macroexpand-1
;;;
;;;"macroexpand-1" is syntactic sugar which allows the programmer to test macro-expansion by writing
;;;
;;;[source,Scheme]
;;;----
;;;(equal? {macroexpand-1 {aif (+ 5 10)
;;;                           (* 2 bug#it)}}
;;;      '{let ((bug#it (+ 5 10)))
;;;         (if bug#it
;;;             [(* 2 bug#it)]
;;;             [#f])})
;;;----
;;;
;;;instead of
;;;
;;;[source,Scheme]
;;;----
;;;(equal? {aif-expand (+ 5 10)
;;;                   (* 2 bug#it))}
;;;      '{let ((bug#it (+ 5 10)))
;;;         (if bug#it
;;;             [(* 2 bug#it)]
;;;             [#f])})
;;;----
;;;
;;;(((macroexpand-1)))
;;;[source,Scheme,linenums]
;;;----
{libbug-private#define-macro
 macroexpand-1
 [|form|
  {let* ((m (car form))
         (the-expander (string->symbol
                        (string-append (symbol->string m)
                                       "-expand"))))
    `(,the-expander ,@(cdr form))}]}
;;;----
;;;
;;;
;;;
;;;=== libbug-private#define-structure
;;;[[definestructure]]
;;;(((libbug-private#define-structure)))
;;;
;;;Like "##define-structure", but additionally writes the namespaces
;;;to filefootnote:[In the following, "##define-structure" is defined at
;;;compile-time, because Gambit does not define "##define-structure" at compile-time.].
;;;
;;;[source,Scheme,linenums]
;;;----
{at-compile-time
 {##define-macro ##define-structure
   [|#!rest args| `{define-structure ,@args}]}}
{##define-macro
  libbug-private#define-structure
  [|name #!rest members|
   `{begin
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
                     )}}}]}
;;;----
;;;
