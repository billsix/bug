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
;;;    \vspace{4 mm} \large{and the Implementation of Libbug}}
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

;;; \noindent  Copyright 2014-2016 William Emerison Six
;;;  \vspace{1cm}
;;;
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
;;; languages might lament the lack of types, as types help them to reason about
;;; programs and help them to deduce where to look to find more information.
;;; In trying to answer those questions,
;;; fans of dynamically-typed languages might argue ``Look at the tests!'',
;;; as tests ensure the code functions in a user-specified way and
;;; they serve as a form of documentation.  But
;;; where are those tests?  Probably in some other file, whose filesystem path is
;;; similar to the current file's path, (e.g., src/com/BigCorp/HugeProject/Foo.java
;;; is tested by test/com/BigCorp/HugeProject/FooTest.java)
;;; Then you'd have to find the file, open the file, look through it
;;; while ignoring tests which are
;;; for other methods.  Frankly, it's too much work and it interrupts the flow
;;; of coding, at least for me.
;;;
;;; But how else would a programmer organize tests?  Well, in this book, which is the
;;; implementation of a library called ``libbug''\footnote{Bill's Utilities
;;; for Gambit}, tests are specified as part of the procedure's definition,
;;; executed at compile-time.  Should any test fail the compiler will
;;; exit in error, not producing the libbug library.  Much like a type error in a
;;; statically-typed language.  Furthering the reliability of the code,
;;; the book you are currently reading
;;; is embedded into the source code of libbug; it is generated only upon successful
;;; compilation of libbug and it couldn't exist if a single test
;;; failed.

