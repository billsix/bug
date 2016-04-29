;;; %Copyright 2014-2016 - William Emerison Six
;;; %All rights reserved
;;; %Distributed under LGPL 2.1 or Apache 2.0
;;;
;;;
;;; \section{Closing Generated Files}
;;;  \label{sec:closefiles}
;;;
;;; The contents of this section are in ``src/bug-language-end.bug.scm''
;;;
;;; \begin{code}
;;;
;;;  ;;clear the namespace of the macro file
(at-compile-time
 (begin
   (display
    "
     (##namespace (\"\"))"
    libbug-macros-file)))
;;;
;;;
(at-compile-time
 (begin
   (force-output libbug-headers-file)
   (close-output-port libbug-headers-file)
   (force-output libbug-macros-file)
   (close-output-port libbug-macros-file)))
;;;\end{code}
;;; \bibliography{abbr_long,pubext}
;;;\begin{thebibliography}{9}
;;;
;;;\bibitem[Abelson96]{sicp}
;;;  Abelon, Harold, Gerald Jay Sussman, and Julie Sussman.
;;;  \emph{Structure and Interpretation of Computer Programs},
;;;  The MIT Press, Massachusetts,
;;;  Second Edition,
;;;  1996.
;;;
;;;\bibitem[Church51]{calculi}
;;;  Church, Alonzo
;;;  \emph{The Calculi of Lambda-Conversion},
;;;  Princeton University Press, New Jersey,
;;;  Second Printing,
;;;  1951.
;;;
;;;\bibitem[Dybvig03]{schemeprogramminglanguage}
;;;  Dybvig, R. Kent.
;;;  \emph{The Scheme Programming Language},
;;;  The MIT Press, Massachusetts,
;;;  Third Edition,
;;;  2003.
;;;
;;;\bibitem[Feeley12]{evalduringmacroexpansion}
;;;  Feeley, Marc. https://mercure.iro.umontreal.ca/pipermail/gambit-list/2012-April/005917.html, 2012
;;;
;;;\bibitem[Friedman96]{littleschemer}
;;;  Friedman, Daniel P., and Matthias Felleisen
;;;  \emph{The Scheme Programming Language},
;;;  The MIT Press, Massachusetts,
;;;  Fourth Edition,
;;;  1996.
;;;\bibitem[Graham94]{onlisp}
;;;  Graham, Paul.
;;;  \emph{On Lisp},
;;;  Prentice Hall, New Jersey,
;;;  1994.
;;;
;;;\bibitem[Graham96]{ansicl}
;;;  Graham, Paul.
;;;  \emph{ANSI Common Lisp},
;;;  Prentice Hall, New Jersey,
;;;  1996.
;;;
;;;\bibitem[Harvey01]{ss}
;;;  Harvey, Brian and Matthew Wright.
;;;  \emph{Simply Scheme - Introducing Computer Science},
;;;  The MIT Press, Massachusetts,
;;;  Second Edition,
;;;  2001.
;;;
;;;\bibitem[Hopcroft01]{hmu2001}
;;;  Hopcroft, John E., Rajeev Motwani, and Jeffrey D. Ullman.
;;;  \emph{Introduction to Automata Theory, Languages, and Computation},
;;;  Addison Wesley, Massachusetts,
;;;  Second Edition,
;;;  2001.
;;;
;;;\bibitem[Kiselyov98]{setf}
;;;  Kiselyov, Oleg. http://okmij.org/ftp/Scheme/setf.txt , 1998.
;;;\bibitem[Knuth97]{taocp}
;;;  Knuth, Donald E.
;;;  \emph{The Art Of Computer Programming, Volume 1},
;;;  Addison Wesley, Massachusetts,
;;;  Third Edition,
;;;  1997.
;;;\bibitem[Norvig92]{paip}
;;;  Norvig, Peter
;;;  \emph{Paradigms of Artificial Intelligence Programming: Case Studies in Common Lisp},
;;;  San Francisco, CA
;;;  1992.
;;;\bibitem[Pierce02]{tapl}
;;;  Pierce, Benjamin C.
;;;  \emph{Types and Programming Languages},
;;;  The MIT Press
;;;  Cambridge, Massachusetts
;;;  2002.
;;;\bibitem[Steele90]{cl}
;;;  Steele Jr, Guy L.
;;;  \emph{Common Lisp the Language},
;;;  Digital Press,
;;;  1990.
;;;
;;;
;;;
;;;
;;;\end{thebibliography}
;;; \printindex
;;;
;;;\end{document}  %End of document.
