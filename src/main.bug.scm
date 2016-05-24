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
;;; \usepackage{appendix}
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
;;; \bibliographystyle{alpha}
;;; % Article top matter
;;; \title{Computation At Compile-Time \\
;;;    \vspace{4 mm} \large{and the Implementation of Libbug}}
;;;
;;; \author{Bill Six}
;;;
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
;;;
;;; \vspace*{\fill}
;;; \begin{center}
;;;  \begin{minipage}{.9\textwidth}

;;;  \noindent
;;;  EITHER
;;;
;;;  \vspace{1cm}
;;;  \noindent
;;;
;;;  \noindent
;;;   Licensed under the Apache License, Version 2.0 (the "License");
;;;   you may not use this file except in compliance with the License.
;;;   You may obtain a copy of the License at
;;;
;;;  \noindent
;;;       http://www.apache.org/licenses/LICENSE-2.0
;;;
;;;  \noindent
;;;   Unless required by applicable law or agreed to in writing, software
;;;   distributed under the License is distributed on an "AS IS" BASIS,
;;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;;   See the License for the specific language governing permissions and
;;;   limitations under the License.
;;;
;;;  \vspace{1cm}
;;;  \noindent
;;;  OR
;;;
;;;  \vspace{1cm}
;;;  \noindent
;;;
;;;  \noindent
;;;    This library is free software; you can redistribute it and/or
;;;    modify it under the terms of the GNU Lesser General Public
;;;    License as published by the Free Software Foundation; either
;;;    version 2.1 of the License, or (at your option) any later version.
;;;
;;;  \noindent
;;;    This library is distributed in the hope that it will be useful,
;;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;;    Lesser General Public License for more details.
;;;
;;;  \noindent
;;;    You should have received a copy of the GNU Lesser General Public
;;;    License along with this library; if not, write to the Free Software
;;;    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
;;;
;;;  \end{minipage}
;;;  \end{center}
;;;  \vfill
;;;  \clearpage
;;; \newpage
;;; \thispagestyle{empty}
;;; \mbox{}
;;;
;;;
;;; \clearpage
;;; \vspace*{\fill}
;;; \begin{center}
;;;  \begin{minipage}{.6\textwidth}
;;;   For Mom and Dad.  Thanks for everything.
;;;  \end{minipage}
;;;  \end{center}
;;;  \vfill
;;;  \clearpage
;;;
;;; \chapter*{Preface}
;;; This is a book about compiler design for people who have no interest
;;; in studying compiler design.  ...Umm, then who wants to read this book?
;;; Let me try this again...  This book is the study of
;;; source code which is discarded by the compiler, having no representation in
;;; the generated machine code.
;;; ...Ummm, still not right...  This book is about viewing a compiler not only
;;; as a means of translating source code into machine code,
;;;  but also viewing it as an interpreter capable of any
;;; general purpose computation.  ...Closer, but who cares?... I think I got it
;;; now. This is a book about ``Testing at Compile-Time''!
;;;
;;; What do I mean by that?  Let's say you're looking at source code with which
;;; you are unfamiliar, such as the following:
;;;
;;; \begin{examplecode}
;;;{define
;;; "list#"
;;; permutations
;;; [|l| (if (null? l)
;;;          ['()]
;;;          [{let permutations ((l l))
;;;             (if (null? (cdr l))
;;;                 [(list l)]
;;;                 [(flatmap [|x|
;;;                            (map [|y| (cons x y)]
;;;                                 (permutations (remove x l)))]
;;;                           l)])}])]
;;; \end{examplecode}
;;;
;;; So what does the code do?  How did the author intend for it to be used?
;;; In trying to answer those questions, fans of statically-typed programming
;;; languages might lament the lack of types, as types help them to reason about
;;; programs and help them to deduce where to look to find more information.
;;; In trying to answer those questions,
;;; fans of dynamically-typed languages might argue ``Look at the tests!'',
;;; as tests ensure the code functions in a user-specified way and
;;; they serve as a form of documentation.  But
;;; where are those tests?  Probably in some other file whose filesystem path is
;;; similar to the current file's path, (e.g., src/com/BigCorp/HugeProject/Foo.java
;;; is tested by test/com/BigCorp/HugeProject/FooTest.java)
;;; Then you'd have to find the file, open the file, look through it
;;; while ignoring tests which are
;;; for other methods.  Frankly, it's too much work and it interrupts the flow
;;; of coding, at least for me.
;;;
;;; But how else would a programmer organize tests?  Well in this book, which is the
;;; implementation of a library called ``libbug'',
;;; tests are specified as part of the procedure's definition
;;; and they are executed at compile-time.  Should any test fail the compiler will
;;; exit in error, like a type error in a
;;; statically-typed language.  Furthermore,
;;; the book you are currently reading
;;; is embedded into the source code of libbug; it is generated only upon successful
;;; compilation of libbug and couldn't exist if a single test
;;; failed.
;;;
;;; So where are these tests then? The very alert reader may have noticed
;;; that the opening '\{' in the definition
;;; of ``permutations'' was not closed.  That is because the definition
;;; of ``permutations'' is completed by specifying tests
;;; to be run at compile-time.
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
;;;           (3 2 1)))}
;;; \end{examplecode}
;;;
;;;
;;; Why does this matter?
;;; Towards answering the questions ``what does the code do?'' and ``how did the author
;;; intend for it to be used?'', there is neither searching through files nor guessing
;;; how the code was originally intended to be used.
;;; The fact that the
;;; tests are collocated with the procedure definition means that the reader can
;;; read the tests without switching between files, perhaps reading the tests
;;; before reading the procedure definition.  And the reader
;;; may not even read the procedure at all if the tests gave him enough information
;;; to use it successfully.  Should the reader want to understand the procedure, he
;;; can mentally apply the procedure to the tests to understand it.
;;;
;;; Wait a second. If those tests are defined in the source code itself, won't they
;;; be in the executable?  And won't they run every time I execute the program?
;;; That would be unacceptable as it would both increase the size of the binary and
;;; slow down the program at start up.  Fortunately the
;;; answer to both questions is no, because in chapter~\ref{sec:buglang} I show how to specify
;;; that certain code should be interpreted by the compiler instead of being
;;; compiled.  Lisp implementations such as Gambit are particularly well
;;; suited for this style of programming because unevaluated Lisp code is
;;; specified using a data structure of Lisp; because the compiler
;;; is an interpreter capable of being augmented with the
;;; same code which it is compiling.  Upon finishing compilation, the
;;; compiler has \emph{become} the very program it is compiling.
;;;
;;;
;;; \tableofcontents
;;; \break
;;; \chapter{Introduction}
;;; \pagenumbering{arabic}
;;; Libbug is Bill's Utilities for Gambit Scheme:  a ``standard library'' of procedures
;;; which augments Scheme's small set of built-in procedures and macros.
;;; Libbug provides procedures for list processing, streams,
;;; control structures,
;;; general-purpose evaluation at compile-time,
;;; and a
;;; compile-time test framework written in only 9 lines of code!
;;; Programs written using libbug optionally may be
;;; programmed in a relatively unobstructive
;;; ``literate programming''\footnote{http://lmgtfy.com/?q=literate+programming}
;;; style, so that a program, such as libbug, can be read linearly in a book form.
;;;
;;; \section{Prerequisites}
;;;
;;; The reader is assumed to be somewhat familiar both with Scheme, with Common Lisp-style
;;; macros, and with recursive design.  If the book proves too difficult for you,
;;; read ``Simply Scheme''
;;; \cite{ss}\footnote{available on-line for no cost}
;;; or ``The Little Schemer'' \cite{littleschemer}.  Since libbug uses Gambit Scheme's
;;; Common Lisp-style macros, the author recommends reading ``On Lisp''
;;; \cite{onlisp}\footnote{available on-line for no cost}.
;;; The other books listed in the bibliography, all of which inspired ideas for this
;;; book, are all recommended reading but are
;;; not necessary to understand the content of this book.
;;;
;;; \section{Conventions}
;;; Code which is part of libbug will not be outlined and
;;; will have line numbers on the left.
;;;
;;; \begin{code}
;; This is part of libbug.
;;; \end{code}
;;;
;;; \noindent
;;; Example code which is not part of libbug not be outlined nor will it have line
;;; numbers.
;;;
;;; \begin{examplecode}
;;; (+ 1 ("This is NOT part of libbug"))
;;; \end{examplecode}
;;;
;;; \noindent
;;; In libbug, the notation
;;;
;;; \begin{examplecode}
;;; (fun arg1 arg2)
;;; \end{examplecode}
;;;
;;; \noindent
;;;  means evaluate ``fun'', ``arg1''
;;; and ``arg2'' in any order, then apply ``fun'' to ``arg1'' and ``arg2'';
;;; standard Scheme semantics for invoking a prodecure.  But since macros
;;; are not normal procedures and do
;;; not necessarily respect those semantics, in libbug, the notation
;;;
;;; \begin{examplecode}
;;; {fun1 arg1 arg2}
;;; \end{examplecode}
;;;
;;; \noindent
;;; is used to denote to
;;; the reader that the standard evaluation rules do not apply.  For instance, in
;;;
;;; \begin{examplecode}
;;; {define x 5}
;;; \end{examplecode}
;;;
;;; \noindent
;;; \{\} are used because ``x''
;;; may be a new variable.  As such, ``x'' cannot currently evaluate to anything.
;;;
;;; Not all macro applications use \{\}.  If the macro respects Scheme's standard
;;; order of evaluation, macro application will use standard Scheme notation:
;;;
;;; \begin{examplecode}
;;; ((compose [|x| (* x 2)]) 5)
;;; \end{examplecode}
;;;
;;; \section{Getting the Source Code}
;;;  The Scheme source code is located at http://github.com/billsix/bug.
;;;  The Scheme files can produce the libbug library, as well as this book\footnote{the version
;;;  of the code used to generate this book is listed on the copyright page}.
;;;  Currently the code works on various distributions of Linux, on FreeBSD, and on Mac
;;;  OS X.  The build currently does not work on Windows.
;;;
;;; You will need a C compiler such as GCC,
;;; Autoconf, Automake, and Gambit
;;; Scheme\footnote{http://gambitscheme.org}, version 4.8 or newer.
;;;
;;; To compile the book and library, execute the following on the command line:
;;;
;;; \begin{examplecode}
;;; $ ./autogen.sh
;;; $ ./configure --prefix=$BUG_HOME --enable-shared --enable-pdf
;;; $ make
;;; $ make install
;;; \end{examplecode}
;;;
;;; \begin{itemize}
;;;   \item
;;;      The argument to ``prefix'' tells Autoconf the location into which libbug
;;;      should be installed when ``make install'' is executed.
;;;   \item
;;;      Libbug can be compiled as a static library, or a dynamic library. ``--enable-shared''
;;;      configures the build so that a shared library is created.  If you desire to build
;;;      libbug as a static library, substitute ``--disable-shared''.
;;;   \item
;;;      ``--enable-pdf'' means to build this book as a PDF.  To disable the creation of the PDF,
;;;      substitute ``--enable-pdf=no''.
;;; \end{itemize}
;;;
;;; \section{Comparison of Compile-Time Computations in Other Languages}
;;;
;;; What exactly is computation at compile-time?  An introduction to the topic is provided
;;; in Appendix~\ref{sec:appendix1}, demonstrated
;;; in languages of more widespread use (C and C++). The appendix
;;; provides examples of compile-time computation in C, C++, and libbug, along with a comparison
;;; of their expressive power.
;;;
;;;
;;; \chapter{Introductory Procedures}
;;;  \label{sec:beginninglibbug}
;;;
;;; This chapter begins the definition of libbug's standard library of Scheme procedures and
;;; macros\footnote{The code within chapters~\ref{sec:beginninglibbug}
;;; to~\ref{sec:endinglibbug} is found in
;;; ``src/main.bug.scm''.}, along with tests which are run as part of the
;;; compilation process.  If any test fails, the compiler will exit in error,
;;; much like a type error in a statically-typed language.
;;;
;;; To gain such functionality libbug cannot be defined using Gambit Scheme's
;;; ``\#\#define'', ``\#\#define-macro'', and ``\#\#define-structure'', since
;;; they only define variables and
;;; procedures for use at run-time\footnote{well... that statement is not true
;;; for ``\#\#define-macro, but it makes for a simpler explanation upon first reading}.
;;; Instead, definitions within
;;; libbug use ``libbug\#define'', ``libbug\#define-macro'', and
;;; ``libbug\#\#define-structure''\footnote{Per convention
;;; within libbug, procedures namespaced to ``libbug'' are not compiled into the library
;;; or other output files; such procedures are meant for private use within the implementation
;;; of libbug.}, which  are implemented in Chapter~\ref{sec:buglang}.
;;; How they are implemented is not relevant yet, since the use of these
;;; procedure-defining procedures will be explained
;;; incrementally.
;;;
;;; \begin{code}
(include "bug-language.scm")
{##namespace ("libbug#" define)}
{##namespace ("libbug#" define-macro)}
{##namespace ("libbug#" define-structure)}
;;;\end{code}
;;; \begin{itemize}
;;;   \item On line 1, the code which makes computation at compile-time possible
;;;     is imported. The contents of that file are in Chapter~\ref{sec:buglang}.
;;;   \item On line 2-4, Gambit's ``\#\#namespace'' procedure is invoked, to
;;;     tell the compiler that all subsequent uses of ``define'', ``define-macro'',
;;;     and ``define-structure'' shall use libbug's version of those procedures
;;;     instead of Gambit's.
;;; \end{itemize}
;;;
;;;
;;; \newpage
;;; \section{lang\#noop}
;;; The first definition is ``noop'', a procedure which takes no arguments and
;;; which evaluates to the symbol 'noop.
;;;
;;; \index{lang\#noop}
;;; \begin{code}
{define
  "lang#"
  noop
  ['noop]
;;; \end{code}
;;;
;;; \begin{itemize}
;;;   \item On line 1, the libbug\#define macro\footnote{defined in section ~\ref{sec:libbugdefine}}
;;; is invoked.
;;;   \item On line 2, a namespace
;;;   \item On line 3, the variable name, which will be declared in the
;;;         namespace defined on line 2.
;;;   \item On line 4, the lambda literal to be stored into the variable.
;;;         Libbug includes a Scheme preprocessor ``bug-gscpp'',
;;;         which expands lambda literals
;;;         into lambdas.  In this case
;;;
;;; \begin{examplecode}
;;; ['noop]
;;; \end{examplecode}
;;;
;;; \noindent
;;; is expanded into
;;;
;;; \begin{examplecode}
;;; (lambda () 'noop)
;;; \end{examplecode}
;;;
;;; \end{itemize}
;;; \subsection*{Test}
;;; \begin{code}
  (equal? (noop) 'noop)}
;;; \end{code}
;;;
;;; \begin{itemize}
;;;  \item  On line 1, an expression which evaluates to a boolean is defined.
;;;  This is a
;;; test which will be evaluated at compile-time.  Should the test fail,
;;; the build process will fail and neither the shared library nor the document which
;;; you are currently reading will be created.  The
;;; tests are not present in the resulting
;;; library.
;;; \end{itemize}
;;;
;;; ``noop'' does not look useful at first glance, but it is frequently used when
;;;  you need to execute a procedure but you do not care about the resulting value.
;;;  For instance, ``noop'' is used as a default ``exception-handler'' for many
;;;  procedures within libbug.
;;;
;;; \newpage
;;; \section{lang\#identity}
;;; lang\#identity is a procedure of one argument which evaluates to
;;; its argument. \cite[p. 2]{calculi}
;;;
;;; \index{lang\#identity}
;;;
;;; \begin{code}
{define
  "lang#"
  identity
  [|x| x]
;;; \end{code}
;;; \begin{itemize}
;;;   \item On line 4, ``bug-gscpp'' expands
;;;
;;; \begin{examplecode}
;;; [|x| x]
;;; \end{examplecode}
;;;
;;; to
;;;
;;; \begin{examplecode}
;;; (lambda (x) x)
;;; \end{examplecode}
;;;
;;; This expansion works with multiple arguments, as long as they are between
;;; the ``\textbar''s \footnote{Since ``bug-gscpp'' uses ``\textbar''s for lambda
;;; literals, Scheme's block comments are not allowed in libbug programs}.
;;; \end{itemize}
;;;
;;; \subsection*{Tests}
;;;
;;; libbug\#define can take more than one test as parameters.
;;;
;;; \begin{code}
  (equal? "foo" (identity "foo"))
  (equal? identity (identity identity))
  }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{list\#all?}
;;; Like ``and'', but takes a list instead of a variable number of arguments, and
;;; all elements of the list are evaluated before ``and'' is applied.
;;;
;;; \label{sec:langiffirstuse}
;;; \index{list\#all?}
;;; \begin{code}
{define
  "list#"
  all?
  [|l|
   (if (null? l)
       [#t]
       [(if (not (car l))
            [#f]
            [(all? (cdr l))])])]
;;; \end{code}
;;; \begin{itemize}
;;;   \item On line 5, if, which is currently namespaced to lang\#if\footnote{
;;;      defined in section~\ref{sec:langif} }, takes
;;;         lambda expressions for the two parameters. Libbug pretends that \#t and \#f are
;;;         ``Church Booleans'' \cite[p. 58]{tapl}, and that lang\#if is just syntactic sugar:
;;;
;;;
;;; \begin{examplecode}
;;;{define #t [|t f| (t)]}
;;;{define #f [|t f| (f)]}
;;;{define lang#if [|b t f| (b t f)]}
;;; \end{examplecode}
;;;
;;; \noindent As such, if would not be a special form, and is more consistent with the
;;; rest of libbug.
;;;
;;; \end{itemize}
;;;
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
;;; Tests in libbug are defined for two purposes.  Firstly, to ensure
;;; that expected behavior of a procedure does not change when that procedure's internal
;;; definition has changed.  Secondly, as a form of documentation of the procedure.
;;; Libbug is unique\footnote{as far as the author knows} in that the tests are collocated with
;;; the procedure definitions.  The reader is encouraged to read the tests for a
;;; procedure before reading the implementation; since in many cases, the tests are designed
;;; specifically to guide the reader through the implementation.
;;;
;;; \newpage
;;; \section{lang\#satisfies?}
;;;
;;; When writing multiple tests, why explicitly invoke the procedure repeatedly,
;;; with varying inputs and outputs, as was done for ``all?''?  Instead, provide
;;; the procedure and a list
;;; of input/output pairs.
;;;
;;; \index{lang\#satisfies?}
;;; \begin{code}
{define
  "lang#"
  satisfies?
  [|f list-of-pairs|
   (all? (map [|pair| (equal? (f (car pair))
                              (cadr pair))]
              list-of-pairs))]
;;; \end{code}
;;;
;;; \footnote{Within libbug, a parameter named ``f'' usually means the parameter is
;;;   a procedure.}

;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   all?
   '(
     (() #t)
     ((1) #t)
     ((#t) #t)
     ((#t #t) #t)
     ((#f) #f)
     ((#t #t #t #f) #f)))
  (satisfies?
   [|x| (+ x 1)]
   '(
     (0 1)
     (1 2)
     (2 3)
     ))}
;;; \end{code}
;;;
;;; For the remaining procedures, if the tests do an adequate job of explaining
;;; the code, there will be no written documentation.
;;;
;;; \section{lang\#while}
;;;
;;; \index{lang\#while}
;;; \begin{code}
{define
  "lang#"
  while
  [|pred? body|
   {let while ()
     (if (pred?)
         [(body)
          (while)]
         [(noop)])}]
;;; \end{code}
;;;
;;; \footnote{Within libbug, a parameter named ``pred?'' or ``p?'' usually means the parameter is
;;;   is a predicate, meaning a procedure which returns true or false.}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((a 0))
    (while [(< a 5)]
           [(set! a (+ a 1))])
    (equal? a 5)}}
;;; \end{code}
;;;
;;;
;;; Programmers who are new to the Scheme language  may be surprised that
;;; the language provides no built-in syntax for looping, such as ``for''
;;; or ``while''.  A better question though, is why don't other
;;; languages provide primitives from which you can create
;;; those looping constructs yourself?  ``Take the red pill.''
;;;
;;;
;;; \newpage
;;; \section{lang\#numeric-if}
;;;   A conditional expression for numbers, based on their sign.
;;;
;;; \index{lang\#numeric-if}
;;; \begin{code}
{define
  "lang#"
  numeric-if
  [|n #!key (ifPositive noop) (ifZero noop) (ifNegative noop)|
   (if (> n 0)
       [(ifPositive)]
       [(if (= n 0)
            [(ifZero)]
            [(ifNegative)])])]
;;; \end{code}
;;;
;;; \noindent \cite[p. 150, called ``nif'']{onlisp}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|n|
    (numeric-if n
                ifPositive: ['pos]
                ifZero: ['zero]
                ifNegative: ['neg])]
   '(
     (5 pos)
     (0 zero)
     (-5 neg)
     ))}
;;; \end{code}
;;;
;;;
;;;
;;;
;;; \newpage
;;; \section{lang\#atom?}
;;; \index{lang\#atom?}
;;; \begin{code}
{define
  "lang#"
  atom?
  [|x| {or (number? x)
           (symbol? x)}]
;;; \end{code}
;;;
;;; \footnote{Within libbug, a parameter named ``x'' usually means the parameter can
;;;   be of any type.}
;;;
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   atom?
   '(
     (a #t)
     (1 #t)
     (() #f)
     ((a) #f)
     ))
  }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{lang\#complement}
;;;
;;; \index{lang\#complement}
;;; \begin{code}
{define
  "lang#"
  complement
  [|f|
   [|#!rest args| (not (apply f args))]]
;;; \end{code}
;;;
;;; \noindent \cite[p. 63]{onlisp}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   pair?
   '(
     (1 #f)
     ((1 2) #t)
     ))
  (satisfies?
   (complement pair?)
   '(
     (1 #t)
     ((1 2) #f)
     ))
  }
;;; \end{code}
;;;
;;;
;;;
;;;
;;;
;;; \newpage
;;; \chapter{Lists}
;;; \section{list\#copy}
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
;;;
;;; \footnote{Within libbug, a parameter named ``l'' usually means the parameter is
;;;   is a list of something.}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((a '(1 2 3 4 5)))
    {and (equal? a (copy a))
         (not (eq? a (copy a)))}}
  }
;;; \end{code}
;;;
;;; For a thorough description of ``equal?'' vs ``eq?'', see \cite[p. 122-129]{schemeprogramminglanguage}.
;;;
;;; \newpage
;;; \section{list\#proper?}
;;;   Will not terminate on a circular list.
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
  (satisfies?
   proper?
   '(
     (4 #f)
     ((1 2) #t)
     ((1 2 . 5) #f)
     ))}
;;; \end{code}
;;;
;;;
;;;
;;;
;;; \newpage
;;; \section{list\#first}
;;;
;;; list\#first uses Gambit's keyword syntax.  ``onNull'' is
;;; an optional argument, with a default value of the value in the ``noop''
;;; variable.
;;;
;;; \index{list\#first}
;;; \begin{code}
{define
  "list#"
  first
  [|l #!key (onNull noop)|
   (if (null? l)
       [(onNull)]
       [(car l)])]
;;; \end{code}
;;;
;;; \noindent \cite[p. 59]{ss}
;;;
;;;  The first test does not provide a value for ``onNull'',
;;; the second test does, which demonstrates the keyword syntax.
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   first
   '(
     (() noop)
     ((1 2 3) 1)
     ))
  (satisfies?
   [|l| (first l onNull: [5])]
   '(
     (() 5)
     ((1 2 3) 1)
     ))}
;;; \end{code}
;;;
;;;
;;;
;;; \newpage
;;; \section{list\#but-first}
;;; \index{list\#but-first}
;;; \begin{code}
{define
  "list#"
  but-first
  [|l #!key (onNull noop)|
   (if (null? l)
       [(onNull)]
       [(cdr l)])]
;;; \end{code}
;;;
;;; \noindent \cite[p. 59]{ss}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   but-first
   '(
     (() noop)
     ((1 2 3) (2 3))
     ))
  (satisfies?
   [|l| (but-first l onNull: [5])]
   '(
     (() 5)
     ((1 2 3) (2 3))
     ))}
;;; \end{code}
;;;
;;; \newpage
;;; \section{list\#last}
;;; \index{list\#last}
;;; \begin{code}
{define
  "list#"
  last
  [|l #!key (onNull noop)|
   (if (null? l)
       [(onNull)]
       [{let last ((l l))
          (if (null? (cdr l))
              [(car l)]
              [(last (cdr l))])}])]
;;; \end{code}
;;;
;;; \noindent \cite[p. 59]{ss}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   last
   '(
     (() noop)
     ((1) 1)
     ((2 1) 1)
     ))
  (satisfies?
   [|l| (last l onNull: [5])]
   '(
     (() 5)
     ((2 1) 1)
     ))}
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{list\#but-last}
;;; \index{list\#but-last}
;;; \begin{code}
{define
  "list#"
  but-last
  [|l #!key (onNull noop)|
   (if (null? l)
       [(onNull)]
       [{let but-last ((l l))
          (if (null? (cdr l))
              ['()]
              [(cons (car l)
                     (but-last (cdr l)))])}])]
;;; \end{code}
;;;
;;; \noindent \cite[p. 59]{ss}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   but-last
   '(
     (() noop)
     ((1) ())
     ((2 1) (2))
     ((3 2 1) (3 2))
     ))
  (satisfies?
   [|l| (but-last l onNull: [5])]
   '(
     (() 5)
     ((3 2 1) (3 2))
     ))
  }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{list\#filter}
;;; \index{list\#filter}
;;; \begin{code}
{define
  "list#"
  filter
  [|p? l|
   {let filter ((l l))
     (if (null? l)
         ['()]
         [{let ((first (car l)))
            (if (p? first)
                [(cons first (filter (cdr l)))]
                [(filter (cdr l))])}])}]
;;; \end{code}
;;;
;;; \noindent \cite[p. 331]{ss}\footnote{Simply Scheme has an excellent discussion on section
;;; on Higher-Order Functions and their combinations \cite[p. 103-125]{ss}}. \cite[p. 115]{sicp}.
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
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
;;;
;;;
;;;
;;;
;;; \newpage
;;; \section{list\#remove}
;;; \index{list\#remove}
;;; \begin{code}
{define
  "list#"
  remove
  [|x l|
   (filter [|y| (not (equal? x y))]
           l)]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|l| (remove 5 l)]
   '(
     ((1 5 2 5 3 5 4 5 5) (1 2 3 4))
     ))}
;;; \end{code}
;;;
;;; \newpage
;;; \section{list\#fold-left}
;;;    Reduce the list to a scalar by applying the reducing procedure repeatedly,
;;;    starting from the ``left'' side of the list
;;;
;;; \index{list\#fold-left}
;;; \begin{code}
{define
  "list#"
  fold-left
  [|f acc l|
   {let fold-left ((acc acc) (l l))
     (if (null? l)
         [acc]
         [(fold-left (f acc
                        (car l))
                     (cdr l))])}]
;;; \end{code}
;;;
;;;
;;; \footnote{Within libbug, a parameter named ``acc'' usually means the parameter is
;;;   is an accumulated value}
;;;
;;; \noindent \cite[p. 121]{sicp}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|l| (fold-left + 5 l)]
   '(
     (() 5)
     ((1) 6)
     ((1 2) 8)
     ((1 2 3 4 5 6) 26)
     ))
;;; \end{code}
;;;
;;; Understanding the first test may give the reader false confidence in understanding
;;; ``fold-left''.  To understand how ``fold-left'' really works, pay close attention
;;; to how it works with non-commutative procedures, such as ``-''.
;;;
;;; \begin{code}
  (satisfies?
   [|l| (fold-left - 5 l)]
   '(
     (() 5)
     ((1) 4)
     ((1 2) 2)
     ((1 2 3 4 5 6) -16)))}
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{list\#fold-right}
;;;    Reduces the list to a scalar by applying the reducing
;;;    procedure repeatedly,
;;;    starting from the ``right'' side of the list
;;;
;;; \index{list\#fold-right}
;;; \begin{code}
{define
  "list#"
  fold-right
  [|f acc l|
   {let fold-right ((acc acc) (l l))
     (if (null? l)
         [acc]
         [(f (car l)
             (fold-right acc (cdr l)))])}]
;;; \end{code}
;;;
;;; \noindent \cite[p. 116 (named ``accumulate'')]{sicp}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|l| (fold-right + 5 l)]
   '(
     (() 5)
     ((1) 6)
     ((1 2) 8)
     ((1 2 3 4 5 6) 26)
     ))
  (satisfies?
   [|l| (fold-right - 5 l)]
   '(
     (() 5)
     ((1) -4)
     ((1 2) 4)
     ((1 2 3 4 5 6) 2)))
  }
;;; \end{code}
;;;
;;;
;;;
;;; \newpage
;;; \section{list\#scan-left}
;;;   Like fold-left, but every intermediate value
;;;   of fold-left's accumulator is put onto the resulting list
;;;
;;; \index{list\#scan-left}
;;; \begin{code}
{define
  "list#"
  scan-left
  [|f acc l|
   {let ((acc-list (list acc)))
     {let scan-left ((acc acc)
                     (last-cell acc-list)
                     (l l))
       (if (null? l)
           [acc-list]
           [{let ((newacc (f acc
                             (car l))))
              (scan-left newacc
                         {begin
                           (set-cdr! last-cell (list newacc))
                           (cdr last-cell)}
                         (cdr l))}])}}]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  ;; (calulating factorials via scan-left
  (satisfies?
   [|l| (scan-left * 1 l)]
   '(
     (() (1))
     ((2) (1 2))
     ((2 3) (1 2 6))
     ((2 3 4) (1 2 6 24))
     ((2 3 4 5 ) (1 2 6 24 120))
     ))
  (satisfies?
   [|l| (scan-left + 5 l)]
   '(
     (() (5))
     ((1) (5 6))
     ((1 2) (5 6 8))
     ((1 2 3 4 5 6) (5 6 8 11 15 20 26)
     )))
  (satisfies?
   [|l| (scan-left - 5 l)]
   '(
     (() (5))
     ((1) (5 4))
     ((1 2) (5 4 2))
     ((1 2 3 4 5 6) (5 4 2 -1 -5 -10 -16))
     ))
  }
;;; \end{code}
;;;
;;; \newpage
;;; \section{list\#append!}
;;;   Like append, but recycles the last cons cell, so it's
;;;   faster, but mutates the input.
;;;
;;; \index{list\#append!}
;;; \begin{code}
{define
  "list#"
  append!
  [|l x|
   (if (null? l)
       [x]
       [{let ((head l))
          {let append! ((l l))
            (if (null? (cdr l))
                [(set-cdr! l x)]
                [(append! (cdr l))])}
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
;;;
;;;
;;; \newpage
;;; \section{list\#flatmap}
;;; \index{list\#flatmap}
;;; \begin{code}
{define
  "list#"
  flatmap
  [|f l|
   (fold-left append! '() (map f l))]
;;; \end{code}
;;;
;;; \noindent \cite[p. 123]{sicp}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|l| (flatmap [|x| (list x
                            (+ x 1)
                            (+ x 2))]
                 l)]
   '(
     ((10 20) (10 11 12 20 21 22))
     ))
  }
;;; \end{code}
;;;
;;;
;;; Mutating cons cells which were created in this procedure still
;;; respects referential-transparency
;;; from the caller's point of view.
;;;
;;; \newpage
;;; \section{list\#take}
;;; \index{list\#take}
;;; \begin{code}
{define
  "list#"
  take
  [|n l|
   (if (or (null? l) (= n 0))
       ['()]
       [(cons (car l)
              (take (- n 1)
                    (cdr l)))])]
;;; \end{code}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|n| (take n '(a b))]
   '(
     (0 ())
     (1 (a))
     (2 (a b))
     (3 (a b))
     ))}
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{list\#take-while}
;;; \index{list\#take-while}
;;; \begin{code}
{define
  "list#"
  take-while
  [|p? l|
   {let take-while ((l l))
     (if (or (null? l) ((complement p?) (car l)))
         ['()]
         [(cons (car l)
                (take-while (cdr l)))])}]
;;; \end{code}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|x| (take-while [|y| (not (equal? x y))]
                    '(a b c))]
   '(
     (a ())
     (b (a))
     (c (a b))
     (d (a b c))
     ))}
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{list\#drop}
;;; \index{list\#drop}
;;; \begin{code}
{define
  "list#"
  drop
  [|n l|
   (if (or (null? l) (= n 0))
       [l]
       [(drop (- n 1)
              (cdr l))])]
;;; \end{code}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|n| (drop n '(a b))]
   '(
     (0 (a b))
     (1 (b))
     (2 ())
     (3 ())
     ))}
;;; \end{code}
;;;
;;; \newpage
;;; \section{list\#drop-while}
;;; \index{list\#drop-while}
;;; \begin{code}
{define
  "list#"
  drop-while
  [|p? l|
   {let drop-while ((l l))
     (if (null? l)
         ['()]
         [(if ((complement p?) (car l))
              [l]
              [(drop-while (cdr l))])])}]
;;; \end{code}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|x| (drop-while [|y| (not (equal? x y))]
                    '(a b c))]
   '(
     (a (a b c))
     (b (b c))
     (c (c))
     (d ())
     (e ())
     ))}
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{list\#enumerate-interval}
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
;;;
;;; \newpage
;;; \section{list\#any?}
;;;
;;; \index{list\#any?}
;;; \begin{code}
{define
  "list#"
  any?
  [|l|
   (if (null? l)
       [#f]
       [(if (car l)
            [#t]
            [(any? (cdr l))])])]
;;; \end{code}
;;; \subsection*{Test}
;;; \begin{code}
  (satisfies?
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
;;;
;;; \newpage
;;; \section{list\#zip}
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
;;; \end{code}
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
;;;
;;; \newpage
;;; \section{list\#permutations}
;;; \index{list\#permutations}
;;; \begin{code}
{define
  "list#"
  permutations
  [|l|
   (if (null? l)
       ['()]
       [{let permutations ((l l))
          (if (null? (cdr l))
              [(list l)]
              [(flatmap [|x| (map [|y| (cons x y)]
                                  (permutations (remove x l)))]
                        l)])}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
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
;;;
;;; Inspired by \cite[p. 124]{sicp}, although I think they have a slight
;;; mistake in their code.  Given their definition (permutations '())
;;; evaluates to '(()), instead of '().
;;;
;;; See also \cite[p. 45]{taocp}
;;;
;;; \newpage
;;; \section{list\#sublists}
;;; \index{list\#sublists}
;;; \begin{code}
{define
  "list#"
  sublists
  [|l|
   (if (null? l)
       ['()]
       [(cons l (sublists (cdr l)))])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   sublists
   '(
     (() ())
     ((3) ((3)))
     ((2 3) ((2 3) (3)))
     ((1 2 3) ((1 2 3) (2 3) (3)))
     ))}
;;; \end{code}
;;;
;;; \newpage
;;; \section{list\#ref-of}
;;; The inverse of list-ref.
;;;
;;; \index{list\#ref-of}
;;; \begin{code}
{define
  "list#"
  ref-of
  [|l x #!key (onMissing noop)|
   (if (null? l)
       [(onMissing)]
       [{let ref-of ((l l)
                     (index 0))
          (if (equal? (car l) x)
              [index]
              [(if (null? (cdr l))
                   [(onMissing)]
                   [(ref-of (cdr l) (+ index 1))])])}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|x| (ref-of '(a b c d e f g) x)]
   '(
     (z noop)
     (a 0)
     (b 1)
     (g 6)
     ))
  (satisfies?
   [|x| (ref-of '(a b c d e f g)
                x
                onMissing: ['missing])]
   '(
     (z missing)
     (a 0)
     ))
  {let ((l '(a b c d e f g)))
    (satisfies?
     [|x| (list-ref l (ref-of l x))]
     '(
       (a a)
       (b b)
       (g g)
       ))}
  }
;;; \end{code}
;;;
;;;
;;;
;;; \newpage
;;; \section{list\#partition}
;;;  Partitions the input list into two lists, one list where
;;;  the predicate matched the element of the input list, the second list
;;;  where the predicate did not match the element of the input list.
;;;
;;;
;;; \index{list\#partition}
;;; \begin{code}
{define
  "list#"
  partition
  [|l p?|
   {let partition ((l l)
                   (trueList '())
                   (falseList '()))
     (if (null? l)
         [(list trueList falseList)]
         [(if (p? (car l))
              [(partition (cdr l)
                          (cons (car l) trueList)
                          falseList)]
              [(partition (cdr l)
                          trueList
                          (cons (car l) falseList))])])}]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|l| (partition l [|x| (<= x 3)])]
   '(
     (() (()
          ()))
     ((3 2 5 4 1) ((1 2 3)
                   (4 5)))
     ))}
;;; \end{code}
;;;
;;; \newpage
;;; \section{list\#sort}
;;; \index{list\#sort}
;;; \begin{code}
{define
  "list#"
  sort
  [|l comparison?|
   {let sort ((l l))
     (if (null? l)
         ['()]
         [{let* ((current-node (car l))
                 (p (partition (cdr l)
                               [|x| (comparison?
                                     x
                                     current-node)]))
                 (less-than (car p))
                 (greater-than (cadr p)))
            (append! (sort less-than)
                     (cons current-node
                           (sort greater-than)))}])}]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|l| (sort l <)]
   '(
     (() ())
     ((1 3 2 5 4 0) (0 1 2 3 4 5))
     ))}
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{list\#reverse!}
;;;   Reverses the list quickly by reusing cons cells
;;;
;;; \index{list\#reverse"!}
;;; \begin{code}
{define
  "list#"
  reverse!
  [|l|
   (if (null? l)
       ['()]
       [{let reverse! ((cons-cell l) (reversed-list '()))
          (if (null? (cdr cons-cell))
              [(set-cdr! cons-cell reversed-list)
               cons-cell]
              [{let ((rest (cdr cons-cell)))
                 (set-cdr! cons-cell reversed-list)
                 (reverse! rest cons-cell)}])}])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   reverse!
   '(
     (() ())
     ((1) (1))
     ((2 1) (1 2))
     ((3 2 1) (1 2 3))
     ))}
;;; \end{code}
;;;
;;;
;;;
;;;
;;; \newpage
;;; \chapter{Strings}
;;; \section{string\#string-liftList}
;;;
;;; Strings are sequences of characters, just as lists are
;;; sequences of arbitrary Scheme objects. ``string-liftList''
;;; takes a one-argument
;;; list processing procedure, and evaluates to an
;;; equivalent procedure for strings.
;;;
;;;
;;; \index{string\#string-liftList"}
;;; \begin{code}
{define
  "string#"
  string-liftList
  [|f|
   [|#!rest s|
    (list->string
     (apply f
            (map string->list s)))]]}
;;;
;;; \end{code}
;;; \newpage


;;; \section{string\#string-reverse}
;;;
;;; \index{string\#string-reverse"}
;;; \begin{code}
{define
  "string#"
  string-reverse
  (string-liftList reverse!)
;;;
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   string-reverse
   '(
     ("" "")
     ("foo" "oof")
     ("bar" "rab")
     ))
  }
;;; \end{code}
;;; \newpage

;;; \section{string\#string-take}
;;;
;;; \index{string\#string-take"}
;;; \begin{code}
{define
  "string#"
  string-take
  [|n s| ((string-liftList [|l| (take n l)])
          s)]
;;;
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|s| (string-take 2 s)]
   '(
     ("" "")
     ("foo" "fo")
     ))
  }
;;; \end{code}
;;; \newpage

;;; \section{string\#string-map}
;;;
;;; \index{string\#string-map"}
;;; \begin{code}
{define
  "string#"
  string-map
  [|f s| ((string-liftList [|l| (map f l)])
          s)]
;;;
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|s| (string-map [|c|
                     (integer->char
                      (+ (char->integer #\a)
                         (modulo (+ (- (char->integer c)
                                       (char->integer #\a))
                                    13)
                                 26)))]
                      s)]

   '(
     ("" "")
     ("abc" "nop")
     ("nop" "abc")
     ))

  }
;;; \end{code}
;;; \newpage



;;; \chapter{Symbols}

;;; \section{symbol\#symbol-liftList}
;;;
;;; Symbols are sequences of characters, just as lists are
;;; sequences of arbitrary Scheme objects. ``symbol-liftList''
;;; takes a one-argument
;;; list processing procedure, and evaluates to an
;;; equivalent procedure for symbols.
;;;
;;;
;;; \index{symbol\#symbol-liftList"}
;;; \begin{code}
{define
  "symbol#"
  symbol-liftList
  [|f|
   [|#!rest s|
    (string->symbol
     (apply (string-liftList f)
            (map symbol->string s)))]]
;;;
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   (symbol-liftList reverse)
   '(
     (foo oof)
     (bar rab)
     ))
  (equal? ((symbol-liftList append!) 'foo 'bar)
          'foobar)
  }
;;; \end{code}

;;; \newpage
;;; \chapter{Streams}
;;;
;;; Streams are sequential collections like lists, but the
;;; ``cdr'' of each pair must be a zero-argument lambda value.  That lambda
;;; is automatically evaluated when ``(stream-cdr s)'' is applied,
;;; where s is a stream created by ``stream-cons''.
;;; For more information, consult ``The Structure and
;;; Interpretation of Computer Programs''\footnote{although, they
;;; define ``stream-cons'' as syntax, instead of passing a lambda
;;; to the second argument}.
;;;
;;; \section{stream\#stream-cons}
;;;
;;; \begin{code}
{define-structure
  "stream#"
  stream a d}
;;; \end{code}
;;;
;;; \section{stream\#stream-car}
;;; Get the first element of the stream.
;;;
;;; \index{stream\#stream-car}
;;; \begin{code}
{define
  "stream#"
  stream-car
  stream-a}
;;; \end{code}
;;;
;;; \noindent \cite[p. 321]{sicp}.
;;;
;;; \newpage
;;; \section{stream\#stream-cdr}
;;; Forces the evaluation of the next element of the stream.
;;;
;;; \index{stream\#stream-cdr}
;;; \begin{code}
{define
  "stream#"
  stream-cdr
  [|s| {force (stream-d s)}]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 321]{sicp}.
;;; \newpage
;;;
;;; \section{stream\#stream-cons}
;;;
;;; Like ``cons'', creates a pair.  The second argument must be a zero-argument
;;; lambda value.
;;;
;;; \index{stream\#stream-cons}
;;; \begin{code}
{define-macro
  "stream#"
  stream-cons
  [|a d|
   (if (or (not (list? d))
           (not (equal? 'lambda (car d)))
           (null? (cdr d))
           (not (equal? '() (cadr d))))
       [(error "stream#stream-cons requires a zero-argument \
                lambda in it's second arg")]
       [`(make-stream ,a {delay ,(caddr d)})])]
;;; \end{code}
;;;
;;; \noindent \cite[p. 321]{sicp}.
;;; \subsection*{Tests}
;;; \begin{code}
  {begin
    {let ((s (stream-cons 1 [2])))
      {and
       (equal? (stream-car s)
               1)
       (equal? (stream-cdr s)
               2)}}}}
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{stream\#stream-null}
;;;
;;; \index{stream\#stream-null}
;;; \begin{code}
{define
  "stream#"
  stream-null
  '()
  }
;;; \end{code}
;;;
;;; \section{stream\#stream-null?}
;;;
;;; \index{stream\#stream-null?}
;;; \begin{code}
{define
  "stream#"
  stream-null?
  null?
;;; \end{code}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (stream-null?
   (stream-cdr
    (stream-cdr (stream-cons 1 [(stream-cons 2
                                             [stream-null])]))))
  }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{stream\#list-\textgreater stream}
;;; Converts a list into a stream
;;;
;;; \index{stream\#list-\textgreater stream}
;;; \begin{code}
{define
  "stream#"
  list->stream
  [|l| (if (null? l)
           [stream-null]
           [(stream-cons (car l)
                         [{let list->stream ((l (cdr l)))
                            (if (null? l)
                                ['()]
                                [(stream-cons (car l)
                                              [(list->stream
                                                (cdr l))])])}])])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((foo (list->stream '(1 2 3))))
    {and (equal? 1 (stream-car foo))
         (equal? 2 (stream-car
                    (stream-cdr foo)))
         (equal? 3 (stream-car
                    (stream-cdr
                     (stream-cdr foo))))
         (stream-null? (stream-cdr
                        (stream-cdr
                         (stream-cdr foo))))}}}
;;; \end{code}
;;;
;;; \newpage
;;; \section{stream\#stream-\textgreater list}
;;; Converts a stream into a list
;;;
;;; \index{stream\#stream-\textgreater list}
;;; \begin{code}
{define
  "stream#"
  stream->list
  [|s|
   (if (stream-null? s)
       ['()]
       [(cons (stream-car s)
              (stream->list
               (stream-cdr s)))])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (equal? '(1 2 3) (stream->list (list->stream '(1 2 3))))
  }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{stream\#stream-ref}
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
              [(if (not (stream-null? (stream-cdr s)))
                   [(stream-ref (stream-cdr s) (- n 1))]
                   [(onOutOfBounds)])])}])]
;;; \end{code}
;;;
;;; \noindent \cite[p. 319]{sicp}.
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|i| (stream-ref (list->stream '(5 4 3 2 1)) i)]
   '(
     (-1 noop)
     (0 5)
     (4 1)
     (5 noop)
     )
   )
  (equal? (stream-ref (list->stream '(5 4 3 2 1))
                      5
                      onOutOfBounds: ['out])
          'out)}
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{stream\#stream-map}
;;; The analogous procedure of \#\#map.
;;;
;;; \index{stream\#stream-map}
;;; \begin{code}
{define
  "stream#"
  stream-map
  [|f #!rest list-of-streams|
   {let stream-map ((list-of-streams list-of-streams))
     (if (any? (map stream-null? list-of-streams))
         [stream-null]
         [(stream-cons (apply f
                              (map stream-car list-of-streams))
                       [(stream-map (map stream-cdr list-of-streams))])])}]
;;; \end{code}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (equal? '(6 5 4 3 2)
          (stream->list
           (stream-map [|x| (+ x 1)]
                       (list->stream '(5 4 3 2 1)))))
  (equal? '(6 5 4 3 2)
          (stream->list
           (stream-map [|x y| (+ x y)]
                       (list->stream '(5 4 3 2 1))
                       (list->stream '(1 1 1 1 1)))))
  }
;;;
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{stream\#stream-filter}
;;; The analogous procedure of list\#filter.
;;;
;;; \index{stream\#stream-filter}
;;; \begin{code}
{define
  "stream#"
  stream-filter
  [|p? s|
   {let stream-filter ((s s))
     (if (stream-null? s)
         [stream-null]
         [{let ((first (stream-car s)))
            (if (p? first)
                [(stream-cons
                  first
                  [(stream-filter (stream-cdr s))])]
                [(stream-filter (stream-cdr s))])}])}]
;;; \end{code}
;;;
;;; \subsection*{Tests}
;;; \begin{code}
  (equal? '(2 1)
          (stream->list
           (stream-filter [|x| (not (= 4 x))]
                          (list->stream '(2 4 1 4)))))
  }
;;;
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{stream\#stream-enumerate-interval}
;;; \index{stream\#stream-enumerate-interval}
;;; \begin{code}
{define
  "stream#"
  stream-enumerate-interval
  [|low high #!key (step 1)|
   (if (> low high)
       ['()]
       [(stream-cons low
                     [(stream-enumerate-interval (+ low step)
                                                 high
                                                 step: step)])])]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
  (equal? (stream->list
           (stream-enumerate-interval 1 10))
          '(1 2 3 4 5 6 7 8 9 10))
  (equal? (stream->list
           (stream-enumerate-interval 1 10 step: 2))
          '(1 3 5 7 9))}
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \chapter{General Procedures}
;;;
;;;
;;; \section{lang\#compose}
;;;
;;; Libbug is a library, meant to be used by other projects.  From libbug, these
;;; projects will require namespace definitions, as well as macro definitions.
;;; As such, besides defining the macro, libbug\#define-macro\footnote{
;;; defined in section ~\ref{sec:libbugdefinemacro}}
;;; also exports the
;;; namespace definition and the macro definitions to external files.
;;;
;;;
;;; \index{lang\#compose}
;;; \begin{code}
{define-macro
  "lang#"
  compose
  [|#!rest fs|
   (if (null? fs)
       ['identity]
       [{let ((args (gensym)))
          `[|#!rest ,args|
            ,{let compose ((fs fs))
               (if (null? (cdr fs))
                   [`(apply ,(car fs)
                            ,args)]
                   [`(,(car fs)
                      ,(compose (cdr fs)))])}]}])]
;;; \end{code}
;;;
;;; \noindent \cite[p. 66]{onlisp}
;;;
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
;;;
;;; Macro-expansions occur during compile-time, so how should a person
;;; test them?  Libbug provides ``macroexpand-1'' which treats the macro
;;; as a procedure which transforms lists, and as such is able to be tested.
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
;;;
;;;
;;; ``macroexpand-1'' expands the unevaluated code passed to the
;;; macro into the new form, which the compiler would have then compiled
;;; if ``macroexpand-1'' had not been present.  But, how should ``gensyms''
;;; evaluate, since by definition it creates symbols which cannot be entered
;;; into a program?  During the expansion of ``macroexpand-1'', ``gensym''
;;; is overridden into a procedure
;;; which expands into symbols like ``gensymed-var1'', ``gensymed-var2'', etc.  Each
;;; call during a macro-expansion generates a new, unique symbol.  Although this symbol
;;; may clash with symbols in the expanded code, this is not a problem, as these
;;; symbols are only generated in the call to ``macroexpand-1''.  As such,
;;; ``eval''ing code generated from ``macroexpand-1'' is not recommended.
;;;
;;;
;;; \newpage
;;; \section{lang\#aif}
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
;;;
;;; \noindent \cite[p. 191]{onlisp}
;;; \subsection*{Tests}
;;; \begin{code}
  (equal? {aif (+ 5 10) (* 2 it)}
          30)
  (equal? {aif #f (* 2 it)}
          #f)
  (equal? (macroexpand-1 {aif (+ 5 10)
                              (* 2 it)})
          '{let ((it (+ 5 10)))
             (if it
                 [(* 2 it)]
                 [#f])})
;;;
  }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{lang\#with-gensyms}
;;;   Utility for macros to minimize repetitive calls to ``gensym''.
;;;
;;; \index{lang\#with-gensyms"}
;;; \begin{code}
{define-macro
  "lang#"
  with-gensyms
  [|symbols #!rest body|
   `{let ,(map [|symbol| `(,symbol {gensym})]
               symbols)
      ,@body}]
;;; \end{code}
;;;
;;; \noindent \cite[p. 145]{onlisp}
;;; \subsection*{Tests}
;;; \begin{code}
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
;;;
;;;
;;; \newpage
;;; \chapter{Generalized Assignment}
;;;  \label{sec:endinglibbug}
;;; \section{lang\#setf!}
;;; Sets a variable using its ``getting'' procedure, as done in Common Lisp.
;;; The implementation inspired by \cite{setf}.
;;;
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
;;; \end{code}
;;; \begin{code}
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
;;; \end{code}
;;; \begin{code}
          (else `(,((symbol-liftList
                     [|l suffix| (append!
                                  (if (equal? (reverse
                                               '(#\- #\r #\e #\f))
                                              (take 4 (reverse l)))
                                      [(reverse (drop 4
                                                      (reverse l)))]
                                      [l])
                                  suffix)])
                    (car exp)
                    '-set!)
                  ,@(cdr exp)
                  ,val))}])]
;;; \end{code}
;;; \subsection*{Tests}
;;;
;;; \noindent Test setting a varible.
;;;
;;; \begin{code}
  (equal? {macroexpand-1
           {setf! a 10}}
          '(set! a 10))
  {let ((a 5))
    {setf! a 10}
    (equal? a 10)}
;;; \end{code}
;;;
;;; \noindent Test setting ``car''.
;;;
;;; \begin{code}
  (equal? {macroexpand-1
           {setf! (car a) 10}}
          '(set-car! a 10))
  {let ((a '(1 2)))
    {setf! (car a) 10}
    (equal? (car a) 10)}
;;; \end{code}
;;;
;;; \noindent Test setting ``cdr''.
;;;
;;; \begin{code}
  (equal? {macroexpand-1
           {setf! (cdr a) 10}}
          '(set-cdr! a 10))
  {let ((a '(1 2)))
    {setf! (cdr a) 10}
    (equal? (cdr a) 10)}
;;; \end{code}
;;;
;;; \noindent Testing all of the ``car'' through ``cddddr'' procedures will be highly
;;; repetitive.  Instead, create a list which has an element at each of those
;;; accessor procedures, and test each.
;;;
;;; \begin{code}
  {eval
   `{begin
      ,@(map [|x| `{let ((a '(
                              (
                               (
                                (1) 2)
                               (3)
                               ())
                              (
                               (4)
                               5)
                              (6)
                              ()
                              )))
                     {setf! (,x a) 10}
                     (equal? (,x a) 10)}]
             '(car cdr

               caar cadr cdar cddr

               caaar caadr cadar caddr
               cdaar cdadr cddar cdddr

               caaaar caaadr caadar caaddr
               cadaar cadadr caddar cadddr
               cdaaar cdaadr cdadar cdaddr
               cddaar cddadr cdddar cddddr
               ))}}
;;; \end{code}
;;;
;;; \noindent Test setting procedures where the setting procedure is
;;; the name of the getting procedure, suffixed by '-set!'.
;;;
;;; \begin{code}
  (equal? {macroexpand-1
           {setf! (stream-a s) 10}}
          '(stream-a-set! s 10))
  {begin
    {let ((a (make-stream 1 2)))
      {setf! (stream-a a) 10}
      (equal? (make-stream 10 2)
              a)}}
;;; \end{code}
;;;
;;; \noindent Test setting procedures where the setting procedure is
;;; the name of the getting procedure, removing the suffix of
;;; '-ref', and adding a suffix of '-set!'.
;;;
;;; \begin{code}
  (equal? {macroexpand-1
           (setf! (string-ref s 0) #\q)}
          '(string-set! s 0 #\q))
  {let ((s "foobar"))
    (setf! (string-ref s 0) #\q)
    (equal? s "qoobar")}
  (equal? {macroexpand-1
           (setf! (vector-ref v 2) 4)}
          '(vector-set! v 2 4))
  {let ((v (vector 1 2 '() "")))
    (setf! (vector-ref v 2) 4)
    (equal? v
            (vector 1 2 4 ""))}
  }
;;; \end{code}
;;;
;;; At the beginning of the code, in section~\ref{sec:beginninglibbug}, ``bug-language.scm''
;;; was imported, so that ``libbug\#define'', and ``libbug\#define-macro'' can be used.
;;; This chapter is the end of the file ``main.bug.scm''.  However, as will be shown
;;; in the next chapter, ``bug-languge.scm'' opened files for writing during compile-time,
;;; and they must be closed, accomplished by importing ``bug-language-end.scm'',
;;; defined in section ~\ref{sec:closefiles}.
;;;
;;; \begin{code}
(include "bug-language-end.scm")
;;; \end{code}
;;;
;;;
;;;
