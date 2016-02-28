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
;;;\usepackage{titlesec}
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
;;;     \lstset{language=Lisp, frame=single,framerule=.8pt,
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
;;;   {\fontfamily{mdugm}\fontsize{60}{60}\selectfont\thechapter}}%
;;;  {10 pt}%
;;;  {\bfseries\huge}%
;;; \date{}
;;; \begin{document}
;;;
;;; % Article top matter
;;; \title{Computation At Compile-Time \\
;;;    \normalsize{and the implementation of libbug}}
;;;
;;; \author{Bill Six}

;;; \maketitle
;;; \break

;;; \chapter*{Preface}
;;;  This will be the preface.

;;; \tableofcontents
;;; \break
;;; \chapter{Introduction}
;;; \pagenumbering{arabic}
;;; BUG is Bill's Utilities for Gambit-C.  BUG provides a concise syntax for
;;; lambdas,  utilities for general-purpose evaluation at compile-time, a
;;; compile-time unit test framework, and a collection of utility functions that
;;; I find useful.  Taken together, these can be used in a ``literate programming''
;;; style.

;;; \begin{examplecode}
;;; class Foo{
;;; }
;;; \end{examplecode}
;;; \section{Prerequisites}
;;;
;;; The reader is assumed to be familiar both with Scheme, and with Common Lisp-style
;;; macros, which Gambit-C provides.  Suggested reading is ``The Structure and
;;; Interpretation of Computer Programs'' by Sussman and Abelson, ``ANSI Common
;;; Lisp'' by Paul Graham, and ``On Lisp'' by Paul Graham.  These books inspired many
;;; ideas within BUG.
;;;
;;; \section{Conventions}
;;; In BUG, the notation ``(fun arg1 arg2)'' means evaluate ``fun'', ``arg1''
;;; and ``arg2'', and then apply ``fun'' to ``arg1'' and ``arg2''.  This notation
;;; is standard Scheme, but Scheme uses the same notation for macro application.
;;; This can cause some confusion to a reader.  To attempt to minimize the confusion,
;;; within BUG the notation ``\{fun1 arg1 arg2\}'' is used to denote to
;;; the reader that the standard evaluation rules do not necessarily apply to
;;; all arguments.  For instance, in ``\{define x 5\}'', \{\} are used because ``x''
;;; is a new variable, and as such, cannot currently evaluate to anything.
;;;
;;;
;;;

;;; \section{Language Definition}
;;;
;;;
;;;
;;; BUG defines extensions to the Scheme language, implemented via
;;; macros.  They are implemented in ``bug-language.bug.scm''\footnote{Although
;;; the filename is ``bug-language.bug.scm'', ``bug-language.scm'' is imported.  This
;;; is because ``bug-gscpp'' preprocesses the bug file, and outputs a standard Gambit
;;; Scheme file, with a different filename}, which will now
;;; import.  How to use these procedure-defining procedures will be explained
;;; incrementally, and their implementation is defined in
;;; section~\ref{sec:buglang}.
;;;
;;; \begin{code}
(include "bug-language.scm")
;;;\end{code}
;;; \chapter{libbug}
;;;
;;; This chapter defines a standard library of Scheme procedures and macros
;;; \footnote{The code within this section is all found in
;;; ``src/main.bug.scm''.}, along with tests which are run as part of the
;;; compilation process.
;;;
;;;
;;; \section*{lang\#noop}
;;; The first definition is ``noop'', a procedure which takes no arguments and
;;; which evaluates to the symbol 'noop.  noop is defined using ``libbug\#define''
;;; instead of Scheme's regular define.

;;; \index{lang\#noop}
;;; \begin{code}
{libbug#define
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
{libbug#define
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
{libbug#define
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
;;;     (define \#t {[}\textbar t f\textbar (t){]}
;;;
;;;     (define \#f {[}\textbar t f\textbar (f){]}
;;;
;;;     (define lang\#if {[}\textbar b t f\textbar (b t f) {]}
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
{libbug#define
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
{libbug#define-macro
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
;;; \index{list\#any?}
;;; \begin{code}
{libbug#define
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
{libbug#define
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
{libbug#define
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
{libbug#define
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



;;; \section*{list\#reverse!}
;;;   Reverses the list quickly by reusing cons cells
;;;
;;; \index{list\#reverse"!}
;;; \begin{code}
{libbug#define
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

;;; \section*{list\#first}
;;;
;;; list\#first uses Gambit's keyword syntax.  In the code, ``onNull'' is
;;; an optional argument, with a default value of the value in the ``noop''
;;; variable.  The first test does not provide a value for ``onNull'',
;;; the second test does, which demonstrates the syntax.
;;;
;;; \index{list\#first}
;;; \begin{code}
{libbug#define
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
{libbug#define
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
{libbug#define
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
{libbug#define
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
{libbug#define
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
{libbug#define
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
{libbug#define
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
{libbug#define
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

;;; \section*{list\#scan-left}
;;;   Like fold-left, but every intermediate value
;;;   of fold-left's accumulator is put onto the resulting list
;;;
;;; \index{list\#scan-left}
;;; \begin{code}
{libbug#define
 "list#"
 scan-left
 [|fn initial lst|
  {let scan-left ((acc-list (list initial)) (lst lst))
    (if (null? lst)
	[(reverse! acc-list)]
	[{let ((newacc (fn (first acc-list)
			   (car lst))))
	   (scan-left (cons newacc acc-list)
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
{libbug#define
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
{libbug#define
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
{libbug#define
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
{libbug#define
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
{libbug#define
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
    ((1) ((1)))
    ((1 2) ((1 2) (2)))
    ((1 2 3) ((1 2 3) (2 3) (3)))
    ))}
;;; \end{code}

;;; \section*{list\#ref-of}
;;; The inverse of list-ref.
;;;
;;; \index{list\#ref-of}
;;; \begin{code}
{libbug#define
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
{libbug#define
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
;;; \section*{list\#append!}
;;;   Like append, but recycles the last cons cell, so it's
;;;   faster, but mutates the input.
;;;
;;; \index{list\#append!"}
;;; \begin{code}
{libbug#define
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
;;; \section*{list\#sort}
;;; \index{list\#sort}
;;; \begin{code}
{libbug#define
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
{libbug#define-macro
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
{libbug#define
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
{libbug#define-macro
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
{libbug#define-macro
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
{libbug#define
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
{libbug#define
 "lang#"
 numeric-if
 [|expr #!key (ifPositive noop)
              (ifZero noop)
              (ifNegative noop)|
  {cond ((> expr 0) (ifPositive))
	((= expr 0) (ifZero))
	(else (ifNegative))}]
;;; \end{code}
;;; \subsection*{Tests}
;;; \begin{code}
 (satisfies-relation
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

;;; \section*{stream\#stream-cons}
;;; Streams are lists whose evaluation is deferred until the value is
;;; requested.  For more information, consult ``The Structure and
;;; Interpretation of Computer Programs''.
;;;
;;; \index{stream\#stream-cons}
;;; \begin{code}
{libbug#define-macro
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
{libbug#define
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
{libbug#define
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
{libbug#define
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
{libbug#define
 "stream#"
 stream-ref
 [|s n #!key (onOutOfBounds noop)|
  {define refPrime
    [|s n|
     (if (equal? n 0)
	 [(stream-car s)]
	 [(if (not (null? (stream-cdr s)))
	      [(refPrime (stream-cdr s) (- n 1))]
	      [(onOutOfBounds)])])]}
  (if (< n 0)
      [(onOutOfBounds)]
      [(refPrime s n)])]
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

