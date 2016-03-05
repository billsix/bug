;;; %Copyright 2014-2016 - William Emerison Six
;;; %All rights reserved
;;; %Distributed under LGPL 2.1 or Apache 2.0
;;;
;;; \documentclass[twoside]{book}
;;; \pagenumbering{gobble}
;;; \usepackage[paperwidth=7.44in, paperheight=9.68in,bindingoffset=0.2in, left=0.5in, right=0.5in]{geometry}
;;; \usepackage{times}
;;; \usepackage{listings}
;;; \usepackage{courier}
;;; \usepackage{color}
;;; \usepackage{makeidx}
;;; \usepackage{amsmath}
;;; \usepackage{titlesec}
;;; \lstnewenvironment{code}[1][]%
;;;  {  \noindent
;;;     \minipage{\linewidth}
;;;     \vspace{0.5\baselineskip}
;;;     \lstset{language=Lisp, frame=single,framerule=.8pt, numbers=left,
;;;             basicstyle=\ttfamily,
;;;             identifierstyle=\ttfamily,keywordstyle=\ttfamily,
;;;             showstringspaces=false,#1}}
;;;  {\endminipage}
;;;
;;; \lstnewenvironment{examplecode}[1][]%
;;;  {  \noindent
;;;     \minipage{\linewidth}
;;;     \vspace{0.5\baselineskip}
;;;     \lstset{language=Lisp, frame=single,framerule=.0pt,
;;;             basicstyle=\ttfamily,
;;;             identifierstyle=\ttfamily,keywordstyle=\ttfamily,
;;;             showstringspaces=false,#1}}
;;;  {\endminipage}
;;;
;;; \raggedbottom
;;; \makeindex
;;; \titleformat{\chapter}[display]
;;;  {\normalsize \huge  \color{black}}%
;;;  {\flushright\normalsize \color{black}%
;;;   \MakeUppercase{\chaptertitlename}\hspace{1ex}%
;;;   {\fontfamily{courier}\fontsize{60}{60}\selectfont\thechapter}}%
;;;  {10 pt}%
;;;  {\bfseries\huge}%
;;; \date{}
;;; \begin{document}
;;;
;;; % Article top matter
;;; \title{Computation At Compile-Time \\
;;;    \vspace{4 mm} \large{and the implementation of libbug}}
;;;
;;; \author{Bill Six}

;;; \maketitle
;;; \null\vfill
;;; \noindent
;;; Copyright \textcopyright 2014-2016 -- William Emerison Six\\
;;; All rights reserved \\
;;; Distributed under LGPL 2.1 or Apache 2.0 \\
;;; Source code - http://github.com/billsix/bug \\
;;; Book generated from Git commit ID - \input{version.tex}
;;; \newpage
;;; \break 

;;; \chapter*{Preface}
;;; This is a book about compiler design for people who have no interest
;;; in studying compiler design.  ...Wait... then who will want to read the book?
;;; Let me try this again...  This book is the study of
;;; source code which is discarded by the compiler, having no representation in
;;; the generated machine code.
;;; ...Ummm, still not right...  This book is about viewing a compiler not only
;;; as a means of translating source code into an executable,
;;;  but also viewing it as an interpreter capable of any
;;; general purpose computation.  ...Closer, but who cares about that... I think I got it
;;; now - This is a book about ``Testing at Compile-Time''!
;;;
;;; What do I mean by that?  Let's say you're looking at source code with which
;;; you are unfamiliar, such as the following:
;;;
;;; \begin{examplecode}
;;;{define
;;; "list#"
;;; permutations
;;; [|lst|
;;;  (if (null? lst)
;;;      ['()]
;;;      [{let permutations ((lst lst))
;;;        (if (null? lst)
;;;          [(list '())]
;;;          [(flatmap
;;;            [|x|
;;;             (map [|y| (cons x y)]
;;;                  (permutations (remove x lst)))]
;;;            lst)])}])]
;;; \end{examplecode}
;;;
;;; So what does the code do?  How did the author intend for it to be used?
;;; In trying to answer those questions, fans of statically-typed programming
;;; languages might lament the lack of types, as types help them reason about
;;; programs, and help them deduce where to look to find more information.
;;; In trying to answer those questions,
;;; fans of dynamically-typed languages might argue ``Look at the tests!'',
;;; as tests ensure the code functions in a user-specified way, and also
;;; serve as a form of documentation.  But
;;; where are those tests?  Probably in some other file, whose filesystem path is
;;; similar to the current file's path, (e.g, src/com/BigCorp/HugeProject/Foo.java
;;; -\textgreater test/com/BigCorp/HugeProject/FooTest.java)
;;; Then you'd have to find the file, open the file, look through it
;;; while ignoring tests which are
;;; for other methods.  Frankly, it's too much work, and interrupts the flow
;;; of coding, at least for me.
;;;
;;; What else could be done?  Well, in this book, which is the
;;; implementation of a library called ``libbug''\footnote{Bill's Utilities
;;; for Gambit}, tests are specified as part of the procedure's definition,
;;; they are run at compile-time, and should any test fail the compiler will
;;; exit and not produce the libbug library, much like a type error in a
;;; statically-typed language.  Furthermore, the book you are currently reading
;;; is embedded into the source code of libbug, is generated only upon successful
;;; compilation of libbug, so it couldn't exist if a single test
;;; failed.  So where are these tests then?
;;;
;;; The very alert reader may have noticed that the opening '\{' in the definition
;;; of ``permutations'' was not closed, and that's because during procedure definition,
;;; we can specify tests which are to be run at compile-time.
;;;
;;; \begin{examplecode}
;;; (equal? (permutations '())
;;;         '())
;;; (equal? (permutations '(1))
;;;         '((1)))
;;; (equal? (permutations '(1 2))
;;;         '((1 2)
;;;           (2 1)))
;;; (equal? (permutations '(1 2 3))
;;;         '((1 2 3)
;;;           (1 3 2)
;;;           (2 1 3)
;;;           (2 3 1)
;;;           (3 1 2)
;;;           (3 2 1)))
;;; }
;;; \end{examplecode}
;;;
;;; Now, the closing '\}' is there, and the ``permutations'' procedure is defined.
;;;
;;; So why does this matter?
;;; Towards answering the questions ``so what does the code do?'' and ``how did the author
;;; intend for it to be used?'', there is no guessing involved.  The fact that the
;;; tests are collocated with the procedure definition means that the reader can
;;; read the tests without switching between files, perhaps reading the tests
;;; before reading the procedure definition.  And the reader
;;; may not even read the definition at all if the tests gave them enough information
;;; to use the procedure.  But should the reader want to understand the definition, the
;;; tests have been designed to help the reader incrementally understand
;;; the procedure under test.  
;;;
;;; Wait a second. If those tests are defined in the source code itself, won't they
;;; be in the executable?  And won't they run every time I run the executable?
;;; That would be unacceptable, as it would increase the size of the binary and
;;; slow downthe program at startup.  Fortunately, the
;;; answer to both questions is no, because in Chapter~\ref{sec:buglang} I show how to specify
;;; that certain code should be interpreted by the compiler, instead of code to be
;;; compiled\footnote{Which is also why this book is
;;; called the more general ``Computation at Compile-Time'' instead of ``Testing
;;; at Compile-Time''}.  Lisp implementations such as Gambit are particularly well
;;; suited for this style of programming since unevaluated Lisp code is
;;; specified using a data structure of the language, and because the compiler,
;;; itself being a Lisp program, is an interpreter of the same language which
;;; it compiles, fully capable of being augmented with user-defined code.
;;;
;;;
;;; \tableofcontents
;;; \break
;;; \chapter{Introduction}
;;; \pagenumbering{arabic}
;;; Libbug is Bill's Utilities for Gambit Scheme, a ``standard library'' of procedures,
;;; since Scheme itself is a small language.  Libbug also provides utilities for
;;; general-purpose evaluation at compile-time, a
;;; compile-time test framework, and a Scheme preprocessor to
;;; provide a lambda literal syntax.  Programs written using libbug can be
;;; programmed in a relatively unobstructive ``literate programming''
;;; style, so that programs can be read linearly in a book form.

;;; \section{Prerequisites}
;;;
;;; The reader is assumed to be somewhat familiar both with Scheme, and with Common Lisp-style
;;; macros (which Gambit provides).  Suggested reading is ``The Structure and
;;; Interpretation of Computer Programs'' by Sussman and Abelson, ``ANSI Common
;;; Lisp'' by Paul Graham, and ``On Lisp'' by Paul Graham.  These books inspired many
;;; ideas within BUG.
;;;
;;; \section{Conventions}
;;; Code which is part of libbug will have an outline and line numbers.
;;;
;;; \begin{code}
;; This is Scheme source code.
;;; \end{code}
;;;
;;; 
;;; Example code which is not part of libbug will not have an outline, nor line
;;; numbers.
;;;
;;; \begin{examplecode}
;;; (+ 1 ("This is NOT part of libbug"))
;;; \end{examplecode}

;;; In libbug, the notation

;;; \begin{examplecode}
;;; (fun arg1 arg2)
;;; \end{examplecode}
;;;
;;;  means evaluate ``fun'', ``arg1''
;;; and ``arg2'', and then apply ``fun'' to ``arg1'' and ``arg2''.  This notation
;;; is standard Scheme, but Scheme uses the same notation for macro application.
;;; This can cause some confusion to a reader.  To attempt to minimize the confusion,
;;; within BUG the notation

;;; \begin{examplecode}
;;; {fun1 arg1 arg2}
;;; \end{examplecode}

;;;      is used to denote to
;;; the reader that the standard evaluation rules do not necessarily apply to
;;; all arguments.  For instance, in

;;; \begin{examplecode}
;;;{define x 5}
;;; \end{examplecode}

;;; \{\} are used because ``x''
;;; is a new variable, and as such, cannot currently evaluate to anything.
;;;
;;;
;;;
;;; \chapter{Compile-Time Language}
;;;
;;; This chapter provides a quick tour of computer language which is interpreted
;;; by the compiler, but which has no direct representation in the executable.
;;; But first, let's discuss was is meant by the word ``language''.
;;;
;;; In ``Introduction to Automata Theory, Languages, and Computation'', Hopcroft,
;;; Motwani, and Ullman define language as ``A set of strings all of which are chosen
;;; from some $\Sigma$ $\star$, where $\Sigma$ is a particular alphabet, is called
;;; a language''.  They further state ``In automata theory, a problem is the question
;;; of deciding whether a given string is a member of some particular language''.
;;; Languages have grammars, which formally define whether or not a given string is in the
;;; language.
;;;
;;; In practice, if your compiler successfully compiles your code, congratulations!
;;; The compiler decided that your code is in fact a valid string in the language
;;; accepted by the compiler.  But does all of that language have a representation
;;; in the generated machine code?  No, it does not.

;;; \section{C}
;;;Consider the following C code:
;;;
;;; \begin{examplecode}
;;;#include <stdio.h>
;;;#define square(x) ((x) * (x))
;;;int fact(int n);
;;;int main(int argc, char* argv[]){
;;;#ifdef DEBUG
;;;  printf("Debug - argc = %d\n", argc);
;;;#endif
;;;  printf("%d\n",square(fact(argc)));
;;;  return 0;
;;;}
;;;int fact(int n){
;;;  return n == 0
;;;    ? 1
;;;    : n * fact(n-1);
;;;}
;;; \end{examplecode}
;;;
;;; On the first line, the \#include preprocessor command, specified by the C grammar,
;;; is language that the compiler
;;; is intended to interpret but not to compile, instructing the compiler to
;;; read the file ``stdio.h''
;;; from the filesystem and to splice the content
;;; into the current C file.  The include command
;;; itself has no representation in the machine code, although the contents
;;; of the included file may.
;;;
;;; The second line, also part of the C grammar, defines a C macro, which
;;; is a procedure for concatenating strings which takes text strings as input,
;;; and outputs text strings.  This expansion happens before the compiler does anything
;;; else.  For example, if using GCC as a compiler, if you run just the the C preprocessor
;;; ``cpp'' on the above C code, you'll see that
;;;
;;; \begin{examplecode}
;;;  printf("%d\n",square(fact(argc)));
;;; \end{examplecode}
;;;
;;; expands into
;;;
;;; \begin{examplecode}
;;;  printf("%d\n",((fact(argc)) * (fact(argc))));
;;; \end{examplecode}
;;;
;;; The third line, also part of the C grammar, defines a function prototype, so that
;;; the compiler knows the argument types and return type for a function called ``fact''.
;;; This code is language, yet still has no representation in the machine code,
;;; as it is language used by the compiler to determine the types for the function
;;; call to ``fact'' on line 8, since ``fact'' has not yet been defined.
;;;
;;; The fourth through tenth line is a function definition, which will have
;;; a representation in the machine code.  However, line 5 is language
;;; to be interpreted by the compiler, referencing a variable defined
;;; only during compilation, to detemine whether or not line 6 should be
;;; compiled.
;;;
;;; \section{C++}
;;;
;;; C++ inherits C's macros, but with the introduction
;;; of templates, C++'s compile time language
;;; accidently became Turing complete.  This means that
;;; theorectically, anything that can be
;;; calculated by a computer can be done using templates running
;;; at compile time.  In practice it is not pragmatic to do so.
;;;
;;; The following is an example of calculating the factorial of
;;; 3, both using C++ functions, and using C++'s templates.
;;;
;;; \begin{examplecode}
;;; #include <iostream>
;;; template <unsigned int n>
;;; struct factorial {
;;;     enum { value = n * factorial<n - 1>::value };
;;; };
;;; template <>
;;; struct factorial<0> {
;;;     enum { value = 1 };
;;; };
;;; int fact(int n){
;;;   return n == 0
;;;     ? 1
;;;     : n * fact(n-1);
;;; }
;;; int main(int argc, char* argv[]){
;;;   std::cout << factorial<3>::value << std::endl;
;;;   std::cout << fact(3) << std::endl;
;;;   return 0;
;;; }
;;; \end{examplecode}

;;; By disassembling the machine code using ``objdump -D'', you can
;;; see the drastic difference in the generated code
;;;
;;; \begin{examplecode}
;;; 400850:       be 06 00 00 00          mov    $0x6,%esi
;;; 400855:       bf c0 0d 60 00          mov    $0x600dc0,%edi
;;; 40085a:       e8 41 fe ff ff          callq  4006a0 <_ZNSolsEi@plt>
;;;  .......
;;;  .......
;;;  .......
;;; 40086c:       bf 03 00 00 00          mov    $0x3,%edi
;;; 400871:       e8 a0 ff ff ff          callq  400816 <_Z4facti>
;;; 400876:       89 c6                   mov    %eax,%esi
;;; 400878:       bf c0 0d 60 00          mov    $0x600dc0,%edi
;;; 40087d:       e8 1e fe ff ff          callq  4006a0 <_ZNSolsEi@plt>
;;; \end{examplecode}




;;; So that was a tad bit boring.  Why care about this?
;;; It's to demonstrate that there is no compiler or interpreter binary,
;;; computer languages implementations are on a spectrum.
;;; C has two distince sub-''languages'', one for compile-time, and one
;;; for run-time;
;;; both of which have variables and procedure definitions.
;;;
;;; \chapter{The Implementation of libbug}
;;;
;;; This chapter defines a standard library of Scheme procedures and macros
;;; \footnote{The code within this section is all found in
;;; ``src/main.bug.scm''.}, along with tests which are run as part of the
;;; compilation process.
;;;
;;;
;;; Libbug defines extensions to the Scheme language, implemented via
;;; macros.  They are ``libbug\#define'', and ``libbug\#define-macro''.
;;; Any variable namespaced with ``libbug'' is not included in the library
;;; or associated files, they are meant for private use within the implementation
;;; of libbug.  They are implemented in ``bug-language.bug.scm''\footnote{Although
;;; the filename is ``bug-language.bug.scm'', ``bug-language.scm'' is imported.  This
;;; is because ``bug-gscpp'' preprocesses the bug file, and outputs a standard Gambit
;;; Scheme file, with a different filename}, which will now
;;; be imported.  How to use these procedure-defining procedures will be explained
;;; incrementally, and their implementation is defined in
;;; chapter~\ref{sec:buglang}.
;;;
;;; \begin{code}
(include "bug-language.scm")
(##namespace ("libbug#" define))
(##namespace ("libbug#" define-macro))
;;;\end{code}

;;;
;;; \section*{lang\#noop}
;;; The first definition is ``noop'', a procedure which takes no arguments and
;;; which evaluates to the symbol 'noop.  noop is defined using ``libbug\#define''
;;; instead of Scheme's regular define.

;;; \index{lang\#noop}
;;; \begin{code}
{define
  "lang#"
  noop
  ['noop]
;;; \end{code}

;;; \begin{itemize}
;;;   \item On line 1, the libbug\#define macro\footnote{defined in section ~\ref{sec:libbugdefine} } is invoked.
;;;   \item On line 2, a namespace
;;;   \item On line 3, the variable name, which will be declared in the
;;;         namespace defined on line 2.
;;;   \item On line 4, the lambda literal to be stored into the variable.
;;;         BUG includes a Scheme preprocessor ``bug-gscpp'',
;;;         which expands lambda literals
;;;         into lambdas.  In this case ``['noop]'' is expanded into
;;;         ``(lambda () 'noop)''
;;; \end{itemize}
;;; \subsection*{Test}
;;; \begin{code}
  (equal? (noop) 'noop)}
;;; \end{code}
;;;
;;; \begin{itemize}
;;;  \item  On line 1, an expression which evaluates to a boolean is defined.
;;;  This is a
;;; test which will be evaluated at compile-time, and should the test fail,
;;; the build process will fail and no shared library, nor the document which
;;; you are currently reading, will be created.  The
;;; test runs at compile time, but is not present in the resulting
;;; library.
;;; \end{itemize}
;;;
;;; \section*{lang\#identity}
;;;
;;; \index{lang\#identity}
;;; \begin{code}
{define
  "lang#"
  identity
  [|x| x]
;;; \end{code}
;;; \begin{itemize}
;;;   \item On line 4, ``bug-gscpp'' expands ``[\textbar x\textbar x]'' to ``(lambda (x) x)''.  This expansion
;;;         works with multiple arguments, as long as they are between the ``\textbar''s.
;;; \end{itemize}

;;; \subsection*{Test}
;;; \begin{code}
  (equal? "foo" (identity "foo"))}
;;; \end{code}
;;;
;;;

;;; \section*{list\#all?}
;;; Like and, but takes a list instead of a variable number of arguments.
;;;
;;; \index{list\#all?}
;;; \begin{code}
{define
  "list#"
  all?
  [|lst|
   (if (null? lst)
       [#t]
       [(if (not (car lst))
            [#f]
            [(all? (cdr lst))])])]
;;; \end{code}
;;; \begin{itemize}
;;;   \item On line 5, if, which is currently namespaced to lang\#if, takes
;;;         lambda expressions for the two parameters. I like to think of
;;;         \#t, \#f, and if as the following:
;;;
;;; \begin{examplecode}
;;;{define #t [|t f| (t)]}
;;;{define #f [|t f| (f)]}
;;;{define lang#if [|b t f| (b t f)]}
;;; \end{examplecode}
;;;
;;; As such, if would not be a special form, and is more consistent with the
;;; rest of BUG.
;;;
;;; \end{itemize}
;;;
;;; libbug\#define can take more than one test as parameters.
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (all? '())
  (all? '(1))
  (all? '(#t))
  (all? '(#t #t))
  (not (all? '(#f)))
  (not (all? '(#t #t #t #f)))
  }
;;; \end{code}
;;;
;;; Tests in libbug are defined for two purposes.  First, to ensure
;;; that expected behavior of a procedure does not change when that procedure's internal
;;; definition has changed.  Second, as a form of documentation of the procedure.
;;; Libbug is unique\footnote{as far as the author knows} in that the tests are collocated with
;;; the procedure definitions.  As such, the reader is encouraged to read the tests for a
;;; procedure before reading the implementation; since in many cases, the tests are designed
;;; specifically to walk the reader through the implementation.
;;;
;;; \section*{lang\#satisfies-relation}

;;; When writing multiple tests, why explicitly invoke the procedure repeatedly,
;;; with varying inputs and outputs?  Instead, provide the procedure, and a list
;;; of input/output pairs.
;;;
;;; \index{lang\#satisfies-relation}
;;; \begin{code}
{define
  "lang#"
  satisfies-relation
  [|fn list-of-pairs|
   (all? (map [|pair| (equal? (fn (car pair))
                              (cadr pair))]
              list-of-pairs))]
;;; \end{code}
;;; \subsection*{Test}
;;; \begin{code}
  (satisfies-relation
   all?
   '(
     (() #t)
     ((1) #t)
     ((#t) #t)
     ((#t #t) #t)
     ((#f) #f)
     ((#t #t #t #f) #f)))
;;; \end{code}
;;; \subsection*{Test}
;;; \begin{code}
  (satisfies-relation
   [|x| (+ x 1)]
   '(
     (0 1)
     (1 2)
     (2 3)
     ))}
;;; \end{code}

;;; \section*{lang\#compose}

;;; \index{lang\#compose}
;;; \begin{code}
{define-macro
  "lang#"
  compose
  [|#!rest fns|
   (if (null? fns)
       ['identity]
       [{let ((args (gensym)))
          `[|#!rest ,args|
            ,{let compose ((fns fns))
               (if (null? (cdr fns))
                   [`(apply ,(car fns)
                            ,args)]
                   [`(,(car fns)
                      ,(compose (cdr fns)))])}]}])]
;;; \end{code}
;;;
;;; libbug\#define-macro \footnote{defined in section ~\ref{sec:libbugdefinemacro}}
;;; is a wrapper around Gambit's \#\#define-macro\footnote{which is very similar to Common
;;; Lisp's macro system}, but libbug\#define-macro only allows the lambda literal
;;; syntax.
;;;
;;; Libbug is a library, meant to be used by other projects.  From libbug, these
;;; projects will require namespace definitions, as well as macro definitions.
;;; As such, besides defining the macro, libbug\#define-macro also exports the
;;; namespace definition and the macro definitions to external files.
;;;
;;; If the reader does not understand the macro definition above, don't worry,
;;; understanding the macro definitions is not required to understand the rest
;;; of the content of this book.  The reader should at least though understand
;;; how to use the macros, which can be learned by reading the associated tests.
;;;
;;; \subsection*{Tests}
;;; \begin{code}
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
          11/13)
;;; \end{code}
;;; \subsection*{Code Expansion Tests}
;;; ``macroexpand-1'' expands the unevaluated code passed to the
;;; macro into the new form, which the compiler would have then compiled
;;; if ``macroexpand-1'' had not been there.  But, how should ``gensyms'' be
;;; handled, since by definition it creates symbols which cannot be entered
;;; into a program?  During the expansion of ``macroexpand-1'', ``gensym''
;;; is overridden into a procedure
;;; which expands into symbols like ``gensymed-var1'', ``gensymed-var2'', etc.  Each
;;; call during a macroexpansion generates a new, unique symbol.  Although this symbol
;;; may clash with symbols in the expanded code, this is not a problem, as these
;;; symbols are only generated in the call to ``macroexpand-1''.  As such,
;;; ``eval''ing code generated from ``macroexpand-1'' is not recommended.
;;;
;;;
;;; \begin{code}
  (equal? (macroexpand-1 (compose))
          'identity)
  (equal? (macroexpand-1 (compose [|x| (* x 2)]))
          '[|#!rest gensymed-var1|
            (apply [|x| (* x 2)]
                   gensymed-var1)])
  (equal? (macroexpand-1 (compose [|x| (+ x 1)]
                                  [|x| (* x 2)]))
          '[|#!rest gensymed-var1|
            ([|x| (+ x 1)]
             (apply [|x| (* x 2)]
                    gensymed-var1))])
  (equal? (macroexpand-1 (compose [|x| (/ x 13)]
                                  [|x| (+ x 1)]
                                  [|x| (* x 2)]))
          '[|#!rest gensymed-var1|
            ([|x| (/ x 13)]
             ([|x| (+ x 1)]
              (apply [|x| (* x 2)]
                     gensymed-var1)))])
  }
;;; \end{code}
;;; \section*{list\#any?}
;;;
;;; For the remaining procedures, if the tests do an adequate job of explaining
;;; the code, there will be no written documentation.
;;;
;;; \index{list\#any?}
;;; \begin{code}
{define
  "list#"
  any?
  [|lst|
   (if (null? lst)
       [#f]
       [(if (car lst)
            [#t]
            [(any? (cdr lst))])])]
;;; \end{code}
;;; \subsection*{Test}
;;; \begin{code}
  (satisfies-relation
   any?
   '(
     (() #f)
     ((1) #t)
     ((#t) #t)
     ((#t #t) #t)
     ((#f) #f)
     ((#t #t #t #f) #t)))
  }
;;; \end{code}


;;; \section*{lang\#complement}
;;;
;;; \index{lang\#complement}
;;; \begin{code}
{define
  "lang#"
  complement
  [|f|
   [|#!rest args| (not (apply f args))]]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   pair?
   '(
     (1 #f)
     ((1 2) #t)
     ))
  (satisfies-relation
   (complement pair?)
   '(
     (1 #t)
     ((1 2) #f)
     ))
  }
;;; \end{code}



;;; \section*{list\#copy}
;;;   Creates a copy of the list data structure.  Does not copy the contents
;;;   of the list.
;;;
;;; \index{list\#copy}
;;; \begin{code}
{define
  "list#"
  copy
  [|l| (map identity l)]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((a '(1 2 3 4 5)))
    (and (equal? a (copy a))
         (not (eq? a (copy a))))}
  }
;;; \end{code}


;;; \section*{list\#proper?}
;;;   Tests that the argument is a list that is properly
;;;   termitated.  Will not terminate on a circular list.
;;;
;;; \index{list\#proper?}
;;; \begin{code}
{define
  "list#"
  proper?
  [|l| (if (null? l)
           [#t]
           [(if (pair? l)
                [(proper? (cdr l))]
                [#f])])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   proper?
   '(
     (4 #f)
     ((1 2) #t)
     ((1 2 . 5) #f)
     ))}
;;; \end{code}




;;; \section*{list\#first}
;;;
;;; list\#first uses Gambit's keyword syntax.  In the code, ``onNull'' is
;;; an optional argument, with a default value of the value in the ``noop''
;;; variable.  The first test does not provide a value for ``onNull'',
;;; the second test does, which demonstrates the syntax.
;;;
;;; \index{list\#first}
;;; \begin{code}
{define
  "list#"
  first
  [|lst #!key (onNull noop)|
   (if (null? lst)
       [(onNull)]
       [(car lst)])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   first
   '(
     (() noop)
     ((1 2 3) 1)
     ))
  (satisfies-relation
   [|l| (first l onNull: [5])]
   '(
     (() 5)
     ((1 2 3) 1)
     ))}
;;; \end{code}


;;; \section*{list\#but-first}
;;; \index{list\#but-first}
;;; \begin{code}
{define
  "list#"
  but-first
  [|lst #!key (onNull noop)|
   (if (null? lst)
       [(onNull)]
       [(cdr lst)])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   but-first
   '(
     (() noop)
     ((1 2 3) (2 3))
     ))
  (satisfies-relation
   [|l| (but-first l onNull: [5])]
   '(
     (() 5)
     ((1 2 3) (2 3))
     ))}
;;; \end{code}

;;; \section*{list\#last}
;;; \index{list\#last}
;;; \begin{code}
{define
  "list#"
  last
  [|lst #!key (onNull noop)|
   (if (null? lst)
       [(onNull)]
       [{let last ((lst lst))
          (if (null? (cdr lst))
              [(car lst)]
              [(last (cdr lst))])}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   last
   '(
     (() noop)
     ((1) 1)
     ((2 1) 1)
     ))
  (satisfies-relation
   [|l| (last l onNull: [5])]
   '(
     (() 5)
     ((2 1) 1)
     ))}
;;; \end{code}
;;; \section*{list\#but-last}
;;; \index{list\#but-last}
;;; \begin{code}
{define
  "list#"
  but-last
  [|lst #!key (onNull noop)|
   (if (null? lst)
       [(onNull)]
       [{let but-last ((lst lst))
          (if (null? (cdr lst))
              ['()]
              [(cons (car lst)
                     (but-last (cdr lst)))])}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   but-last
   '(
     (() noop)
     ((1) ())
     ((2 1) (2))
     ((3 2 1) (3 2))
     ))
  (satisfies-relation
   [|l| (but-last l onNull: [5])]
   '(
     (() 5)
     ((3 2 1) (3 2))
     ))
  }
;;; \end{code}
;;; \section*{list\#filter}
;;; \index{list\#filter}
;;; \begin{code}
{define
  "list#"
  filter
  [|p? lst|
   {let filter ((lst lst))
     (if (null? lst)
         ['()]
         [{let ((first (car lst)))
            (if (p? first)
                [(cons first (filter (cdr lst)))]
                [(filter (cdr lst))])}])}]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   [|l| (filter [|x| (not (= 4 x))]
                l)]
   '(
     (() ())
     ((4) ())
     ((1 4) (1))
     ((4 1 4) (1))
     ((2 4 1 4) (2 1))
     ))}
;;; \end{code}
;;; \section*{list\#remove}
;;; \index{list\#remove}
;;; \begin{code}
{define
  "list#"
  remove
  [|x lst|
   (filter [|y| (not (equal? x y))]
           lst)]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   [|l| (remove 5 l)]
   '(
     ((1 5 2 5 3 5 4 5 5) (1 2 3 4))
     ))}
;;; \end{code}

;;; \section*{list\#fold-left}
;;;    Reduce the list to a scalar by applying the reducing function repeatedly,
;;;    starting from the ``left'' side of the list
;;;
;;; \index{list\#fold-left}
;;; \begin{code}
{define
  "list#"
  fold-left
  [|fn initial lst|
   {let fold-left ((acc initial)
                   (lst lst))
     (if (null? lst)
         [acc]
         [(fold-left (fn acc
                         (car lst))
                     (cdr lst))])}]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   [|l| (fold-left + 5 l)]
   '(
     (() 5)
     ((1) 6)
     ((1 2) 8)
     ((1 2 3 4 5 6) 26)
     ))
  (satisfies-relation
   [|l| (fold-left - 5 l)]
   '(
     (() 5)
     ((1) 4)
     ((1 2) 2)
     ((1 2 3 4 5 6) -16)))}
;;; \end{code}

;;; \section*{list\#fold-right}
;;;    Reduces the list to a scalar by applying the reducing
;;;    function repeatedly,
;;;    starting from the ``right'' side of the list
;;;
;;; \index{list\#fold-right}
;;; \begin{code}
{define
  "list#"
  fold-right
  [|fn initial lst|
   {let fold-right ((acc initial) (lst lst))
     (if (null? lst)
         [acc]
         [(fn (car lst)
              (fold-right acc (cdr lst)))])}]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   [|l| (fold-right - 0 l)]
   '(
     (() 0)
     ((1) 1)
     ((2 1) 1)
     ((3 2 1) 2)
     ))}
;;; \end{code}

;;; \section*{list\#append!}
;;;   Like append, but recycles the last cons cell, so it's
;;;   faster, but mutates the input.
;;;
;;; \index{list\#append!}
;;; \begin{code}
{define
  "list#"
  append!
  [|lst x|
   (if (null? lst)
       [x]
       [{let ((head lst))
          {let append! ((lst lst))
            (if (null? (cdr lst))
                [(set-cdr! lst x)]
                [(append! (cdr lst))])}
          head}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (equal? (append! '()
                   '(5))
          '(5))
  (equal? (append! '(1 2 3)
                   '(5))
          '(1 2 3 5))
  {let ((a '(1 2 3)))
    (append! a '(5))
    (not (equal? '(1 2 3) a))}
  }
;;; \end{code}

;;; \section*{list\#scan-left}
;;;   Like fold-left, but every intermediate value
;;;   of fold-left's accumulator is put onto the resulting list
;;;
;;; \index{list\#scan-left}
;;; \begin{code}
{define
  "list#"
  scan-left
  [|fn initial lst|
   {let scan-left ((acc initial) (acc-list (list initial)) (lst lst))
     (if (null? lst)
         [acc-list]
         [{let ((newacc (fn acc
                            (car lst))))
            (scan-left newacc
                       (append! acc-list (list newacc))
                       (cdr lst))}])}]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  ;; (calulating factorials via scan-left
  (satisfies-relation
   [|l| (scan-left * 1 l)]
   '(
     (() (1))
     ((2) (1 2))
     ((2 3) (1 2 6))
     ((2 3 4) (1 2 6 24))
     ((2 3 4 5 ) (1 2 6 24 120))
     ))}
;;; \end{code}



;;; \section*{list\#flatmap}
;;;  Maps a prodecure to a list, but the result of the
;;;  procedure application will be a list.  Aggregate all
;;;  of those lists together.
;;;
;;; \index{list\#flatmap}
;;; \begin{code}
{define
  "list#"
  flatmap
  [|fn lst|
   (fold-left append '() (map fn lst))]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   [|l| (flatmap [|x| (list x
                            (+ x 1)
                            (+ x 2))]
                 l)]
   '(
     ((10 20) (10 11 12 20 21 22))
     ))}
;;; \end{code}
;;; \section*{list\#enumerate-interval}
;;; \index{list\#enumerate-interval}
;;; \begin{code}
{define
  "list#"
  enumerate-interval
  [|low high #!key (step 1)|
   (if (> low high)
       ['()]
       [(cons low
              (enumerate-interval (+ low step)
                                  high
                                  step: step))])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (equal? (enumerate-interval 1 10)
          '(1 2 3 4 5 6 7 8 9 10))
  (equal? (enumerate-interval 1 10 step: 2)
          '(1 3 5 7 9))}
;;; \end{code}
;;; \section*{list\#zip}
;;; \index{list\#zip}
;;; \begin{code}
{define
  "list#"
  zip
  [|#!rest lsts|
   (if (any? (map null? lsts))
       ['()]
       [(cons (apply list (map car lsts))
              (apply zip (map cdr lsts)))])]
;;; \end{code}
;;; \subsection*{Tests with 2 Lists}
;;; \begin{code}
  (equal? (zip '() '())
          '())
  (equal? (zip '(1) '(4))
          '((1 4)))
  (equal? (zip '(1 2) '(4 5))
          '((1 4)
            (2 5)))
  (equal? (zip '(1 2 3) '(4 5 6))
          '((1 4)
            (2 5)
            (3 6)))
  (equal? (zip '(1) '())
          '())
  (equal? (zip '() '(1))
          '())
;;; \end{code}
;;; \subsection*{Tests with 3 Lists}
;;; \begin{code}
  (equal? (zip '() '() '())
          '())
  (equal? (zip '(1 2 3)
               '(4 5 6)
               '(7 8 9))
          '((1 4 7)
            (2 5 8)
            (3 6 9)))
;;; \subsection*{Tests with 4 Lists}
;;; \begin{code}
  (equal? (zip '() '() '() '())
          '())
  (equal? (zip '(1 2 3)
               '(4 5 6)
               '(7 8 9)
               '(10 11 12))
          '((1 4 7 10)
            (2 5 8 11)
            (3 6 9 12)))
  }
;;; \end{code}
;;; \section*{list\#permutations}
;;; \index{list\#permutations}
;;; \begin{code}
{define
  "list#"
  permutations
  [|lst|
   (if (null? lst)
       ['()]
       [{let permutations ((lst lst))
          (if (null? lst)
              [(list '())]
              [(flatmap
                [|x|
                 (map [|y| (cons x y)]
                      (permutations (remove x lst)))]
                lst)])}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   permutations
   '(
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
;;; \end{code}

;;; \section*{list\#sublists}
;;; \index{list\#sublists}
;;; \begin{code}
{define
  "list#"
  sublists
  [|lst|
   (if (null? lst)
       ['()]
       [(cons lst (sublists (cdr lst)))])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   sublists
   '(
     (() ())
     ((3) ((3)))
     ((2 3) ((2 3) (3)))
     ((1 2 3) ((1 2 3) (2 3) (3)))
     ))}
;;; \end{code}

;;; \section*{list\#ref-of}
;;; The inverse of list-ref.
;;;
;;; \index{list\#ref-of}
;;; \begin{code}
{define
  "list#"
  ref-of
  [|lst x #!key (onMissing noop)|
   (if (null? lst)
       [(onMissing)]
       [{let ref-of ((lst lst)
                     (index 0))
          (if (equal? (car lst) x)
              [index]
              [(if (null? (cdr lst))
                   [(onMissing)]
                   [(ref-of (cdr lst) (+ index 1))])])}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   [|x| (ref-of '(a b c d e f g) x)]
   '(
     (z noop)
     (a 0)
     (b 1)
     (g 6)
     ))
;;; \end{code}
;;; \begin{code}
  (satisfies-relation
   [|x| (ref-of '(a b c d e f g)
                x
                onMissing: ['missing])]
   '(
     (z missing)
     (a 0)
     ))
;;; \end{code}
;;; \begin{code}
  {let ((lst '(a b c d e f g)))
    (satisfies-relation
     [|x| (list-ref lst (ref-of lst x))]
     '(
       (a a)
       (b b)
       (g g)
       ))}
  }
;;; \end{code}
;;; \section*{list\#partition}
;;;  Partitions the input list into two lists, one list where
;;;  the predicate matched the element of the list, the second list
;;;  where the predicate did not match the element of the list.
;;;
;;;
;;; \index{list\#partition}
;;; \begin{code}
{define
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
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   [|lst| (partition lst [|x| (<= x 3)])]
   '(
     (() (()
          ()))
     ((3 2 5 4 1) ((1 2 3)
                   (4 5)))
     ))}
;;; \end{code}
;;; \section*{list\#sort}
;;; \index{list\#sort}
;;; \begin{code}
{define
  "list#"
  sort
  [|lst comparison|
   (if (null? lst)
       ['()]
       [{let* ((current-node (car lst))
               (p (partition (cdr lst)
                             [|x| (comparison
                                   x
                                   current-node)]))
               (less-than (car p))
               (greater-than (cadr p)))
          (append! (sort less-than
                         comparison)
                   (cons current-node
                         (sort greater-than
                               comparison)))}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   [|lst| (sort lst <)]
   '(
     (() ())
     ((1 3 2 5 4 0) (0 1 2 3 4 5))
     ))}
;;; \end{code}


;;; \section*{list\#reverse!}
;;;   Reverses the list quickly by reusing cons cells
;;;
;;; \index{list\#reverse"!}
;;; \begin{code}
{define
  "list#"
  reverse!
  [|lst|
   (if (null? lst)
       ['()]
       [{let reverse! ((cons-cell lst) (reversed-list '()))
          (if (null? (cdr cons-cell))
              [(set-cdr! cons-cell reversed-list)
               cons-cell]
              [{let ((rest (cdr cons-cell)))
                 (set-cdr! cons-cell reversed-list)
                 (reverse! rest cons-cell)}])}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   reverse!
   '(
     (() ())
     ((1) (1))
     ((2 1) (1 2))
     ((3 2 1) (1 2 3))
     ))}
;;; \end{code}


;;; \section*{lang\#aif}
;;; BUG also provides a new procedure for creating macros.  Just as libbug\#define
;;; exports the namespace to a file during compilation time, libbug\#define-macro
;;; exports the namespace to ``libbug\#.scm'', and also exports the definition of
;;; the macro to ``libbug-macros.scm'' during compile time.  Since external
;;; projects will actually load those macros as input files, much care was needed
;;; in defining libbug\#define-macro to ensure that the macros work externally in
;;; the same manner as they work in this file.  The details of how this works
;;; outside the current scope; it is defined in ``bug-language.bug.scm'

;;; aif evaluates bool, binds it to the variable ``it'', which is accessible in
;;; body.
;;;
;;; \index{lang\#aif}
;;; \begin{code}
{define-macro
  "lang#"
  aif
  [|bool body|
   `{let ((it ,bool))
      (if it
          [,body]
          [#f])}]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (equal? {aif (+ 5 10) (* 2 it)}
          30)
  (equal? {aif #f (* 2 it)}
          #f)
  (equal? (macroexpand-1 (aif (+ 5 10)
                              (* 2 it)))
          '{let ((it (+ 5 10)))
             (if it
                 [(* 2 it)]
                 [#f])})

  }
;;; \end{code}


;;; \section*{symbol\#symbol-append}
;;;   Like append, but recycles the last cons cell, so it's
;;;   faster, but mutates the input.
;;;
;;; \index{symbol\#symbol-append"}
;;; \begin{code}
{define
  "symbol#"
  symbol-append
  [|#!rest symlst|
   (string->symbol (apply string-append
                          (map symbol->string symlst)))]

;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (equal? (symbol-append 'foo 'bar) 'foobar)
  (equal? (symbol-append 'foo 'bar 'baz) 'foobarbaz)
  }
;;; \end{code}


;;; \section*{lang\#setf!}
;;; Sets a variable using its ``getting'' procedure, as done in Common Lisp.
;;; The implementation inspired by \footnote{http://okmij.org/ftp/Scheme/setf.txt}
;;;
;;; Libbug includes a macro called ``at-compile-time''\footnote{define
;;; in chapter ~\ref{sec:buglang}}, which executes its' argument exclusively
;;; at compile-time.  For the purpose of testing the ``setf!'' macro, a dummy
;;; structure is created, for use in the test.  The structure is not present
;;; in the produced library.
;;;
;;; \begin{code}
{at-compile-time
 {define-structure foo bar baz}}
;;; \end{code}


;;; \index{lang\#setf"!}
;;; \begin{code}
{define-macro
  "lang#"
  setf!
  [|exp val|
   (if (not (pair? exp))
       [`{set! ,exp ,val}]
       [{case (car exp)
          ((car) `{set-car! ,@(cdr exp) ,val})
          ((cdr) `{set-cdr! ,@(cdr exp) ,val})
          ((caar) `{setf! (car (car ,@(cdr exp))) ,val})
          ((cadr) `{setf! (car (cdr ,@(cdr exp))) ,val})
          ((cdar) `{setf! (cdr (car ,@(cdr exp))) ,val})
          ((cddr) `{setf! (cdr (cdr ,@(cdr exp))) ,val})
          ((caaar) `{setf! (car (caar ,@(cdr exp))) ,val})
          ((caadr) `{setf! (car (cadr ,@(cdr exp))) ,val})
          ((cadar) `{setf! (car (cdar ,@(cdr exp))) ,val})
          ((caddr) `{setf! (car (cddr ,@(cdr exp))) ,val})
          ((cdaar) `{setf! (cdr (caar ,@(cdr exp))) ,val})
          ((cdadr) `{setf! (cdr (cadr ,@(cdr exp))) ,val})
          ((cddar) `{setf! (cdr (cdar ,@(cdr exp))) ,val})
          ((cdddr) `{setf! (cdr (cddr ,@(cdr exp))) ,val})
          ((caaaar) `{setf! (car (caaar ,@(cdr exp))) ,val})
          ((caaadr) `{setf! (car (caadr ,@(cdr exp))) ,val})
          ((caadar) `{setf! (car (cadar ,@(cdr exp))) ,val})
          ((caaddr) `{setf! (car (caddr ,@(cdr exp))) ,val})
          ((cadaar) `{setf! (car (cdaar ,@(cdr exp))) ,val})
          ((cadadr) `{setf! (car (cdadr ,@(cdr exp))) ,val})
          ((caddar) `{setf! (car (cddar ,@(cdr exp))) ,val})
          ((cadddr) `{setf! (car (cdddr ,@(cdr exp))) ,val})
          ((cdaaar) `{setf! (cdr (caaar ,@(cdr exp))) ,val})
          ((cdaadr) `{setf! (cdr (caadr ,@(cdr exp))) ,val})
          ((cdadar) `{setf! (cdr (cadar ,@(cdr exp))) ,val})
          ((cdaddr) `{setf! (cdr (caddr ,@(cdr exp))) ,val})
          ((cddaar) `{setf! (cdr (cdaar ,@(cdr exp))) ,val})
          ((cddadr) `{setf! (cdr (cdadr ,@(cdr exp))) ,val})
          ((cdddar) `{setf! (cdr (cddar ,@(cdr exp))) ,val})
          ((cddddr) `{setf! (cdr (cdddr ,@(cdr exp))) ,val})
          ;; TODO - handle other atypical cases
          (else `(,(symbol-append (car exp) '-set!)
                  ,@(cdr exp)
                  ,val))}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  ;; test variable
  {let ((a 5))
    {setf! a 10}
    (equal? a 10)}
  {begin
    {let ((a (make-foo 1 2)))
      {setf! (foo-bar a) 10}
      (equal? (make-foo 10 2)
              a)}}
;;; \end{code}
;;; \begin{code}
  {let ((a '(1 2)))
    {setf! (car a) 10}
    (equal? (car a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(1 2)))
    {setf! (cdr a) 10}
    (equal? (cdr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '((1 2) (3 4))))
    {setf! (caar a) 10}
    (equal? (caar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '((1 2) (3 4))))
    {setf! (cadr a) 10}
    (equal? (cadr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '((1 2) (3 4))))
    {setf! (cdar a) 10}
    (equal? (cdar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '((1 2) (3 4))))
    {setf! (cddr a) 10}
    (equal? (cddr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) ((3 4)))))
    {setf! (caaar a) 10}
    (equal? (caaar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) ((3 4)))))
    {setf! (caadr a) 10}
    (equal? (caadr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2) 5) ((3 4)))))
    {setf! (cadar a) 10}
    (equal? (cadar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) ((3 4)) (5))))
    {setf! (caddr a) 10}
    (equal? (caddr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) ((3 4)))))
    {setf! (cdaar a) 10}
    (equal? (cdaar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) ((3 4)))))
    {setf! (cdadr a) 10}
    (equal? (cdadr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) ((3 4)) (5 6))))
    {setf! (cdddr a) 10}
    (equal? (cdddr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '((((1 2))) ((3 4)) (5 6))))
    {setf! (caaaar a) 10}
    (equal? (caaaar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) ((3 4)) (5 6))))
    {setf! (caaadr a) 10}
    (equal? (caaadr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2) (7 8)) ((3 4)) (5 6))))
    {setf! (caadar a) 10}
    (equal? (caadar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) ((3 4)) (5 6))))
    {setf! (caaddr a) 10}
    (equal? (caaddr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) ((3 4)) (5 6))))
    {setf! (cadaar a) 10}
    (equal? (cadaar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) ((3 4) (7 8)) (5 6))))
    {setf! (cadadr a) 10}
    (equal? (cadadr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2) () (7 8)) ((3 4)) (5 6))))
    {setf! (caddar a) 10}
    (equal? (caddar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(1 2 3 (x 5))))
    {setf! (cadddr a) 10}
    (equal? (cadddr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '((((1 x))))))
    {setf! (cdaaar a) 10}
    (equal? (cdaaar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) ((3 4)) (5 6))))
    {setf! (cdaadr a) 10}
    (equal? (cdaadr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '((1 ((2 x))))))
    {setf! (cdadar a) 10}
    (equal? (cdadar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(1 2 (3 x))))
    {setf! (cdaddr a) 10}
    (equal? (cdaddr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 (2 x))))))
    {setf! (cddaar a) 10}
    (equal? (cddaar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(((1 2)) (3 (4 x)))))
    {setf! (cddadr a) 10}
    (equal? (cddadr a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '((1 2 3 x))))
    {setf! (cdddar a) 10}
    (equal? (cdddar a) 10)}
;;; \end{code}
;;; \begin{code}
  {let ((a '(1 2 3 4 x)))
    {setf! (cddddr a) 10}
    (equal? (cddddr a) 10)}
  }
;;; \end{code}



;;; \section*{lang\#with-gensyms}
;;;   Utility for macros to minimize explicit use of gensym.
;;;   Gensym creates a symbol at compile time which is guaranteed
;;;   to be unique.  Macros which intentionally capture variables,
;;;   such as aif, are the anomaly.
;;;   Usually, variables local to a macro should not clash
;;;   with variables local to the macro caller.
;;;
;;; \begin{code}
{define-macro
  "lang#"
  with-gensyms
  [|symbols #!rest body|
   `{let ,(map [|symbol| `(,symbol {gensym})]
               symbols)
      ,@body}]
  (equal? (macroexpand-1 (with-gensyms (foo bar baz)
                                       `{begin
                                          (pp ,foo)
                                          (pp ,bar)
                                          (pp ,baz)}))
          '{let ((foo (gensym))
                 (bar (gensym))
                 (baz (gensym)))
             `{begin
                (pp ,foo)
                (pp ,bar)
                (pp ,baz)}})
  }
;;; \end{code}

;;; \section*{lang\#while}
;;; Sometimes a person needs an imperative loop
;;;
;;; \index{lang\#while}
;;; \begin{code}
{define
  "lang#"
  while
  [|pred body|
   (if (pred)
       [(body)
        (while pred body)]
       [(noop)])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((a 0))
    (while [(< a 5)]
           [(set! a (+ a 1))])
    (equal? a 5)}}
;;; \end{code}
;;; \section*{lang\#numeric-if}
;;;   An if expression for numbers, based on their sign.
;;;
;;; \index{lang\#numeric-if}
;;; \begin{code}
{define
  "lang#"
  numeric-if
  [|expr #!key (ifPositive noop) (ifZero noop) (ifNegative noop)|
   {cond ((> expr 0) (ifPositive))
         ((= expr 0) (ifZero))
         (else (ifNegative))}]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies-relation
   [|n|
    (numeric-if n ifPositive: ['pos] ifZero: ['zero] ifNegative: ['neg])]
   '(
     (5 pos)
     (0 zero)
     (-5 neg)
     ))}
;;; \end{code}

;;; \section*{stream\#stream-cons}
;;; Streams are lists whose evaluation is deferred until the value is
;;; requested.  For more information, consult ``The Structure and
;;; Interpretation of Computer Programs''.
;;;
;;; \index{stream\#stream-cons}
;;; \begin{code}
{define-macro
  "stream#"
  stream-cons
  [|a b|
   `(cons ,a {delay ,b})]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  {begin
    {let ((s {stream-cons 1 2}))
      {and
       (equal? (car s)
               1)
       (equal? {force (cdr s)}
               2)}}}}
;;; \end{code}
;;; \section*{stream\#stream-car}
;;; Get the first element of the stream.
;;;
;;; \index{stream\#stream-car}
;;; \begin{code}
{define
  "stream#"
  stream-car
  car
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((s {stream-cons 1 2}))
    (equal? (stream-car s)
            1)}}
;;; \end{code}
;;; \section*{stream\#stream-cdr}
;;; Forces the evaluation of the next element of the stream.
;;;
;;; \index{stream\#stream-cdr}
;;; \begin{code}
{define
  "stream#"
  stream-cdr
  [|s| {force (cdr s)}]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((s {stream-cons 1 2}))
    (equal? (stream-cdr s)
            2)}}
;;; \end{code}
;;; \section*{list\#list-\textgreater stream}
;;; Converts a list into a stream
;;;
;;; \index{list\#list-\textgreater stream}
;;; \begin{code}
{define
  "list#"
  list->stream
  [|l|
   (if (null? l)
       [l]
       [(stream-cons (car l)
                     {let list->stream ((l (cdr l)))
                       (if (null? l)
                           ['()]
                           [(stream-cons (car l)
                                         (list->stream (cdr l)))])})])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((foo (list#list->stream '(1 2 3))))
    {and (equal? 1 (stream-car foo))
         (equal? 2 (stream-car
                    (stream-cdr foo)))
         (equal? 3 (stream-car
                    (stream-cdr
                     (stream-cdr foo))))
         (null? (stream-cdr
                 (stream-cdr
                  (stream-cdr foo))))}}}
;;; \end{code}
;;; \section*{stream\#stream-ref}
;;; The analogous procedure of list-ref
;;;
;;; \index{stream\#stream-ref}
;;; \begin{code}
{define
  "stream#"
  stream-ref
  [|s n #!key (onOutOfBounds noop)|
   (if (< n 0)
       [(onOutOfBounds)]
       [{let stream-ref ((s s) (n n))
          (if (equal? n 0)
              [(stream-car s)]
              [(if (not (null? (stream-cdr s)))
                   [(stream-ref (stream-cdr s) (- n 1))]
                   [(onOutOfBounds)])])}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((s (list->stream '(5 4 3 2 1))))
    (and
     (equal? (stream-ref s -1)
             'noop)
     (equal? (stream-ref s 0)
             5)
     (equal? (stream-ref s 4)
             1)
     (equal? (stream-ref s 5)
             'noop)
     (equal? (stream-ref s 5 onOutOfBounds: ['out])
             'out))}}
;;; \end{code}


;;; \begin{code}
(include "bug-language-end.scm")
;;; \end{code}