;;; So where are these tests then? The very alert reader may have noticed
;;; that the opening '\{' in the definition
;;; of ``permutations'' was not closed.  That is because tests can be specified
;;; to be run at compile-time as part of the definition of a procedure.
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
;;; \noindent Now, the closing '\}' is there, so ``permutations'' procedure is defined.
;;;
;;; Why does this matter?
;;; Towards answering the questions ``so what does the code do?'' and ``how did the author
;;; intend for it to be used?'', there is no searching through files, no extrapolation
;;; of expected inputs and outputs required.
;;; The fact that the
;;; tests are collocated with the procedure definition means that the reader can
;;; read the tests without switching between files, perhaps reading the tests
;;; before reading the procedure definition.  And the reader
;;; may not even read the procedure at all if the tests gave them enough information
;;; to use it successfully.  But should the reader want to understand the procedure, they
;;; can apply the procedure incrementally to the tests to understand it.
;;;
;;; Wait a second. If those tests are defined in the source code itself, won't they
;;; be in the executable?  And won't they run every time I execute the program?
;;; That would be unacceptable, as it would increase the size of the binary and
;;; slow down the program at start up.  Fortunately, the
;;; answer to both questions is no, because in chapter~\ref{sec:buglang} I show how to specify
;;; that certain code should be interpreted by the compiler instead of being
;;; compiled\footnote{Which is also why this book is
;;; called the more general ``Computation at Compile-Time'' instead of ``Testing
;;; at Compile-Time''}.  Lisp implementations such as Gambit are particularly well
;;; suited for this style of programming because unevaluated Lisp code is
;;; specified using a data structure of Lisp; because the compiler
;;; is an interpreter capable of being augmented with the very
;;; same code which it is compiling.  Upon finishing compilation, the
;;; compiler has \emph{become} the very program it is compiling.
;;;
;;;
;;; \tableofcontents
;;; \break
;;; \part{Background}
;;; \chapter{Introduction}
;;; \pagenumbering{arabic}
;;; Libbug is Bill's Utilities for Gambit Scheme:  a ``standard library'' of procedures
;;; which augments Scheme's small set of built-in procedures and macros.
;;; Libbug provides procedures for list processing, streams, procedure-building procedures,
;;; control structures,
;;; general-purpose evaluation at compile-time, a
;;; compile-time test framework\footnote{in only 9 lines of code!}, and a Scheme preprocessor to
;;; provide a lambda literal syntax.  Programs written using libbug optionally may be
;;; programmed in a relatively unobstructive
;;; ``literate programming''\footnote{http://lmgtfy.com/?q=literate+programming}
;;; style, so that a program, such as libbug, can be read linearly in a book form.

;;; \section{Prerequisites}
;;;
;;; The reader is assumed to be somewhat familiar both with Scheme, with Common Lisp-style
;;; macros, and with recursive design.  Reading ``Simply Scheme''
;;; \cite{ss}\footnote{available on-line for no cost}
;;; or ``The Little Schemer'' \cite{littleschemer} should be sufficient
;;; to understand all of the code except for the macros.  Reading ``On Lisp''
;;; \cite{onlisp}\footnote{available on-line for no cost} is more than sufficient
;;; to understand everything in this book, as this book expands on chapter 13 of
;;; ``On Lisp'''; also called``Computation at Compile-Time''.
;;;
;;; The other books listed in the bibliography, all of which inspired ideas for this
;;; book, are all recommended reading, but are
;;; not necessary to understand the content of this book.
;;;
;;; \section{Conventions}
;;; Code which is part of libbug will be outlined and will have line numbers on the left.
;;;
;;; \begin{code}
;; This is part of libbug.
;;; \end{code}
;;;
;;; \noindent
;;; Example code which is not part of libbug will not be outlined nor will have line
;;; numbers.
;;;
;;; \begin{examplecode}
;;; (+ 1 ("This is NOT part of libbug"))
;;; \end{examplecode}

;;; \noindent
;;; In libbug, the notation

;;; \begin{examplecode}
;;; (fun arg1 arg2)
;;; \end{examplecode}
;;;
;;; \noindent
;;;  means evaluate ``fun'', ``arg1''
;;; and ``arg2'' in any order, then apply ``fun'' to ``arg1'' and ``arg2''.
;;; Standard Scheme semantics. But regular Scheme uses this same notation for all macro applications.
;;; As macros transform source code into different source code before compilation, the generated
;;; code may not follow the standard order of evaluation.  For instance, an argument may be
;;; evaluated multiple
;;; times in the generated code, causing an unintended side-effect.
;;; The inability for the reader to reason about the evaluation semantics of arguments to a macro
;;; at the call site may cause confusion to the reader; as such,
;;; within libbug the notation

;;; \begin{examplecode}
;;; {fun1 arg1 arg2}
;;; \end{examplecode}

;;; \noindent
;;; is used to denote to
;;; the reader that the standard evaluation rules do not necessarily apply to
;;; all arguments.  For instance, in

;;; \begin{examplecode}
;;;{define x 5}
;;; \end{examplecode}

;;; \noindent
;;; \{\} are used because ``x''
;;; may be a new variable.  As such, it cannot currently evaluate to anything.
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
;;;  The Scheme files can produce the libbug library, as well as this book.
;;;  This book was generated from git commit ID \input{version.tex} .
;;;  Currently, the code works on various distributions of Linux, and on
;;;  OS X.  The build currently does not work on Windows.
;;;
;;; You will of course need a C compiler, and Gambit
;;; Scheme\footnote{http://gambitscheme.org}.
;;;
;;; To compile the book and library, execute the following on the command line:
;;;
;;; \begin{examplecode}
;;; $ ./autogen.sh
;;; $ ./configure --enable-pdf=yes
;;; $ make
;;; $ make install
;;; \end{examplecode}


;;; \chapter{Compile-Time Language}
;;;
;;; This chapter provides a quick tour of computer language which is interpreted
;;; by the compiler, but which has no direct representation in the generated machine
;;; code.  Examples are provided in well-known languages to illustrate that
;;; many compilers are also interpreters for a subset of the language.  This
;;; chapter is not required to understand the rest of the book, and may be freely
;;; skipped, but it provides a baseline understanding of compile-time computation,
;;; so the reader may contrast these languages' capabilities with libbug's.

;;; First, let's discuss was is meant by the word ``language''.
;;; In ``Introduction to Automata Theory, Languages, and Computation'', Hopcroft,
;;; Motwani, and Ullman define language as ``A set of strings all of which are chosen
;;; from some $\Sigma$ $\star$, where $\Sigma$ is a particular alphabet, is called
;;; a language'' \cite[p. 30]{hmu2001}.
;;;  They further state ``In automata theory, a problem is the question
;;; of deciding whether a given string is a member of some particular language''. TODO cite.
;;;
;;; In practice, if your compiler successfully compiles your code, congratulations!
;;; The code is a valid string in the language, and passed any additional constraints
;;; (e.g. type-checking).  But does all of that language directly generate instructions
;;; in the machine code?  Turns out, no, it does not.

;;; \section{C}
;;;Consider the following C code:
;;;
;;; \begin{examplecode}
;;;/*Line01*/  #include <stdio.h>
;;;/*Line02*/  #define square(x) ((x) * (x))
;;;/*Line03*/  int fact(unsigned int n);
;;;/*Line04*/  int main(int argc, char* argv[]){
;;;/*Line05*/  #ifdef DEBUG
;;;/*Line06*/    printf("Debug - argc = %d\n", argc);
;;;/*Line07*/  #endif
;;;/*Line08*/   printf("%d\n",square(fact(argc)));
;;;/*Line09*/    return 0;
;;;/*Line10*/  }
;;;/*Line11*/  int fact(unsigned int n){
;;;/*Line12*/    return n == 0
;;;/*Line13*/      ? 1
;;;/*Line14*/      : n * fact(n-1);
;;;/*Line15*/  }
;;; \end{examplecode}
;;;
;;; On the first line, the \#include preprocessor command
;;; is language that the compiler
;;; is intended to interpret, instructing the compiler to
;;; read the file ``stdio.h''
;;; from the filesystem and to splice the content
;;; into the current C file.  The include command
;;; itself has no representation in the machine code, although the contents
;;; of the included file may.
;;;
;;; The second line defines a C macro. It is a procedure which takes a text
;;; string as input and transforms it into a new text string as output.
;;; This expansion happens before the compiler does anything
;;; else.  For example, using GCC as a compiler, if you run the C preprocessor
;;; ``cpp'' on the above C code, you'll see that
;;;
;;; \begin{examplecode}
;;;  printf("%d\n",square(fact(argc)));
;;; \end{examplecode}
;;;
;;; \noindent expands into
;;;
;;; \begin{examplecode}
;;;  printf("%d\n",((fact(argc)) * (fact(argc))));
;;; \end{examplecode}
;;;
;;; \noindent before compilation.
;;;
;;; The third line defines a function prototype, so that
;;; the compiler knows the argument types and return type for a function called ``fact''.
;;; It is language interpreted by the compiler to determine the types for the function
;;; call to ``fact'' on line 8, since ``fact'' has not yet been defined in this
;;; translation unit.
;;;
;;; The fourth through tenth line is a function definition, which will have
;;; a representation in the machine code.  However, line 5 is language
;;; to be interpreted by the compiler, referencing a variable defined
;;; only during compilation, to detemine whether or not line 6 should be
;;; compiled.
;;;
;;; \section{C++}
;;;
;;; C++ inherits C's macros, but with the additional introduction
;;; of templates, C++'s compile time language
;;; incidently became Turing complete.  This means that
;;; theoretically, anything that can be
;;; calculated by a computer can be calculated using template expansion
;;; at compile time.  Fun fact, but general purpose computation using template
;;; metaprogramming is not useful in practice.
;;;
;;; The following is an example of calculating the factorial of
;;; 3, using both C++ functions and C++'s templates.
;;;
;;; \begin{examplecode}
;;; /*Line01*/  #include <iostream>
;;; /*Line02*/  template <unsigned int n>
;;; /*Line03*/  struct factorial {
;;; /*Line04*/      enum { value = n * factorial<n - 1>::value };
;;; /*Line05*/  };
;;; /*Line06*/  template <>
;;; /*Line07*/  struct factorial<0> {
;;; /*Line08*/      enum { value = 1 };
;;; /*Line09*/  };
;;; /*Line10*/  int fact(unsigned int n){
;;; /*Line11*/    return n == 0
;;; /*Line12*/      ? 1
;;; /*Line13*/      : n * fact(n-1);
;;; /*Line14*/  }
;;; /*Line15*/  int main(int argc, char* argv[]){
;;; /*Line16*/    std::cout << factorial<3>::value << std::endl;
;;; /*Line17*/    std::cout << fact(3) << std::endl;
;;; /*Line18*/    return 0;
;;; /*Line19*/  }
;;; \end{examplecode}

;;; On line 16, ``factorial\textless3\textgreater::value'' is an
;;; instruction to be interpreted
;;; by the compiler using templates.  Template expansions
;;; conditionally match patterns based on types (or values in the case
;;; of integers).  For iteration, instead of loops, templates expand recursively.
;;; In this case, the expansion of
;;; ``factorial\textless3\textgreater::value'' in dependent upon
;;; ``factorial\textless n-1\textgreater::value''.  The compiler
;;; does the subtraction at compile-time,
;;; so ``factorial\textless3\textgreater::value'' is dependent on
;;; ``factorial\textless2\textgreater::value''.
;;; This recursion will terminate on ``factorial\textless0\textgreater::value''
;;; on line 7. (Even though
;;; the base case of ``factorial\textless0\textgreater'' is specified
;;; after the more general
;;; case of ``factorial\textless n\textgreater'', template expansion expands to the most
;;; specific case first.  So the compiler will terminate.)
;;;
;;; On line 17, a run-time call to ``fact'', defined on line 10, is declared.
;;;
;;; We can verify that the stated behavior is true by disassembling the machine code.
;;; By disassembling the machine code using ``objdump -D'', we can
;;; see the drastic difference in the generated code.
;;;
;;; \begin{examplecode}
;;; 400850:       be 06 00 00 00          mov    $0x6,%esi
;;; 400855:       bf c0 0d 60 00          mov    $0x600dc0,%edi
;;; 40085a:       e8 41 fe ff ff          callq  4006a0 <_ZNSolsEi@plt>
;;; .......
;;; .......
;;; .......
;;; 40086c:       bf 03 00 00 00          mov    $0x3,%edi
;;; 400871:       e8 a0 ff ff ff          callq  400816 <_Z4facti>
;;; 400876:       89 c6                   mov    %eax,%esi
;;; 400878:       bf c0 0d 60 00          mov    $0x600dc0,%edi
;;; 40087d:       e8 1e fe ff ff          callq  4006a0 <_ZNSolsEi@plt>
;;; \end{examplecode}

;;; The instructions at locations 400850 through 40085a correspond to the
;;; printing out of the compile-time expanded call to factorial\textless3\textgreater.
;;; The number 6 is loaded into the esi register; then the second
;;; two lines call the printing routine\footnote{at least I assume, because
;;; I don't completely understand how C++ name-mangling works}.

;;; The instructions at locations 40086c through 40087d correspond to the
;;; printing out of the run-time calculation to fact(3).  The number 3
;;; is loaded into the edi register, fact is invoked, the result of
;;; calling fact is moved from the eax register to the esi register, and then
;;; printing routine is called.
;;;
;;; The compile-time computation worked!

;;; \section{libbug}
;;; With libbug, the following is how you'd define factorial, pretty-print
;;; the factorial of 3, both computed at compile-time and computed at run-time.
;;;
;;; \begin{examplecode}
;;; {at-both-times
;;;  {define fact
;;;    [|n| (if (= n 0)
;;;             [1]
;;;             [(* n (fact (- n 1)))])]}}
;;;
;;; (pp (at-compile-time-expand (fact 3)))
;;; (pp (fact 3))
;;; \end{examplecode}
;;;

;;; By compiling the Scheme source to the ``gvm'' intermediate
;;; representation, we can verify the stated behavior.

;;; In the compile-time calculation of fact, the following gvm code is produced.

;;; \begin{examplecode}
;;; r1 = '6
;;;   r0 = frame[1]
;;;   jump/poll fs=4 #4
;;; #4 fs=4
;;;   jump/safe fs=0 global[pp] nargs=1
;;; \end{examplecode}

;;;  \noindent The precomputed value of ``(fact 3)'', 6, is loaded into a variable, there's no
;;;  jump to fact, just a jump to pp.  Fantastic!

;;; In the run-time calculation of fact, the following gvm code is produced.

;;; \begin{examplecode}
;;; r1 = '3
;;;   r0 = #4
;;;   jump/safe fs=4 global[fact] nargs=1
;;; #4 fs=4 return-point
;;;   r0 = frame[1]
;;;   jump/poll fs=4 #5
;;; #5 fs=4
;;;   jump/safe fs=0 global[pp] nargs=1
;;; \end{examplecode}

;;; \noindent The number 3 is being loaded into a variable r1, there's a jump
;;; (effectively a procedure call) to the
;;; fact procedure, and then a jump to pp.

;;;
;;; So this has been an moderately interesting excercise, but why is
;;; this important?
;;; This chapter demonstrates that compilers have interpretive aspects to them,
;;; which is mostly taken for granted and not questioned.
;;; C has two distinct sub-''languages'', one for compile-time and one
;;; for run-time;
;;; both of which have variables, conditionals, and procedure definitions.
;;; As does C++, which also has compile-time Turing-completeness in an awkward
;;; purely functional language
;;; lacking state and IO. The Java Virtual Machine, initially just an interpreter
;;; of Java byte-code, eventually added the ability to compile byte-code
;;; into optimized machine code during interpretation to increase performance.
;;; Libbug, on the opposite end of the spectrum, is meant to be compiled, but it adds
;;; a full interpreter to be executed during compile-time, including state and IO.
;;;
;;; When I first started on this project, I only wanted a way to collocate
;;; tests with definitions, to evaluate the tests at compile time, and to error out
;;; of compilation
;;; if a test failed.  Only later did I realize that compile-time evaluation
;;; can execute full programs without limitations.  What else could be
;;; calculated at compile-time?  In graphics, perhaps calculating normal vectors
;;; from a vertex mesh automatically; perhaps writing ``shaders'' as compile-time
;;; tested Scheme procedures which are translated into actual shaders at compile-time.
;;; In database programming, perhaps fetching the table definitions at compile-time,
;;; and generating code for easy database access.
;;;
;;; I don't understand all of the implications of having a compiler augment itself
;;; with the code its currently compiling.   ``Come along and ride on a fantastic voyage.''

;;; \part{The Implementation of Libbug}
;;; \chapter{General Procedures}
;;;
;;; This part defines a standard library of Scheme procedures and
;;; macros\footnote{The code within this section is all found in
;;; ``src/main.bug.scm''.}, along with tests which are run as part of the
;;; compilation process.
;;;
;;;
;;; Libbug defines extensions to the Scheme language, implemented via
;;; macros.  They are ``libbug\#define'', and ``libbug\#define-macro''.
;;; As they are namespaced to ``libbug'', they are not compiled into the library
;;; or other output files; they are meant for private use within the implementation
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
{##namespace ("libbug#" define)}
{##namespace ("libbug#" define-macro)}
;;;\end{code}

;;;
;;; \newpage
;;; \section{lang\#noop}
;;; The first definition is ``noop'', a procedure which takes no arguments and
;;; which evaluates to the symbol 'noop.

;;; \index{lang\#noop}
;;; \begin{code}
{define
  "lang#"
  noop
  ['noop]
;;; \end{code}

;;; \begin{itemize}
;;;   \item On line 1, the libbug\#define macro\footnote{defined in section ~\ref{sec:libbugdefine}}
;;; is invoked.
;;;   \item On line 2, a namespace
;;;   \item On line 3, the variable name, which will be declared in the
;;;         namespace defined on line 2.
;;;   \item On line 4, the lambda literal to be stored into the variable.
;;;         libbug includes a Scheme preprocessor ``bug-gscpp'',
;;;         which expands lambda literals
;;;         into lambdas.  In this case
;;;
;;; \begin{examplecode}
;;; ['noop]
;;; \end{examplecode}

;;; \noindent
;;; is expanded into

;;; \begin{examplecode}
;;; (lambda () 'noop)
;;; \end{examplecode}

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
;;; the ``\textbar''s.
;;; \end{itemize}

;;; \subsection*{Test}

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
;;; Like ``and'', but takes a list instead of a variable number of arguments.
;;;
;;; \label{sec:langiffirstuse}
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
;;;   \item On line 5, if, which is currently namespaced to lang\#if\footnote{
;;;      defined in section~\ref{sec:langif} }, takes
;;;         lambda expressions for the two parameters. I like to think of
;;;         \#t, \#f, and if as the
;;;         following\footnote{\#t is the constancy function K\cite[p. 4]{calculi}}:
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
;;; Tests in libbug are defined for two purposes.  First, to ensure
;;; that expected behavior of a procedure does not change when that procedure's internal
;;; definition has changed.  Second, as a form of documentation of the procedure.
;;; Libbug is unique\footnote{as far as the author knows} in that the tests are collocated with
;;; the procedure definitions.  As such, the reader is encouraged to read the tests for a
;;; procedure before reading the implementation; since in many cases, the tests are designed
;;; specifically to walk the reader through the implementation.
;;;
;;; \newpage
;;; \section{lang\#satisfies?}

;;; When writing multiple tests, why explicitly invoke the procedure repeatedly,
;;; with varying inputs and outputs?  Instead, provide the procedure, and a list
;;; of input/output pairs.
;;;
;;; \index{lang\#satisfies?}
;;; \begin{code}
{define
  "lang#"
  satisfies?
  [|fn list-of-pairs|
   (all? (map [|pair| (equal? (fn (car pair))
                              (cadr pair))]
              list-of-pairs))]
;;; \end{code}
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

;;; \newpage
;;; \section{lang\#compose}

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

;;; \cite[p. 66]{onlisp}
;;;
;;;
;;; Libbug is a library, meant to be used by other projects.  From libbug, these
;;; projects will require namespace definitions, as well as macro definitions.
;;; As such, besides defining the macro, libbug\#define-macro\footnote{
;;; defined in section ~\ref{sec:libbugdefinemacro}}
;;; also exports the
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
;;;
;;; Macro-expansions occur during compile-time, so how should a person
;;; test them?  Libbug provides ``macroexpand-1'' which treats the macro
;;; as a normal procedure, and as such is able to be tested.
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


;;; \newpage
;;; \section{lang\#atom?}
;;;
;;; For the remaining procedures, if the tests do an adequate job of explaining
;;; the code, there will be no written documentation.
;;;
;;; \index{lang\#atom?}
;;; \begin{code}
{define
  "lang#"
  atom?
  [|x| {and (not (pair? x))
            (not (null? x))}]
;;; \end{code}

;;; \noindent \cite[p. TODO]{littleschemer}

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

;;; \cite[p. 63]{onlisp}
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

;;; \newpage
;;; \section{lang\#while}
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

;;; \newpage
;;; \section{lang\#numeric-if}
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

;;; \cite[p. 150, called ``nif'']{onlisp}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|n|
    (numeric-if n ifPositive: ['pos] ifZero: ['zero] ifNegative: ['neg])]
   '(
     (5 pos)
     (0 zero)
     (-5 neg)
     ))}
;;; \end{code}
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

;;; \cite[p. 191]{onlisp}
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
;;;


;;; \newpage
;;; \section{lang\#symbol-append}
;;;
;;; \index{lang\#symbol-append"}
;;; \begin{code}
{define
  "lang#"
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


;;; \newpage
;;; \section{lang\#with-gensyms}
;;;   Utility for macros to minimize explicit use of gensym.
;;;   Gensym creates a symbol at compile time which is guaranteed
;;;   to be unique.  Macros which intentionally capture variables,
;;;   such as aif, are the anomaly.
;;;   Usually, variables local to a macro should not clash
;;;   with variables local to the macro caller.
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

;;; \cite[p. 145]{onlisp}
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

;;; \newpage
;;; \section{lang\#Y}
;;; \index{lang\#Y}
;;;
;;; The Y combinator allows a programmer to create a procedure which references
;;; itself without needing to define a variable.  There is never an actual need
;;; to use this in real code.  Read \cite[p. 149-172]{littleschemer} for an excellent
;;; derivation of this combinator.
;;;
;;;
;;; \begin{code}
{define
  "lang#"
  Y
  [|le|
   ([|f| (f f)]
    [|f| (le [|x| ((f f) x)])])]
;;; \end{code}
;;; \section*{Test}
;;; \begin{code}
  (satisfies?
   (Y [|fact|
       [|n|
	(if (= n 0)
	    [1]
	    [(* n (fact (- n 1)))])]])
   `(
     (0 1)
     (1 1)
     (2 2)
     (3 6)
     (4 24)
     ))}
;;; \end{code}

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
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((a '(1 2 3 4 5)))
    {and (equal? a (copy a))
         (not (eq? a (copy a)))}}
  }
;;; \end{code}


;;; \newpage
;;; \section{list\#proper?}
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
  (satisfies?
   proper?
   '(
     (4 #f)
     ((1 2) #t)
     ((1 2 . 5) #f)
     ))}
;;; \end{code}




;;; \newpage
;;; \section{list\#first}
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

;;; \cite[p. 59]{ss}
;;;
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


;;; \newpage
;;; \section{list\#but-first}
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

;;; \cite[p. 59]{ss}
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

;;; \newpage
;;; \section{list\#last}
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

;;; \cite[p. 59]{ss}
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
  [|lst #!key (onNull noop)|
   (if (null? lst)
       [(onNull)]
       [{let but-last ((lst lst))
          (if (null? (cdr lst))
              ['()]
              [(cons (car lst)
                     (but-last (cdr lst)))])}])]
;;; \end{code}

;;; \cite[p. 59]{ss}
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

;;; \newpage
;;; \section{list\#filter}
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

;;; \cite[p. 331]{ss}\footnote{Simply Scheme has an excellent discussion on section
;;; on Higher-Order Functions and their combinations TODO ensure the pages are correct from this source \cite[p. 103-125]{ss}}. \cite[p. 115]{sicp}.
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

;;; \newpage
;;; \section{list\#remove}
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
  (satisfies?
   [|l| (remove 5 l)]
   '(
     ((1 5 2 5 3 5 4 5 5) (1 2 3 4))
     ))}
;;; \end{code}

;;; \newpage
;;; \section{list\#fold-left}
;;;    Reduce the list to a scalar by applying the reducing function repeatedly,
;;;    starting from the ``left'' side of the list
;;;
;;; \index{list\#fold-left}
;;; \begin{code}
{define
  "list#"
  fold-left
  [|fn initial lst|
   {let fold-left ((acc initial) (lst lst))
     (if (null? lst)
         [acc]
         [(fold-left (fn acc
                         (car lst))
                     (cdr lst))])}]
;;; \end{code}

;;; \cite[p. 121]{sicp}
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
  (satisfies?
   [|l| (fold-left - 5 l)]
   '(
     (() 5)
     ((1) 4)
     ((1 2) 2)
     ((1 2 3 4 5 6) -16)))}
;;; \end{code}
;;;

;;; \newpage
;;; \section{list\#fold-right}
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

;;; \cite[p. 116 (named ``accumulate'')]{sicp}
;;; \subsection*{Tests}
;;; \begin{code}
  (satisfies?
   [|l| (fold-right - 0 l)]
   '(
     (() 0)
     ((1) 1)
     ((2 1) 1)
     ((3 2 1) 2)
     ))}
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
  (satisfies?
   [|l| (scan-left * 1 l)]
   '(
     (() (1))
     ((2) (1 2))
     ((2 3) (1 2 6))
     ((2 3 4) (1 2 6 24))
     ((2 3 4 5 ) (1 2 6 24 120))
     ))}
;;; \end{code}



;;; \newpage
;;; \section{list\#flatmap}
;;; \index{list\#flatmap}
;;; \begin{code}
{define
  "list#"
  flatmap
  [|fn lst|
   (fold-left append! '() (map fn lst))]
;;; \end{code}

;;; \cite[p. 123]{sicp}

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

;;; \newpage
;;; \section{list\#take}
;;; \index{list\#take}
;;; \begin{code}
{define
  "list#"
  take
  [|n lst|
   (if (or (null? lst) (= n 0))
       ['()]
       [(cons (car lst)
              (take (- n 1)
                    (cdr lst)))])]
;;; \end{code}

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


;;; \newpage
;;; \section{list\#take-while}
;;; \index{list\#take-while}
;;; \begin{code}
{define
  "list#"
  take-while
  [|p? lst|
   {let take-while ((lst lst))
     (if (or (null? lst) ((complement p?) (car lst)))
         ['()]
         [(cons (car lst)
                (take-while (cdr lst)))])}]
;;; \end{code}

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


;;; \newpage
;;; \section{list\#drop}
;;; \index{list\#drop}
;;; \begin{code}
{define
  "list#"
  drop
  [|n lst|
   (if (or (null? lst) (= n 0))
       [lst]
       [(drop (- n 1)
              (cdr lst))])]
;;; \end{code}

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

;;; \newpage
;;; \section{list\#drop-while}
;;; \index{list\#drop-while}
;;; \begin{code}
{define
  "list#"
  drop-while
  [|p? lst|
   {let drop-while ((lst lst))
     (if (null? lst)
         ['()]
         [(if ((complement p?) (car lst))
              [lst]
              [(drop-while (cdr lst))])])}]
;;; \end{code}

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

;;; \newpage
;;; \section{list\#any?}
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

;;; \newpage
;;; \section{list\#permutations}
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
;;; mistake in
;;;  their code.  Given their definition (permutations '()) evaluates to '(()), instead of '().
;;;
;;; \cite[p. 45]{taocp}

;;; \newpage
;;; \section{list\#sublists}
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
  (satisfies?
   sublists
   '(
     (() ())
     ((3) ((3)))
     ((2 3) ((2 3) (3)))
     ((1 2 3) ((1 2 3) (2 3) (3)))
     ))}
;;; \end{code}

;;; \newpage
;;; \section{list\#ref-of}
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
  (satisfies?
   [|x| (ref-of '(a b c d e f g) x)]
   '(
     (z noop)
     (a 0)
     (b 1)
     (g 6)
     ))
;;; \end{code}
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
;;; \begin{code}
  {let ((lst '(a b c d e f g)))
    (satisfies?
     [|x| (list-ref lst (ref-of lst x))]
     '(
       (a a)
       (b b)
       (g g)
       ))}
  }
;;; \end{code}



;;; \newpage
;;; \section{list\#partition}
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
  (satisfies?
   [|lst| (partition lst [|x| (<= x 3)])]
   '(
     (() (()
          ()))
     ((3 2 5 4 1) ((1 2 3)
                   (4 5)))
     ))}
;;; \end{code}

;;; \newpage
;;; \section{list\#sort}
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
  (satisfies?
   [|lst| (sort lst <)]
   '(
     (() ())
     ((1 3 2 5 4 0) (0 1 2 3 4 5))
     ))}
;;; \end{code}


;;; \newpage
;;; \section{list\#reverse!}
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
  (satisfies?
   reverse!
   '(
     (() ())
     ((1) (1))
     ((2 1) (1 2))
     ((3 2 1) (1 2 3))
     ))}
;;; \end{code}




;;; \newpage
;;; \chapter{Streams}

;;; Streams are lists whose evaluation is deferred until the value is
;;; requested.  For more information, consult ``The Structure and
;;; Interpretation of Computer Programs''.

;;; \section{stream\#stream-cons}
;;;
;;; \index{stream\#stream-cons}
;;; \begin{code}
{define-macro
  "stream#"
  stream-cons
  [|a b|
   `(cons ,a {delay ,b})]
;;; \end{code}

;;; \cite[p. 321]{sicp}.
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
;;;

;;; \newpage
;;; \section{stream\#stream-car}
;;; Get the first element of the stream.
;;;
;;; \index{stream\#stream-car}
;;; \begin{code}
{define
  "stream#"
  stream-car
  car
;;; \end{code}

;;; \cite[p. 321]{sicp}.
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((s {stream-cons 1 2}))
    (equal? (stream-car s)
            1)}}
;;; \end{code}
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
  [|s| {force (cdr s)}]
;;; \end{code}

;;; \cite[p. 321]{sicp}.
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((s {stream-cons 1 2}))
    (equal? (stream-cdr s)
            2)}}
;;; \end{code}
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
  {let ((foo (stream#list->stream '(1 2 3))))
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
              [(if (not (null? (stream-cdr s)))
                   [(stream-ref (stream-cdr s) (- n 1))]
                   [(onOutOfBounds)])])}])]
;;; \end{code}

;;; \cite[p. 319]{sicp}.
;;; \subsection*{Tests}
;;; \begin{code}
  {let ((s (list->stream '(5 4 3 2 1))))
    {and
     (equal? (stream-ref s -1)
             'noop)
     (equal? (stream-ref s 0)
             5)
     (equal? (stream-ref s 4)
             1)
     (equal? (stream-ref s 5)
             'noop)
     (equal? (stream-ref s 5 onOutOfBounds: ['out])
             'out)}}}
;;; \end{code}
;;;


;;; \newpage
;;; \chapter{Generalized Assignment}
;;; \section{lang\#setf!}
;;; Sets a variable using its ``getting'' procedure, as done in Common Lisp.
;;; The implementation inspired by \cite{setf}.
;;;
;;; Libbug includes a macro called ``at-compile-time''\footnote{defined
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

;;; \begin{code}
(include "bug-language-end.scm")
;;; \end{code}

;;; \footnote{defined in section ~\ref{sec:closefiles}}
;;;

