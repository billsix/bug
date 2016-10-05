;;; %Copyright 2014-2016 - William Emerison Six
;;; %All rights reserved
;;; %Distributed under LGPL 2.1 or Apache 2.0
;;;
;;; \documentclass[twoside]{book}
;;; \pagenumbering{gobble}
;;; \usepackage[paperwidth=8.25in, paperheight=10.75in,bindingoffset=0.2in, left=0.5in, right=0.5in]{geometry}
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
;;;{define permutations
;;; [|l|
;;;   (if (null? l)
;;;       ['()]
;;;       [{let permutations ((l l))
;;;          (if (null? (cdr l))
;;;              [(list l)]
;;;              [(flatmap [|x|
;;;                         (map [|y| (cons x y)]
;;;                              (permutations (remove x l)))]
;;;                        l)])}])]}
;;; \end{examplecode}
;;;
;;; What does the code do?  How did the author intend for it to be used?
;;; In trying to answer those questions, fans of statically-typed programming
;;; languages might lament the lack of types, as types help them to reason about
;;; programs and help them to deduce where to look to find more information.
;;; In trying to answer those questions,
;;; fans of dynamically-typed languages might argue ``Look at the tests!'',
;;; as tests ensure the code functions in a user-specified way and
;;; they serve as a form of documentation.  But
;;; where are those tests?  Probably in some other file whose filesystem path is
;;; similar to the current file's path (e.g., src/com/BigCorp/HugeProject/Foo.java
;;; is tested by test/com/BigCorp/HugeProject/FooTest.java).
;;; Then you'd have to find the file, open the file, look through it
;;; while ignoring tests which are
;;; for other methods.  Frankly, it's too much work and it interrupts the flow
;;; of coding, at least for me.
;;;
;;; But how else would a programmer organize tests?  Well in this book, which is the
;;; implementation of a library called ``libbug'',
;;; tests are specified after the procedure's definition,
;;; but they are only executed at compile-time.  Should any test fail the compiler will
;;; exit in error, like a type error in a
;;; statically-typed language.
;;;
;;; \begin{examplecode}
;;;{unit-test
;;; (satisfies?
;;;  permutations
;;;  '(
;;;    (() ())
;;;    ((1) ((1)))
;;;    ((1 2) ((1 2)
;;;            (2 1)))
;;;    ((1 2 3) ((1 2 3)
;;;              (1 3 2)
;;;              (2 1 3)
;;;              (2 3 1)
;;;              (3 1 2)
;;;              (3 2 1)))
;;;    ))}
;;; \end{examplecode}
;;;
;;; Why does collocating tests with definitions matter?
;;; Towards answering the questions ``what does the code do?'' and ``how did the author
;;; intend for it to be used?'', there is neither searching through files nor guessing
;;; how the code was originally intended to be used.
;;; The fact that the
;;; tests are collocated with the procedure definition means that the reader can
;;; inspect the tests without switching between files, perhaps
;;; before looking at the procedure's definition.  And the reader
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
;;; which augments Scheme's small set of built-in procedures.
;;; Libbug provides procedures for list processing, streams,
;;; control structures,
;;; general-purpose evaluation at compile-time,
;;; and a
;;; compile-time test framework written in only 9 lines of code!
;;; Programs written using libbug optionally may be
;;; programmed in a relatively unobstructive
;;; ``literate programming''\footnote{http://lmgtfy.com/?q=literate+programming}
;;; style, so that a program can be read linearly in a book form.
;;;
;;; \section{Prerequisites}
;;;
;;; The reader is assumed to be somewhat familiar with Scheme, with Common Lisp-style
;;; macros, and with recursive design.  If the book proves too difficult for you,
;;; read ``Simply Scheme''
;;; \cite{ss}\footnote{available on-line for no cost}
;;; or ``The Little Schemer'' \cite{littleschemer}.  Since libbug uses Gambit Scheme's
;;; Common Lisp-style macros, the author recommends reading ``On Lisp''
;;; \cite{onlisp}\footnote{available on-line for no cost}.
;;; The other books listed in the bibliography, all of which inspired ideas for this
;;; book, are recommended reading but are
;;; not necessary to understand the content of this book.
;;;
;;; \section{Parts}
;;;  This book is a ``literate program'', meaning both that the source code of libbug is
;;;  embedded within this book, and that the book is intended to be able to be
;;;  read linearly.
;;;  As such, new procedures defined are dependent upon
;;;  either standard Gambit Scheme procedures or
;;;  procedures which have already been defined earlier in the book.  In writing the book,
;;;  however, it became quite apparent that the foundation upon which libbug is constructed
;;;  is by far the most difficult material.  Reading it in the order which the compiler
;;;  compiles it
;;;  would cause the reader to quickly get lost in the ``how'',
;;;  before understanding ``why''.
;;;
;;;  As such, the ordering of the book was rearranged in an effort to keep the reader
;;;  engaged and curious.  The book begins with ``Part 1, The Implementation of Libbug''
;;;  and ends with ``Part 2, Foundations Of Libbug''.
;;;  The Gambit compiler, however, compiles Part 2 first, then Part 1.
;;;
;;; \section{Conventions}
;;; Code which is part of libbug will be outlined and
;;; will have line numbers on the left.
;;;
;;; \begin{code}
;; This is part of libbug.
;;; \end{code}
;;;
;;; \noindent
;;; Example code which is not part of libbug will not be outlined nor will it have line
;;; numbers.
;;;
;;; \begin{examplecode}
;;; (+ 1 ("This is NOT part of libbug"))
;;; \end{examplecode}
;;;
;;; \noindent
;;; Some examples within this book show sessions of the use of the ``bug-gsi'' Read-Evaluate-Print-Loop (REPL).
;;; Such examples will look like the following:
;;;
;;; \begin{examplecode}
;;;> (+ 1 2)
;;;3
;;; \end{examplecode}
;;;
;;; \noindent
;;; The line on which the user entered text begins with a ``\textgreater''.  The result
;;; of evaluating that line appears on the subsequent line. In this case, 1 added to 2
;;; evaluates to 3.
;;;
;;; \subsection{Syntactic Conventions}
;;; In libbug, the notation
;;;
;;; \begin{examplecode}
;;; (fun arg1 arg2)
;;; \end{examplecode}
;;;
;;; \noindent
;;;  means evaluate ``fun'', ``arg1''
;;; and ``arg2'' in any order, then apply ``fun'' to ``arg1'' and ``arg2'';
;;; standard Scheme semantics for invoking a procedure.  But since macros
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
;;;  The Scheme source code is located at http://github.com/billsix/bug\footnote{
;;;  This book was generated from git commit \input{version.tex}}.
;;;  The Scheme files produce the libbug library, as well as this book.
;;;  Currently the code works on various distributions of Linux, on FreeBSD, and on Mac
;;;  OS X.  The build currently does not work on Windows.
;;;
;;; You will need a C compiler such as GCC,
;;; Autoconf, Automake, and Gambit
;;; Scheme\footnote{http://gambitscheme.org} version 4.8 or newer.
;;;
;;; To compile the book and library, execute the following on the command line:
;;;
;;; \begin{examplecode}
;;; $ ./autogen.sh
;;; $ ./configure --prefix=$BUG_HOME --enable-pdf
;;; $ make
;;; $ make install
;;; \end{examplecode}
;;;
;;; \begin{itemize}
;;;   \item
;;;      The argument to ``prefix'' tells Autoconf the location into which libbug
;;;      should be installed when ``make install'' is executed. ``\$BUG\textunderscore HOME'' is an
;;;      environment variable that I have not defined, so the reader should substitute
;;;      ``\$BUG\textunderscore HOME'' with an actual filesystem path.
;;;   \item
;;;      ``--enable-pdf'' means to build this book as a PDF.  To disable the creation of the PDF,
;;;      substitute ``--enable-pdf=no''.
;;; \end{itemize}
;;;
;;; \section{Comparison of Compile-Time Computations in Other Languages}
;;;
;;; What exactly is computation at compile-time?  An introduction to the topic is provided
;;; in Appendix~\ref{sec:appendix1}, demonstrated
;;; in languages of more widespread use (C and C++),
;;; along with a comparison
;;; of their expressive power.
;;;
;;;
;;; \part{The Implementation of Libbug}
;;;
;;; \chapter{Introductory Procedures}
;;;  \label{sec:beginninglibbug}
;;;
;;; This chapter begins the definition of libbug's standard library of Scheme procedures and
;;; macros\footnote{The code within chapters~\ref{sec:beginninglibbug}
;;; through ~\ref{sec:endinglibbug} inclusive is found in
;;; ``src/main.bug.scm''.}, along with tests which are run as part of the
;;; compilation process.  If any test fails, the compiler will exit in error,
;;; much like a type error in a statically-typed language.
;;;
;;; To gain such functionality libbug cannot be defined using Gambit Scheme's
;;; ``\#\#define'', ``\#\#define-macro'', and ``\#\#define-structure'', since
;;; they only define variables and
;;; procedures for use at run-time\footnote{well... that statement is not true
;;; for ``\#\#define-macro'', but it makes for a simpler explanation upon first reading}.
;;; Instead, definitions within
;;; libbug use ``libbug-private\#define'', ``libbug-private\#define-macro'', and
;;; ``libbug-private\#\#define-structure''\footnote{Per convention
;;; within libbug, procedures namespaced to ``libbug-private'' are not compiled into the library
;;; or other output files; such procedures are meant for private use within the implementation
;;; of libbug.}, which  are implemented in Chapter~\ref{sec:buglang}.
;;; How they are implemented is not relevant yet, since the use of these
;;; procedure-defining procedures will be explained
;;; incrementally.
;;;
;;; \begin{code}
(include "bug-language.scm")
{##namespace ("libbug-private#" define define-macro define-structure)}
{##namespace ("bug#" if)}
;;;\end{code}
;;; \begin{itemize}
;;;   \item On line 1, the code which makes computation at compile-time possible
;;;     is imported. The contents of that file are in Chapter~\ref{sec:buglang}.
;;;   \item On line 2, Gambit's ``\#\#namespace'' procedure is invoked, to
;;;     tell the compiler that all subsequent uses of ``define'', ``define-macro'',
;;;     and ``define-structure'' shall use libbug's version of those procedures
;;;     instead of Gambit's.
;;;   \item On line 3, all subsequent uses of ``if'' shall use libbug's version.
;;; \end{itemize}
;;;
;;;
;;; \newpage
;;; \section{noop}
;;; The first definition is ``noop'', a procedure which takes no arguments and
;;; which evaluates to the symbol 'noop.
;;;
;;; \index{noop}
;;; \begin{code}
{define noop
  ['noop]}
;;; \end{code}
;;;
;;; \begin{itemize}
;;;   \item On line 1, the libbug-private\#define macro\footnote{defined in section ~\ref{sec:libbugdefine}}
;;; is invoked.
;;;   \item On line 1, the variable name ``noop''.
;;;   \item On line 2, the lambda literal to be stored into the variable.
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
;;;
;;; \begin{code}
{unit-test
 (equal? (noop) 'noop)}
;;; \end{code}
;;;
;;; \begin{itemize}
;;;  \item  On line 1, an expression which evaluates to a boolean is defined.
;;;  This is a
;;; test which will be evaluated at compile-time.  Should the test fail,
;;; the build process will fail and neither the shared library nor the document which
;;; you are currently reading will be created.
;;; Tests are not present in the created
;;; library.
;;; \end{itemize}
;;;
;;; ``noop'' does not look useful at first glance, but it is frequently used when
;;;  a procedure is required but the resulting value of it is not.
;;;  For instance, ``noop'' is used as a default ``exception-handler'' for many
;;;  procedures within libbug.
;;;
;;; \newpage
;;; \section{identity}
;;; ``identity'' is a procedure of one argument which evaluates to
;;; its argument. \cite[p. 2]{calculi}
;;;
;;; \index{identity}
;;;
;;; \begin{code}
{define identity
  [|x| x]}
;;; \end{code}
;;; \begin{itemize}
;;;   \item On line 2, ``bug-gscpp'' expands
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
;;;
;;;
;;; ``unit-test'' can take more than one test as parameters.
;;;
;;; \begin{code}
{unit-test
 (equal? "foo" (identity "foo"))
 (equal? identity (identity identity))}
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{all?}
;;; Like regular Scheme's ``and'', but takes a list instead of a variable number of arguments, and
;;; all elements of the list are evaluated before ``all?'' is applied.
;;;
;;; \label{sec:langiffirstuse}
;;; \index{all?}
;;; \begin{code}
{define all?
  [|l|
   (if (null? l)
       [#t]
       [(if (not (car l))
            [#f]
            [(all? (cdr l))])])]}
;;; \end{code}
;;; \begin{itemize}
;;;   \item On line 3, ``if'', which is currently namespaced to ``bug\#if''\footnote{
;;;      defined in section~\ref{sec:langif} }, takes
;;;         lambda expressions for the two parameters. Libbug pretends that \#t and \#f are
;;;         ``Church Booleans'' \cite[p. 58]{tapl}, and that ``bug\#if'' is just syntactic sugar:
;;;
;;;
;;; \begin{examplecode}
;;;{define #t [|t f| (t)]}
;;;{define #f [|t f| (f)]}
;;;{define bug#if [|b t f| (b t f)]}
;;; \end{examplecode}
;;;
;;; \noindent As such, ``bug\#if'' would not be a special form, and is more consistent with the
;;; rest of libbug.
;;;
;;; \end{itemize}
;;;
;;;
;;;
;;; \begin{code}
{unit-test
 (all? '())
 (all? '(1))
 (all? '(#t))
 (all? '(#t #t))
 (not (all? '(#f)))
 (not (all? '(#t #t #t #f)))}
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
;;; \section{satisfies?}
;;;
;;; When writing multiple tests, why explicitly invoke the procedure repeatedly
;;; with varying inputs and outputs, as was done for ``all?''?  Instead, provide
;;; the procedure and a list
;;; of input/output pairs.
;;;
;;; \index{satisfies?}
;;; \begin{code}
{define satisfies?
  [|f list-of-pairs|
   (all? (map [|pair| (equal? (f (car pair))
                              (cadr pair))]
              list-of-pairs))]}
;;; \end{code}
;;;
;;; \footnote{Within libbug, a parameter named ``f'' usually means the parameter is
;;;   a procedure.}

;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|x| (+ x 1)]
  '(
    (0 1)
    (1 2)
    (2 3)
    ))
 (satisfies?
  all?
  '(
    (() #t)
    ((1) #t)
    ((#t) #t)
    ((#t #t) #t)
    ((#f) #f)
    ((#t #t #t #f) #f)))
 }
;;; \end{code}
;;;
;;; For the remaining procedures, if the tests do an adequate job of explaining
;;; the code, there will be no written documentation.
;;;
;;; \newpage
;;; \section{while}
;;;
;;; \index{while}
;;;
;;; Programmers who are new to the Scheme language  may be surprised that
;;; the language provides no built-in syntax for looping, such as ``for''
;;; or ``while''.  A better question though, is why don't other
;;; languages provide primitives from which you can create
;;; those looping constructs yourself?  ``Take the red pill.''
;;;
;;;
;;; \begin{code}
{define while
  [|pred? body|
   {let while ((val 'noop))
     (if (pred?)
         [(while (body))]
         [val])}]}
;;; \end{code}
;;;
;;; \footnote{Within libbug, a parameter named ``pred?'' or ``p?'' usually means the parameter
;;;   is a predicate, meaning a procedure which returns true or false.}
;;;
;;;
;;; \begin{code}
{unit-test
 {let ((a 0))
   {and (equal? (while [(< a 5)]
                       [{set! a (+ a 1)}])
                #!void)
        (equal? a 5)}}
 {let ((a 0))
   {and (equal? (while [(< a 5)]
                       [{set! a (+ a 1)}
                        'foo])
                'foo)
        (equal? a 5)}}}
;;; \end{code}
;;;
;;;
;;;
;;; \newpage
;;; \section{numeric-if}
;;;   A conditional expression for numbers, based on their sign. ``numeric-if''
;;;   uses Gambit's keyword syntax.  ``ifPositive'', ``ifZero'', and ``ifNegative'' are
;;;   an optionals argument, each with their default value as the value in the ``noop''
;;;   variable.
;;;
;;;
;;; \index{numeric-if}
;;; \begin{code}
{define numeric-if
  [|n #!key (ifPositive noop) (ifZero noop) (ifNegative noop)|
   (if (> n 0)
       [(ifPositive)]
       [(if (= n 0)
            [(ifZero)]
            [(ifNegative)])])]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 150, called ``nif'']{onlisp}
;;;
;;; Keyword arguments are optionally passed to the procedure, and use the following syntax.
;;;
;;; \begin{code}
{unit-test
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
;;; \section{atom?}
;;; \index{atom?}
;;; \begin{code}
{define atom?
  [|x|
   {or (number? x)
       (symbol? x)}]}
;;; \end{code}
;;;
;;; \footnote{Within libbug, a parameter named ``x'' usually means the parameter can
;;;   be of any type.}
;;;
;;;
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  atom?
  '(
    (1 #t)
    (1/3 #t)
    (a #t)
    ((make-vector 3) #f)
    (() #f)
    ((a) #f)
    ))
 }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{complement}
;;;
;;; \index{complement}
;;; \begin{code}
{define complement
  [|f|
   [|#!rest args|
    (not (apply f args))]]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 63]{onlisp}
;;;
;;;
;;; \begin{code}
{unit-test
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
;;; \section{copy}
;;;   Creates a shallow copy of the list.
;;;
;;; \index{copy}
;;; \begin{code}
{define copy
  [|l|
   (map identity l)]}
;;; \end{code}
;;;
;;; \footnote{Within libbug, a parameter named ``l'' usually means the parameter is
;;;   is a list.}
;;;
;;;
;;; \begin{code}
{unit-test
 {let ((a '(1 2 3 4 5)))
   {and (equal? a (copy a))
        (not (eq? a (copy a)))}}
 }
;;; \end{code}
;;;
;;; For a thorough description of ``equal?'' vs ``eq?'', see \cite[p. 122-129]{schemeprogramminglanguage}.
;;;
;;; \newpage
;;; \section{proper?}
;;;   Tests that the last element of the list is the sentinel value ``'()''.
;;;   Will not terminate on a circular list.
;;;
;;; \index{proper?}
;;; \begin{code}
{define proper?
  [|l|
   (if (null? l)
       [#t]
       [(if (pair? l)
            [(proper? (cdr l))]
            [#f])])]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  proper?
  '(
    (() #t)
    ((4) #t)
    ((1 2) #t)
    (4 #f)
    ((1 2 . 5) #f)
    ))}
;;; \end{code}
;;;
;;;
;;;
;;;
;;; \newpage
;;; \section{first}
;;;
;;;
;;; \index{first}
;;; \begin{code}
{define first
  [|l #!key (onNull noop)|
   (if (null? l)
       [(onNull)]
       [(car l)])]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 59]{ss}
;;;
;;;
;;; \begin{code}
{unit-test
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
;;; \section{but-first}
;;; \index{but-first}
;;; \begin{code}
{define but-first
  [|l #!key (onNull noop)|
   (if (null? l)
       [(onNull)]
       [(cdr l)])]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 59]{ss}
;;;
;;;
;;; \begin{code}
{unit-test
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
;;; \section{last}
;;; \index{last}
;;; \begin{code}
{define last
  [|l #!key (onNull noop)|
   (if (null? l)
       [(onNull)]
       [{let last ((l l))
          (if (null? (cdr l))
              [(car l)]
              [(last (cdr l))])}])]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 59]{ss}
;;;
;;;
;;; \begin{code}
{unit-test
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
;;; \section{but-last}
;;; \index{but-last}
;;; \begin{code}
{define but-last
  [|l #!key (onNull noop)|
   (if (null? l)
       [(onNull)]
       [{let but-last ((l l))
          (if (null? (cdr l))
              ['()]
              [(cons (car l)
                     (but-last (cdr l)))])}])]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 59]{ss}
;;;
;;;
;;; \begin{code}
{unit-test
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
;;; \section{filter}
;;; \index{filter}
;;; \begin{code}
{define filter
  [|p? l|
   {let filter ((l l))
     (if (null? l)
         ['()]
         [{let ((first (car l)))
            (if (p? first)
                [(cons first (filter (cdr l)))]
                [(filter (cdr l))])}])}]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 331]{ss}\footnote{Simply Scheme has an excellent discussion on section
;;; on Higher-Order Functions and their combinations \cite[p. 103-125]{ss}}. \cite[p. 115]{sicp}.
;;;
;;; \begin{code}
{unit-test
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
;;; \section{remove}
;;; \index{remove}
;;; \begin{code}
{define remove
  [|x l|
   (filter [|y| (not (equal? x y))]
           l)]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|l| (remove 5 l)]
  '(
    ((1 5 2 5 3 5 4 5 5) (1 2 3 4))
    ))}
;;; \end{code}
;;;
;;; \newpage
;;; \section{fold-left}
;;;    Reduce the list to a scalar by applying the reducing procedure repeatedly,
;;;    starting from the ``left'' side of the list
;;;
;;; \index{fold-left}
;;; \begin{code}
{define fold-left
  [|f acc l|
   {let fold-left ((acc acc) (l l))
     (if (null? l)
         [acc]
         [(fold-left (f acc
                        (car l))
                     (cdr l))])}]}
;;; \end{code}
;;;
;;;
;;; \footnote{Within libbug, a parameter named ``acc'' usually means the parameter is
;;;   is an accumulated value}
;;;
;;; \noindent \cite[p. 121]{sicp}
;;;
;;; \begin{code}
{unit-test
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
;;; \section{fold-right}
;;;    Reduces the list to a scalar by applying the reducing
;;;    procedure repeatedly,
;;;    starting from the ``right'' side of the list
;;;
;;; \index{fold-right}
;;; \begin{code}
{define fold-right
  [|f acc l|
   {let fold-right ((l l))
     (if (null? l)
         [acc]
         [(f (car l)
             (fold-right (cdr l)))])}]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 116 (named ``accumulate'')]{sicp}
;;;
;;; \begin{code}
{unit-test
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
;;; \section{scan-left}
;;;   Like fold-left, but every intermediate value
;;;   of fold-left's accumulator is put onto the resulting list
;;;
;;; \index{scan-left}
;;; \begin{code}
{define scan-left
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
                           {set-cdr! last-cell (list newacc)}
                           (cdr last-cell)}
                         (cdr l))}])}}]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|l| (scan-left * 1 l)]
  '(
    (() (1))
    ((2) (1 2))
    ((2 3) (1 2 6))
    ((2 3 4) (1 2 6 24))
    ((2 3 4 5 ) (1 2 6 24 120))
    ))
 }
;;; \end{code}
;;;
;;; \newpage
;;; \section{append!}
;;;   Like Scheme's ``append'', but recycles the last cons cell, so it's
;;;   faster but it mutates the input.
;;;
;;; \index{append"!}
;;; \begin{code}
{define append!
  [|#!rest ls|
   {##define append!
     [|l1 l2|
      (if (null? l1)
          [l2]
          [{let ((head l1))
             {let append! ((l1 l1))
               (if (null? (cdr l1))
                   [{set-cdr! l1 l2}]
                   [(append! (cdr l1))])}
             head}])]}
   (fold-right append! '() ls)]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (equal? (append! '()
                  '(5))
         '(5))
 (equal? (append! '(1 2 3)
                  '(5))
         '(1 2 3 5))
 {let ((a '(1 2 3)))
   (append! a '(5))
   (not (equal? '(1 2 3) a))}
 {let ((a '(1 2 3))
       (b '(4 5 6)))
   (append! a b '(7))
   (equal? a '(1 2 3 4 5 6 7))}
 }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{flatmap}
;;; \index{flatmap}
;;; \begin{code}
{define flatmap
  [|f l|
   (fold-left append! '() (map f l))]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 123]{sicp}
;;;
;;;
;;; \begin{code}
{unit-test
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
;;; \section{take}
;;; \index{take}
;;; \begin{code}
{define take
  [|n l|
   (if {or (null? l)
           (= n 0)}
       ['()]
       [(cons (car l)
              (take (- n 1)
                    (cdr l)))])]}
;;; \end{code}
;;;
;;;
;;; \begin{code}
{unit-test
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
;;; \section{take-while}
;;; \index{take-while}
;;; \begin{code}
{define take-while
  [|p? l|
   {let take-while ((l l))
     (if {or (null? l)
             ((complement p?) (car l))}
         ['()]
         [(cons (car l)
                (take-while (cdr l)))])}]}
;;; \end{code}
;;;
;;;
;;; \begin{code}
{unit-test
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
;;; \section{drop}
;;; \index{drop}
;;; \begin{code}
{define drop
  [|n l|
   (if {or (null? l)
           (= n 0)}
       [l]
       [(drop (- n 1)
              (cdr l))])]}
;;; \end{code}
;;;
;;;
;;; \begin{code}
{unit-test
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
;;; \section{drop-while}
;;; \index{drop-while}
;;; \begin{code}
{define drop-while
  [|p? l|
   {let drop-while ((l l))
     (if {or (null? l)
             ((complement p?) (car l))}
         [l]
         [(drop-while (cdr l))])}]}
;;; \end{code}
;;;
;;;
;;; \begin{code}
{unit-test
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
;;; \section{enumerate-interval}
;;; \index{enumerate-interval}
;;; \begin{code}
{define enumerate-interval
  [|low high #!key (step 1)|
   (if (> low high)
       ['()]
       [(cons low
              (enumerate-interval (+ low step)
                                  high
                                  step: step))])]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (equal? (enumerate-interval 1 10)
         '(1 2 3 4 5 6 7 8 9 10))
 (equal? (enumerate-interval 1 10 step: 2)
         '(1 3 5 7 9))}
;;; \end{code}
;;;
;;; \newpage
;;; \section{any?}
;;;
;;; \index{any?}
;;; \begin{code}
{define any?
  [|l|
   (if (null? l)
       [#f]
       [(if (car l)
            [#t]
            [(any? (cdr l))])])]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
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
;;; \section{zip}
;;; \index{zip}
;;; \begin{code}
{define zip
  [|#!rest lsts|
   (if (any? (map null? lsts))
       ['()]
       [(cons (apply list (map car lsts))
              (apply zip (map cdr lsts)))])]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
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
;;;
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
;;;
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
;;; \section{permutations}
;;; \index{permutations}
;;; \begin{code}
{define permutations
  [|l|
   (if (null? l)
       ['()]
       [{let permutations ((l l))
          (if (null? (cdr l))
              [(list l)]
              [(flatmap [|x| (map [|y| (cons x y)]
                                  (permutations (remove x l)))]
                        l)])}])]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
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
;;; \section{ref-of}
;;; The inverse of list-ref.
;;;
;;; \index{ref-of}
;;; \begin{code}
{define ref-of
  [|l x #!key (onMissing noop)|
   (if (null? l)
       [(onMissing)]
       [{let ref-of ((l l)
                     (index 0))
          (if (equal? (car l) x)
              [index]
              [(if (null? (cdr l))
                   [(onMissing)]
                   [(ref-of (cdr l) (+ index 1))])])}])]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|x| (ref-of '(a b c d e f g) x)]
  '(
    (z noop)
    (a 0)
    (b 1)
    (g 6)
    ))
;;; \end{code}
;;;
;;; \begin{code}
 (satisfies?
  [|x| (ref-of '(a b c d e f g)
               x
               onMissing: ['missing])]
  '(
    (z missing)
    (a 0)
    ))
;;; \end{code}
;;;
;;; \begin{code}
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
;;; \section{partition}
;;;  Partitions the input list into two lists, with the criterion being whether or not
;;;  the application of the  procedure ``p?'' to each element of the input list evaluated
;;;  to true or false.
;;;
;;;
;;; \index{partition}
;;; \begin{code}
{define partition
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
                          (cons (car l) falseList))])])}]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
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
;;; In section~\ref{sec:dbind}, ``destructuring-bind'' allows for a more convenient syntax when
;;; using ``partition''.
;;;
;;; \begin{examplecode}
;;;> (destructuring-bind (trueList falseList)
;;;                      (partition '(3 2 5 4 1)
;;;                                 [|x| (<= x 3)])
;;;                      trueList)
;;;(1 2 3)
;;;> (destructuring-bind (trueList falseList)
;;;                      (partition '(3 2 5 4 1)
;;;                                 [|x| (<= x 3)])
;;;                      falseList)
;;;(4 5)
;;; \end{examplecode}
;;;
;;; \newpage
;;; \section{sort}
;;; \index{sort}
;;; \begin{code}
{define sort
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
                           (sort greater-than)))}])}]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
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
;;; \section{reverse!}
;;;   Reverses the list quickly by reusing cons cells
;;;
;;; \index{reverse"!}
;;; \begin{code}
{define reverse!
  [|l|
   (if (null? l)
       ['()]
       [{let reverse! ((cons-cell l) (reversed-list '()))
          (if (null? (cdr cons-cell))
              [{set-cdr! cons-cell reversed-list}
               cons-cell]
              [{let ((rest (cdr cons-cell)))
                 {set-cdr! cons-cell reversed-list}
                 (reverse! rest cons-cell)}])}])]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
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
;;; \chapter{Lifting}
;;; \section{string-lift-list}
;;;
;;; Strings are sequences of characters, just as lists are
;;; sequences of arbitrary Scheme objects. ``string-lift-list''
;;; allows the creation of a context in which the strings may
;;; be treated as lists.
;;;
;;;
;;; \index{string-lift-list}
;;; \begin{code}
{define string-lift-list
  [|f|
   [|#!rest s|
    (list->string
     (apply f
            (map string->list s)))]]}
;;;
;;; \end{code}
;;; \newpage


;;; \section{string-reverse}
;;;
;;; \index{string-reverse}
;;; \begin{code}
{define string-reverse
  (string-lift-list reverse!)}
;;;
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
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

;;; \section{string-take}
;;;
;;; \index{string-take}
;;; \begin{code}
{define string-take
  [|n s|
   ((string-lift-list [|l| (take n l)])
    s)]}
;;;
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|s| (string-take 2 s)]
  '(
    ("" "")
    ("foo" "fo")
    ))
 }
;;; \end{code}
;;; \newpage
;;; \section{string-drop}
;;;
;;; \index{string-drop}
;;; \begin{code}
{define string-drop
  [|n s|
   ((string-lift-list [|l| (drop n l)])
    s)]}
;;;
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|s| (string-drop 2 s)]
  '(
    ("" "")
    ("foo" "o")
    ("foobar" "obar")
    ))
 }
;;; \end{code}
;;; \newpage
;;;
;;; \section{character-lift-integer}
;;;
;;; Characters have a numeric value, but are not treated
;;; as numbers.
;;; ``character-lift-integer''
;;; allows the creation of a context in which the characters may
;;; be treated as integers.
;;;
;;; \index{character-lift-integer}
;;; \begin{code}
{define character-lift-integer
  [|f|
   [|#!rest n|
    (integer->char
     (apply f
            (map char->integer n)))]]}
;;;
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  (character-lift-integer [|c| (+ c 1)])
  '(
    (#\a #\b)
    (#\b #\c)
    (#\c #\d)
    ))}
;;; \end{code}
;;; \newpage

;;; \section{string-map}
;;;
;;; \index{string-map}
;;; \begin{code}
{define string-map
  [|f s|
   ((string-lift-list [|l| (map f l)])
    s)]}
;;;
;;; \end{code}
;;;
;;;
;;; The ``Caesar Cipher''. \cite[p. 30]{crypto}.
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|s| (string-map
        [|c|
         ((character-lift-integer [|base-char c|
                                   (+ base-char
                                      (modulo (+ (- c base-char)
                                                 3)
                                              26))])
          #\a
          c)]
        s)]

  '(
    ("" "")
    ("abc" "def")
    ("nop" "qrs")
    ("xyz" "abc")
    ))
 }
;;; \end{code}
;;; \newpage

;;; \section{symbol-lift-list}
;;;
;;; Symbols are sequences of characters, just as lists are
;;; sequences of arbitrary Scheme objects. ``symbol-lift-list''
;;; allows the creation of a context in which the symbols may
;;; be treated as lists.
;;;
;;;
;;; \index{symbol-lift-list}
;;; \begin{code}
{define symbol-lift-list
  [|f|
   [|#!rest s|
    (string->symbol
     (apply (string-lift-list f)
            (map symbol->string s)))]]}
;;;
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  (symbol-lift-list reverse)
  '(
    (foo oof)
    (bar rab)
    ))
 (equal? ((symbol-lift-list append!) 'foo 'bar)
         'foobar)
 }
;;; \end{code}

;;; \newpage
;;; \chapter{Streams}
;;;
;;; Streams are sequential collections like lists, but the
;;; ``cdr'' of each pair must be a zero-argument lambda value.  That lambda
;;; is automatically evaluated when ``(stream-cdr s)'' is evaluated.
;;; For more information, consult ``The Structure and
;;; Interpretation of Computer Programs''\footnote{although, they
;;; define ``stream-cons'' as syntax instead of passing a lambda
;;; to the second argument}.
;;;
;;; \section{Stream structure}
;;;
;;; ``bug\#define-structure''\footnote{defined in section~\ref{sec:definestructure}}
;;;  takes as parameters the name of the datatype, and a variable
;;; number of fields.
;;;
;;; \begin{code}
{define-structure stream
  a
  d}
;;; \end{code}
;;;
;;; ``bug\#define-structure'' will create a constructor procedure named ``make-stream'',
;;;  accessor procedures ``stream-a'', ``stream-d'', and updating procedures ``stream-a-set!'' and
;;; ``stream-d-set!''.
;;;  For streams, none of these generated procedures are intended to be
;;; evaluated directly by the programmer. Instead, the following
;;; are to be used.
;;;
;;; \section{stream-car}
;;; Get the first element of the stream.
;;;
;;; \index{stream-car}
;;; \begin{code}
{define stream-car
  stream-a}
;;; \end{code}
;;;
;;; \noindent \cite[p. 321]{sicp}.
;;;
;;; \section{stream-cdr}
;;; Forces the evaluation of the next element of the stream.
;;;
;;; \index{stream-cdr}
;;; \begin{code}
{define stream-cdr
  [|s|
   {force (stream-d s)}]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 321]{sicp}.
;;; \newpage
;;; \section{stream-cons}
;;;
;;; Like ``cons'', creates a pair.  The second argument must be a zero-argument
;;; lambda value.
;;;
;;;
;;; \index{stream-cons}
;;; \begin{code}
{define-macro stream-cons
  [|a d|
   (if {and (list? d)
            (equal? 'lambda (car d))
            (not (null? (cdr d)))
            (equal? '() (cadr d))}
       [`(make-stream ,a {delay ,(caddr d)})]
       [(error "bug#stream-cons requires a zero-argument \
                lambda in it's second arg")])]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 321]{sicp}.
;;;
;;; \begin{code}
{unit-test
 {let ((s (stream-cons 1 [2])))
   {and
    (equal? (stream-car s)
            1)
    (equal? (stream-cdr s)
            2)}}
 }
;;; \end{code}
;;;
;;;
;;; \newpage
;;;
;;; \section{stream-null}
;;;
;;; \index{stream-null}
;;; \begin{code}
{define stream-null
  '()
  }
;;; \end{code}
;;;
;;; \section{stream-null?}
;;;
;;; \index{stream-null?}
;;; \begin{code}
{define stream-null?
  null?}
;;; \end{code}
;;;
;;;
;;; \begin{code}
{unit-test
 (stream-null?
  (stream-cdr
   (stream-cdr (stream-cons 1 [(stream-cons 2
                                            [stream-null])]))))
 }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{list-\textgreater stream}
;;; Converts a list into a stream
;;;
;;; \index{list-\textgreater stream}
;;; \begin{code}
{define list->stream
  [|l|
   (if (null? l)
       [stream-null]
       [(stream-cons (car l)
                     [(list->stream
                       (cdr l))])])]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
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
;;; \section{stream-\textgreater list}
;;; Converts a stream into a list
;;;
;;; \index{stream-\textgreater list}
;;; \begin{code}
{define stream->list
  [|s|
   (if (stream-null? s)
       ['()]
       [(cons (stream-car s)
              (stream->list
               (stream-cdr s)))])]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (equal? (stream->list
          (list->stream '(1 2 3)))
         '(1 2 3))
 }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{stream-ref}
;;; The analogous procedure of ``list-ref''
;;;
;;; \index{stream-ref}
;;; \begin{code}
{define stream-ref
  [|s n #!key (onOutOfBounds noop)|
   (if (< n 0)
       [(onOutOfBounds)]
       [{let stream-ref ((s s) (n n))
          (if (equal? n 0)
              [(stream-car s)]
              [(if (not (stream-null? (stream-cdr s)))
                   [(stream-ref (stream-cdr s) (- n 1))]
                   [(onOutOfBounds)])])}])]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 319]{sicp}.
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|i| (stream-ref (list->stream '(a b c d e)) i)]
  '(
    (-1 noop)
    (0 a)
    (4 e)
    (5 noop)
    )
  )
 (equal? (stream-ref (list->stream '(a b c d e))
                     5
                     onOutOfBounds: ['out])
         'out)}
;;; \end{code}
;;;
;;;
;;; \newpage

;;; \section{integers-from}
;;; \index{integers-from}
;;;
;;; Creates an ``infinite'' list of integers.
;;;
;;; \begin{code}
{define integers-from
  [|n|
   (stream-cons n [(integers-from (+ n 1))])]}
;;; \end{code}
;;;
;;; \cite[p. 326]{sicp}.
;;;
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|n| (stream-ref (integers-from 0) n)]
  '(
    (0 0)
    (1 1)
    (2 2)
    ))
 (satisfies?
  [|n| (stream-ref (integers-from 5) n)]
  '(
    (0 5)
    (1 6)
    (2 7)
    ))
 }
;;; \end{code}
;;;
;;; \newpage
;;; \section{stream-take}
;;; \index{stream-take}
;;; \begin{code}
{define stream-take
  [|n s|
   (if {or (stream-null? s)
           (= n 0)}
       [stream-null]
       [(stream-cons (stream-car s)
                     [(stream-take (- n 1)
                                   (stream-cdr s))])])]}
;;; \end{code}
;;;
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|n| (stream->list
        (stream-take n (integers-from 0)))]
  '(
    (0 ())
    (1 (0))
    (2 (0 1))
    (6 (0 1 2 3 4 5))
    ))}
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{stream-filter}
;;; The analogous procedure of filter.
;;;
;;; \index{stream-filter}
;;; \begin{code}
{define stream-filter
  [|p? s|
   {let stream-filter ((s s))
     (if (stream-null? s)
         [stream-null]
         [{let ((first (stream-car s)))
            (if (p? first)
                [(stream-cons
                  first
                  [(stream-filter (stream-cdr s))])]
                [(stream-filter (stream-cdr s))])}])}]}
;;; \end{code}
;;;
;;;
;;; \begin{code}
{unit-test
 (equal?  (stream->list
           (stream-filter [|x| (not (= 4 x))]
                          (list->stream '(1 4 2 4))))
          '(1 2))
 (equal? (stream->list
          (stream-take
           10
           (stream-filter [|n|
                           (not (equal? 0
                                        (modulo n 2)))]
                          (integers-from 2))))
         '(3 5 7 9 11 13 15 17 19 21))
 }
;;;
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{primes}
;;; \index{primes}
;;; \begin{code}
{define primes
  {let sieve-of-eratosthenes ((s (integers-from 2)))
    (stream-cons
     (stream-car s)
     [(sieve-of-eratosthenes (stream-filter
                              [|n|
                               (not (equal? 0
                                            (modulo n (stream-car s))))]
                              (stream-cdr s)))])}}
;;; \end{code}
;;;
;;; \cite[p. 327]{sicp}.
;;;
;;;
;;; \begin{code}
{unit-test
 (equal? (stream->list
          (stream-take
           10
           primes))
         '(2 3 5 7 11 13 17 19 23 29))
 }
;;; \end{code}
;;;
;;; \newpage

;;; \section{stream-map}
;;; The analogous procedure of ``map''.
;;;
;;; \index{stream-map}
;;; \begin{code}
{define stream-map
  [|f #!rest list-of-streams|
   {let stream-map ((list-of-streams list-of-streams))
     (if (any? (map stream-null? list-of-streams))
         [stream-null]
         [(stream-cons (apply f
                              (map stream-car list-of-streams))
                       [(stream-map (map stream-cdr list-of-streams))])])}]}
;;; \end{code}
;;;
;;;
;;; \begin{code}
{unit-test
 (equal? (stream->list
          (stream-map [|x| (+ x 1)]
                      (list->stream '(1 2 3 4 5))))
         '(2 3 4 5 6))
 (equal? (stream->list
          (stream-map [|x y| (+ x y)]
                      (list->stream '(1 2 3 4 5))
                      (list->stream '(1 1 1 1 1))))
         '(2 3 4 5 6))
 }
;;;
;;; \end{code}
;;;
;;; \newpage
;;; \section{stream-enumerate-interval}
;;; \index{stream-enumerate-interval}
;;; \begin{code}
{define stream-enumerate-interval
  [|low high #!key (step 1)|
   (if (> low high)
       [stream-null]
       [(stream-cons low
                     [(stream-enumerate-interval (+ low step)
                                                 high
                                                 step: step)])])]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (equal? (stream->list
          (stream-enumerate-interval 1 10))
         '(1 2 3 4 5 6 7 8 9 10))
 (equal? (stream->list
          (stream-enumerate-interval 1 10 step: 2))
         '(1 3 5 7 9))}
;;; \end{code}
;;;
;;; \newpage
;;; \section{stream-take-while}
;;; \index{stream-take-while}
;;; \begin{code}
{define stream-take-while
  [|p? s|
   {let stream-take-while ((s s))
     (if {or (stream-null? s)
             ((complement p?) (stream-car s))}
         [stream-null]
         [(stream-cons (stream-car s)
                       [(stream-take-while
                         (stream-cdr s))])])}]}
;;; \end{code}
;;;
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|s|
   (stream->list
    (stream-take-while [|n| (< n 10)]
                       s))]
  `((,(integers-from 0)               (0 1 2 3 4 5 6 7 8 9))
    (,(stream-enumerate-interval 1 4) (1 2 3 4))))
 }
;;; \end{code}
;;;
;;; \newpage

;;; \section{stream-drop}
;;; \index{stream-drop}
;;; \begin{code}
{define stream-drop
  [|n s|
   (if {or (stream-null? s)
           (= n 0)}
       [s]
       [(stream-drop (- n 1)
                     (stream-cdr s))])]}
;;; \end{code}
;;;
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|n|
   (stream->list
    (stream-drop n (list->stream '(a b))))]
  '(
    (0 (a b))
    (1 (b))
    (2 ())
    (3 ())
    ))
 (equal? (stream->list
          (stream-take 10 (stream-drop 10
                                       primes)))
         '(31 37 41 43 47 53 59 61 67 71))
 }
;;; \end{code}
;;;
;;;
;;; \newpage

;;; \section{stream-drop-while}
;;; \index{stream-drop-while}
;;; \begin{code}
{define stream-drop-while
  [|p? s|
   {let stream-drop-while ((s s))
     (if {or (stream-null? s)
             ((complement p?) (stream-car s))}
         [s]
         [(stream-drop-while (stream-cdr s))])}]}
;;; \end{code}
;;;
;;;
;;; \begin{code}
{unit-test
 (satisfies?
  [|x|
   (stream->list
    (stream-drop-while [|y| (not (equal? x y))]
                       (list->stream
                        '(a b c))))]
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

;;;
;;; \chapter{Macros}
;;;  \label{sec:macros}
;;;
;;;  Although many concepts first implemented in Lisp (conditional expressions,
;;;  garbage collection, procedures as first-class objects)
;;;  have been appropriated into mainstream languages, the one feature of Lisp which
;;;  remains difficult to copy is also one of Lisp's strongest:  macros.  Macros are a facility
;;;  by which a programmer may augment the compiler with new functionality \emph{while
;;;  the compiler is compiling.}
;;;
;;;  Mastery of macros is required to understand all subsequent chapters of this book.
;;;  Should the reader have difficulty with this chapter, the author recommends reading
;;;  ``On Lisp'' by Paul Graham \cite{onlisp}.

;;;
;;; \newpage
;;; \section{compose}
;;;
;;; \index{compose}
;;; \begin{code}
{define-macro compose
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
                      ,(compose (cdr fs)))])}]}])]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 66]{onlisp}
;;;
;;;
;;; \begin{itemize}
;;;   \item On line 1, the libbug-private\#define-macro macro\footnote{defined in
;;;     section ~\ref{sec:libbugdefinemacro}}
;;;     is invoked.  Besides defining the macro, libbug-private\#define-macro
;;;     also exports the
;;;     namespace definition and the macro definitions to external files.
;;;     Libbug is a library, meant to be used by other projects.  From libbug, these
;;;     projects will require namespace definitions, as well as macro definitions.
;;;
;;;
;;; \end{itemize}

;;;
;;;
;;; \begin{code}
{unit-test
 (equal? {macroexpand-1 (compose)}
         'identity)
 (equal? ((eval {macroexpand-1 (compose)}) 5)
         5)
 (equal? ((compose) 5)
         5)
;;; \end{code}
;;;
;;;
;;; Macro-expansions occur during compile-time, so how should a person
;;; test them?  Libbug provides ``macroexpand-1'' which treats the macro
;;; as a procedure which transforms lists into lists, and as such is able
;;; to be tested\footnote{
;;; ``macroexpand-1'' expands the unevaluated code passed to the
;;; macro into the new form, which the compiler would have then compiled
;;; if ``macroexpand-1'' had not been present.  But, how should ``gensyms''
;;; evaluate, since by definition it creates symbols which cannot be entered
;;; into a program?  During the expansion of ``macroexpand-1'', ``gensym''
;;; is overridden into a procedure
;;; which expands into symbols like ``gensymed-var1'', ``gensymed-var2'', etc.  Each
;;; call during a macro-expansion generates a new, unique symbol.  Although this symbol
;;; may clash with symbols in the expanded code, this is not a problem, as these
;;; symbols are only generated in the call to ``macroexpand-1''; run-time ``gensym'' is
;;; regular old ``gensym''.  As such,
;;; ``eval''ing code generated from ``macroexpand-1'' in a non-testing context is not
;;; recommended.
;;; }.
;;;
;;;
;;;
;;;
;;; \begin{code}
 (equal? {macroexpand-1 (compose [|x| (* x 2)])}
         '[|#!rest gensymed-var1|
           (apply [|x| (* x 2)]
                  gensymed-var1)])
 (equal? ((eval {macroexpand-1 (compose [|x| (* x 2)])})
          5)
         10)
 (equal? ((compose [|x| (* x 2)])
          5)
         10)
;;; \end{code}
;;;
;;; \begin{code}
 (equal? {macroexpand-1 (compose [|x| (+ x 1)]
                                 [|x| (* x 2)])}
         '[|#!rest gensymed-var1|
           ([|x| (+ x 1)]
            (apply [|x| (* x 2)]
                   gensymed-var1))])
 (equal? ((eval {macroexpand-1 (compose [|x| (+ x 1)]
                                        [|x| (* x 2)])})
          5)
         11)
 (equal? ((compose [|x| (+ x 1)]
                   [|x| (* x 2)])
          5)
         11)
;;; \end{code}
;;;
;;; \begin{code}
 (equal? {macroexpand-1 (compose [|x| (/ x 13)]
                                 [|x| (+ x 1)]
                                 [|x| (* x 2)])}
         '[|#!rest gensymed-var1|
           ([|x| (/ x 13)]
            ([|x| (+ x 1)]
             (apply [|x| (* x 2)]
                    gensymed-var1)))])
 (equal? ((eval {macroexpand-1 (compose [|x| (/ x 13)]
                                        [|x| (+ x 1)]
                                        [|x| (* x 2)])})
          5)
         11/13)
 (equal? ((compose [|x| (/ x 13)]
                   [|x| (+ x 1)]
                   [|x| (* x 2)])
          5)
         11/13)
 }
;;; \end{code}
;;;
;;; \newpage
;;; \section{aif}
;;;
;;; \index{aif}
;;; \begin{code}
{define-macro aif
  [|bool body|
   `{let ((bug#it ,bool))
      (if bug#it
          [,body]
          [#f])}]}
;;; \end{code}
;;;
;;; Although variable capture \cite[p. 118-132]{onlisp} is generally avoided,
;;; there are instances in which variable capture is desirable \cite[p. 189-198]{onlisp}.
;;; Within libbug, varibles intended for capture are fully qualified with a namespace
;;; to ensure that the variable is captured.
;;;
;;; \noindent \cite[p. 191]{onlisp}
;;;
;;; \begin{code}
{unit-test
 (equal? {aif (+ 5 10) (* 2 bug#it)}
         30)
 (equal? {aif #f (* 2 bug#it)}
         #f)
 (equal? {macroexpand-1 {aif (+ 5 10)
                             (* 2 bug#it)}}
         '{let ((bug#it (+ 5 10)))
            (if bug#it
                [(* 2 bug#it)]
                [#f])})
 }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{with-gensyms}
;;;   ``with-gensyms'' is a macro to be invoked from other macros.  It is a utility for
;;;    macros to minimize repetitive calls to ``gensym''.
;;;
;;; \index{with-gensyms}
;;; \begin{code}
{define-macro with-gensyms
  [|symbols #!rest body|
   `{let ,(map [|symbol| `(,symbol {gensym})]
               symbols)
      ,@body}]}
;;; \end{code}
;;;
;;; \noindent \cite[p. 145]{onlisp}
;;;
;;; \begin{code}
{unit-test
 (equal? {macroexpand-1 (with-gensyms (foo bar baz)
                                      `{begin
                                         (pp ,foo)
                                         (pp ,bar)
                                         (pp ,baz)})}
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
;;; \newpage
;;; \section{once-only}
;;; \index{once-only}
;;;
;;; Sometimes macros need to put two copies of its arguments in the generated code.
;;; But that will mean that the argument will be evaluated multiple times,
;;; which is seldomly desirable.
;;;
;;;
;;; \begin{examplecode}
;;;> {define-macro double [|x| `(+ ,x ,x)]}
;;;> {double 5}
;;;10
;;; \end{examplecode}
;;;
;;; A person using a macro such as ``double'' should expect the argument to ``double''
;;; to only be evaluated once.
;;;
;;; \begin{examplecode}
;;;> {define foo 5}
;;;> {double {mutate! foo [|x| (+ x 1)]}}
;;;13
;;; \end{examplecode}
;;;
;;; ``once-only'' allows a macro-writer to ensure that a variable is evaluated
;;; only once in the generated code.
;;;
;;; \begin{examplecode}
;;;> {define-macro double [|x| {once-only (x) `(+ ,x ,x)}]}
;;;> {define foo 5}
;;;> {double {mutate! foo [|x| (+ x 1)]}}
;;;12
;;; \end{examplecode}
;;;
;;;
;;;
;;; \begin{code}
{define-macro once-only
  [|symbols #!rest body|
   ;; one gensym per symbol
   {let ((gensyms (map [|s| (gensym)]
                       symbols)))
     ;; after the second macro expansion, the resulting code to be compiled
     ;; will be a ``let'' expression.
     ;;
     ;; The ``let'''s variable bindings will be the subset of symbols whose values
     ;; are not atoms in the second macroexpansion, as multiple evaluation of
     ;; atoms causes no problems with respect to multiple evaluation.
     ;;
     ;; The ``let'''s body will be the body passed to ``once-only'', but
     ;; with gensymed variables substituted for all non-atom arguments
     ;; to the calling macro.
     `(list 'let
            ;; In the second expansion, append a list of variable mappings
            ;; together
            ,`(append ,@(map [|g s| `(if (atom? ,s)
                                         ;; in the second expansion,
                                         ;; if the value is an atom, no gensymed
                                         ;; variable substition is required
                                         ['()]
                                         ;; if it's not create a binding to a
                                         ;; gensymed variable
                                         [(list ,`(list
                                                   ,`(quote ,g)
                                                   ,s))])]
                             gensyms
                             symbols))
            ;; in the second expansion, substitute symbols in body either with
            ;; a gensym or with the symbol itself
            ,(append (list 'let
                           (map [|s g| (list s
                                             `(if (atom? ,s)
                                                  ;; itself
                                                  [,(list 'quote s)]
                                                  ;; the associated gensym
                                                  [,(list 'quote g)]))]
                                symbols
                                gensyms))
                     body))}]}
;;; \end{code}
;;;
;;; \cite[p. 854]{paip}
;;;
;;; Like ``with-gensyms'', ``once-only'' is a macro to be used by other macros.  But
;;; while ``with-gensyms'' only wraps it's argument with a new context to be used for
;;; later macroexpansions, ``once-only'' needs to defer binding the variable to a
;;; ``gensym-ed'' variable until the second macroexpansion.
;;;
;;; \subsubsection*{First Macroexpansion}
;;; \begin{code}
 {unit-test
  (equal? {macroexpand-1 {once-only (x y) `(+ ,x ,y)}}
          `(list 'let
                 (append (if (atom? x)
                             ['()]
                             [(list (list 'gensymed-var1 x))])
                         (if (atom? y)
                             ['()]
                             [(list (list 'gensymed-var2 y))]))
                 {let ((x (if (atom? x)
                              ['x]
                              ['gensymed-var1]))
                       (y (if (atom? y)
                              ['y]
                              ['gensymed-var2))))
                   `(+ ,x ,y)}))
;;; \end{code}
;;;
;;;
;;; \subsubsection*{The Second Macroexpansion}
;;; \begin{code}
  (equal? (eval `{let ((x 5)
                       (y 6))
                   ,{macroexpand-1
                     {once-only (x y)
                                `(+ ,x ,y)}}})
          `{let () (+ x y)})
  (equal? (eval `{let ((x '(car foo))
                       (y 6))
                   ,{macroexpand-1
                     {once-only (x y)
                                `(+ ,x ,y)}}})
          '{let ((gensymed-var1 (car foo)))
             (+ gensymed-var1 y)})
  (equal? (eval `{let ((x '(car foo))
                       (y '(baz)))
                   ,{macroexpand-1
                     {once-only (x y)
                                `(+ ,x ,y)}}})
          '{let ((gensymed-var1 (car foo))
                 (gensymed-var2 (baz)))
             (+ gensymed-var1 gensymed-var2)})
;;; \end{code}
;;;
;;; \subsubsection*{The Evaluation of the twice-expanded Code}
;;; \begin{code}
  (equal? (eval `{let ((x 5)
                       (y 6))
                   ,(eval `{let ((x 5)
                                 (y 6))
                             ,{macroexpand-1
                               {once-only (x y)
                                          `(+ ,x ,y)}}})})
          11)
  }
;;; \end{code}
;;;
;;; \newpage
;;; \chapter{Generalized Assignment}
;;;  \label{sec:endinglibbug}
;;; \section{setf!}
;;;  Lisp based systems such as Gambit do not provide raw access to memory
;;;  locations via pointers, thus relieving the user of the language
;;;  of direct memory management.  However, pointers are very useful in that
;;;  they allow a procedure to pass a memory location as a variable to another procedure,
;;;  which can then indirectly access/write to that location.
;;;
;;;  Fortunatly, most data-structures in Lisp have an ``accessing'' procedure
;;;  (for instance ``car'' or ``stream-a'') and an ``updating procedure''
;;;  (``set-car!'' and ``stream-a-set!'').  And there are only 3 patterns used
;;;  to map names of accessing procedures to updating procedures.
;;;
;;;
;;; ``Rather than thinking about two distinct functions that respectively
;;;  access and update a storage location somehow deduced from their arguments,
;;;  we can instead simply think of a call to the access function with given
;;;  arguments as a \emph{name} for the storage location.'' \cite[p. 123-124]{cl}
;;;
;;;  Therefore, create a macro named ``setf!'' which invokes the appropriate
;;;  ``setting'' procedure, based on the given ``accessing'' procedure\footnote{The
;;;  implementation is inspired by \cite{setf}.}.
;;;
;;; \index{setf"!}
;;; \begin{code}
{define-macro setf!
  [|exp val|
   (if (not (pair? exp))
       [`{set! ,exp ,val}]
       [{case (car exp)
          ((car)  `{set-car! ,@(cdr exp) ,val})
          ((cdr)  `{set-cdr! ,@(cdr exp) ,val})
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
          (else `(,((symbol-lift-list
                     [|l -set! -ref|
                      (append!
                       (if (equal? (reverse -ref)
                                   (take 4 (reverse l)))
                           [(reverse (drop 4
                                           (reverse l)))]
                           [l])
                       -set!)])
                    (car exp)
                    '-set!
                    '-ref)
                  ,@(cdr exp)
                  ,val))}])]}
;;; \end{code}
;;;
;;; \subsubsection*{Updating a Variable Directly}
;;;
;;; \begin{code}
{unit-test
 (equal? {macroexpand-1
          {setf! foo 10}}
         '{set! foo 10})
 {let ((a 5))
   {setf! a 10}
   (equal? a 10)}
;;; \end{code}
;;;
;;; \subsubsection*{Updating Car, Cdr, ... Through Cddddr}
;;; \noindent Test updating ``car''.
;;;
;;; \begin{code}
 (equal? {macroexpand-1
          {setf! (car foo) 10}}
         '{set-car! foo 10})
 {let ((foo '(1 2)))
   {setf! (car foo) 10}
   (equal? (car foo) 10)}
;;; \end{code}
;;;
;;; \noindent Test updating ``cdr''.
;;;
;;; \begin{code}
 (equal? {macroexpand-1
          {setf! (cdr foo) 10}}
         '{set-cdr! foo 10})
 {let ((foo '(1 2)))
   {setf! (cdr foo) 10}
   (equal? (cdr foo) 10)}
;;; \end{code}
;;;
;;; \noindent Testing all of the ``car'' through ``cddddr'' procedures will be highly
;;; repetitive.  Instead, create a list which has an element at each of those
;;; accessor procedures, and test each.
;;;
;;; \begin{code}
 (eval
  `{and
    ,@(map [|x| `{let ((foo '((((the-caaaar)
                                the-cadaar)
                               (the-caadar)
                               ())
                              ((the-caaadr) the-cadadr)
                              (the-caaddr)
                              ()
                              )))
                   {setf! (,x foo) 10}
                   (equal? (,x foo) 10)}]
           '(car
             cdr
             caar cadr
             cdar cddr
             caaar caadr cadar caddr
             cdaar cdadr cddar cdddr
             caaaar caaadr caadar caaddr
             cadaar cadadr caddar cadddr
             cdaaar cdaadr cdadar cdaddr
             cddaar cddadr cdddar cddddr
             ))})
;;; \end{code}
;;;
;;; \subsubsection*{Suffixed By -set!}
;;; \noindent Test updating procedures where the updating procedure is
;;; the name of the getting procedure, suffixed by '-set!'.
;;;
;;; \begin{code}
 (equal? {macroexpand-1
          {setf! (stream-a s) 10}}
         '{stream-a-set! s 10})
 {begin
   {let ((a (make-stream 1 2)))
     {setf! (stream-a a) 10}
     (equal? (make-stream 10 2)
             a)}}
;;; \end{code}
;;;
;;; \footnote{As a reminder, ``stream-a'', ``make-stream'', and ``stream-a-set!'' are not meant to be used
;;;    directly.  But for the purposes of testing ``setf!'', it sufficies to use them directly.}
;;;
;;; \subsubsection*{-ref Replaced By -set!}
;;; \noindent Test updating procedures where the updating procedure is
;;; the name of the getting procedure, removing the suffix of
;;; '-ref', and adding a suffix of '-set!'.
;;;
;;; \begin{code}
 (equal? {macroexpand-1
          {setf! (string-ref s 0) #\q}}
         '{string-set! s 0 #\q})
 {let ((s "foobar"))
   {setf! (string-ref s 0) #\q}
   (equal? s "qoobar")}
 (equal? {macroexpand-1
          {setf! (vector-ref v 2) 4}}
         '{vector-set! v 2 4})
 {let ((v (vector 1 2 '() "")))
   {setf! (vector-ref v 2) 4}
   (equal? v
           (vector 1 2 4 ""))}
 }
;;; \end{code}

;;; \newpage
;;; \section{mutate!}
;;;  Like ``setf!'', ``mutate!'' takes a generalized variable
;;;  as input, but it additionally takes a procedure.  The procedure is applied
;;;  to the value of that generalized variable, and is then
;;;  stored back into it.
;;;
;;; \index{mutate"!}
;;; \begin{code}
{define-macro mutate!
  [|exp f|
   (if (symbol? exp)
       [`{begin
           {setf! ,exp (,f ,exp)}
           ,exp}]
       [{let* ((let-args (map [|x| (if (atom? x)
                                       [x]
                                       [(list (gensym) x)])]
                              (cdr exp)))
               (symbol-list-to-setf (map [|x| (if (atom? x)
                                                  [x]
                                                  [(car x)])]
                                         let-args)))
          `{let ,(filter (complement atom?) let-args)
             {setf! (,(car exp) ,@symbol-list-to-setf)
                    (,f (,(car exp) ,@symbol-list-to-setf))}
             (,(car exp) ,@symbol-list-to-setf)}}])]}
;;; \end{code}
;;;

;;;
;;;
;;; \begin{code}
{unit-test
 (equal? {macroexpand-1 {mutate! foo not}}
         '{begin
            {setf! foo (not foo)}
            foo})
 {let ((foo #t))
   {and
    {begin
      {mutate! foo not}
      (equal? foo #f)}
    {begin
      {mutate! foo not}
      (equal? foo #t)}}}
;;; \end{code}
;;;
;;; \footnote{``mutate!'' is used in similar contexts as Common Lisp's
;;;   ``define-modify-macro'' would be, but it is more general, as
;;;   it allows the new procedure to remain anonymous, as compared
;;;   to making a new name like ``toggle'' \cite[p. 169]{onlisp}.}

;;;

;;; \begin{code}
 (equal? {macroexpand-1 (mutate! foo [|n| (+ n 1)])}
         '{begin
            {setf! foo ([|n| (+ n 1)] foo)}
            foo})
 {let ((foo 1))
   (mutate! foo [|n| (+ n 1)])
   (equal? foo
           2)}
;;; \end{code}
;;;
;;; \begin{code}
 (equal? {macroexpand-1 {mutate! (vector-ref foo 0) [|n| (+ n 1)]}}
         '{let ()
            (setf! (vector-ref foo 0)
                   ([|n| (+ n 1)] (vector-ref foo 0)))
            (vector-ref foo 0)})
 {let ((foo (vector 0 0 0)))
   {mutate! (vector-ref foo 0) [|n| (+ n 1)]}
   (equal? foo
           (vector 1 0 0))}
 {let ((foo (vector 0 0 0)))
   {mutate! (vector-ref foo 2) [|n| (+ n 1)]}
   (equal? foo
           (vector 0 0 1))}
;;; \end{code}
;;;
;;;
;;; \begin{code}
 (equal? {macroexpand-1
          {mutate! (vector-ref foo {begin
                                     {setf! index (+ 1 index)}
                                     index})
                   [|n| (+ n 1)]}}
         '{let ((gensymed-var1 (begin
                                 (setf! index (+ 1 index))
                                 index)))
            (setf! (vector-ref foo gensymed-var1)
                   ([|n| (+ n 1)] (vector-ref foo gensymed-var1)))
            (vector-ref foo gensymed-var1)})
 {let ((foo (vector 0 0 0))
       (index 1))
   {mutate! (vector-ref foo {begin
                              {setf! index (+ 1 index)}
                              index})
            [|n| (+ n 1)]}
   {and (equal? foo
                (vector 0 0 1))
        (equal? index
                2)}}
 }
;;; \end{code}
;;;
;;;
;;; \newpage
;;; \section{destructuring-bind}
;;;
;;;  \label{sec:dbind}
;;; \index{destructuring-bind}
;;;
;;; ``destructuring-bind'' is a generalization of ``let'', in which multiple variables
;;;  may be bound to values based on their positions within a list.  Look at the tests
;;;  at the end of the section for an example.
;;;
;;; ``destructuring-bind'' is a complicated macro which can be decomposed into a regular
;;;  procedure named ``tree-of-accessors'', and the macro ``destructuring-bind''\footnote{
;;;   This poses a small problem.  ``tree-of-accessors'' is not macroexpanded as it a not a
;;;  macro, therefore it does not have access to the compile-time ``gensym'' procedure
;;;  which allows macroexpansions to be tested.  To allow ``tree-of-accessors'' to
;;;  be tested independently, as well as part of ``destructuring-bind'', ``tree-of-accessors''
;;;  takes a procedure named ``gensym'' as an argument, defaulting to whatever value
;;;  ``gensym'' is by default in the environment.
;;;
;;;  }.
;;;
;;; \begin{code}
{define tree-of-accessors
  [|pat lst #!key (gensym gensym) (n 0)|
   {cond ((null? pat)                '())
         ((symbol? pat)              `((,pat (drop ,n ,lst))))
         ((equal? (car pat) '#!rest) `((,(cadr pat) (drop ,n
                                                          ,lst))))
         (else
          (cons {let ((p (car pat)))
                  (if (symbol? p)
                      [`(,p (list-ref ,lst ,n))]
                      [{let ((var (gensym)))
                         (cons `(,var (list-ref ,lst ,n))
                               (tree-of-accessors p
                                                  var
                                                  gensym: gensym
                                                  n: 0))}])}
                (tree-of-accessors (cdr pat)
                                   lst
                                   gensym: gensym
                                   n: (+ 1 n))))}]}
;;; \end{code}
;;;
;;; \begin{code}
{unit-test
 (equal? (tree-of-accessors '() '(1 2))
         '())
 (equal? (tree-of-accessors 'a '(1 2))
         '((a (drop 0 (1 2)))))
 (equal? (tree-of-accessors '(#!rest d) '(1 2))
         '((d (drop 0 (1 2)))))
 (equal? (tree-of-accessors '(a) '(1 2))
         '((a (list-ref (1 2) 0))))
 (equal? (tree-of-accessors '(a . b) '(1 2))
         '((a (list-ref (1 2) 0))
           (b (drop 1 (1 2)))))
;;; \end{code}
;;;
;;; \begin{code}
 (equal? (tree-of-accessors '(a (b c))
                            '(1 (2 3))
                            gensym: ['gensymed-var1])
         '((a (list-ref (1 (2 3)) 0))
           ((gensymed-var1 (list-ref (1 (2 3)) 1))
            (b (list-ref gensymed-var1 0))
            (c (list-ref gensymed-var1 1)))))
 }
;;; \end{code}
;;;
;;;
;;; Although ``tree-of-accessors'' appears to be victim of the multiple-evaluation
;;; problem that macros may have, ``tree-of-accessors'' is completely safe to use
;;; as long as the caller does not directly pass a list to ``tree-of-accessors''.
;;; The only caller of ``tree-of-accessors'' is ``destructuring-bind'', which passes
;;; a symbol to ``tree-of-accessors''.  Therefore ``destructuring-bind'' does not
;;; fall victim to unintended multiple evaluations.
;;;
;;; \begin{code}
{define-macro destructuring-bind
  [|pat lst #!rest body|
   {let ((glst (gensym)))
     `{let ((,glst ,lst))
        ,{let create-nested-lets ((bindings
                                   (tree-of-accessors
                                    pat
                                    glst
                                    gensym: gensym)))
           (if (null? bindings)
               [`{begin ,@body}]
               [`{let ,(map [|b| (if (pair? (car b))
                                     [(car b)]
                                     [b])]
                            bindings)
                   ,(create-nested-lets (flatmap [|b| (if (pair? (car b))
                                                          [(cdr b)]
                                                          ['()])]
                                                 bindings))}])}}}]}
;;; \end{code}
;;;
;;; \cite[p. 232]{onlisp}
;;;
;;;
;;;
;;; \begin{code}
{unit-test
 (equal? {macroexpand-1
          {destructuring-bind (a (b . c) #!rest d)
                              '(1 (2 3) 4 5)
                              (list a b c d)}}
         '{let ((gensymed-var1 '(1 (2 3) 4 5)))
            {let ((a (list-ref gensymed-var1 0))
                  (gensymed-var2 (list-ref gensymed-var1 1))
                  (d (drop 2 gensymed-var1)))
              {let ((b (list-ref gensymed-var2 0))
                    (c (drop 1 gensymed-var2)))
                {begin (list a b c d)}}}})
 (equal? {destructuring-bind (a (b . c) #!rest d)
                             '(1 (2 3) 4 5)
                             (list a b c d)}
         '(1 2 (3) (4 5)))
 }
;;; \end{code}
;;;
;;; \newpage
;;; \section{The End of Compilation}
;;;
;;;
;;; At the beginning of the book, in chapter~\ref{sec:beginninglibbug}, ``bug-language.scm''
;;; was imported, so that ``libbug-private\#define'', and ``libbug-private\#define-macro'' can be used.
;;; This chapter is the end of the file ``main.bug.scm''.  However, as will be shown
;;; in the next chapter, ``bug-languge.scm'' opened files for writing during compile-time,
;;; and they must be closed, accomplished by executing ``at-end-of-compilation''.
;;;
;;; \begin{code}
{at-compile-time
 (at-end-of-compilation)}
;;; \end{code}
;;;
;;;
;;;
