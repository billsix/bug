;;; %Copyright 2014-2016 - William Emerison Six
;;; %All rights reserved
;;; %Distributed under LGPL 2.1 or Apache 2.0
;;;

;;; \section{Closing Generated Files}
;;;  \label{sec:closefiles}

;;; The contents of this section are in ``src/bug-language-end.bug.scm''

;;; \begin{code}

;;;  ;;clear the namespace of the macro file
(at-compile-time
 (begin
   (display
    "
     (##namespace (\"\"))"
    libbug-macros-file)))


(at-compile-time
 (begin
   (force-output libbug-headers-file)
   (close-output-port libbug-headers-file)
   (force-output libbug-macros-file)
   (close-output-port libbug-macros-file)))
;;;\end{code}

;;;\begin{thebibliography}{9}
;;;
;;;\bibitem{onlisp}
;;;  Paul Graham
;;;  \emph{On Lisp},
;;;  Prentice Hall, New Jersey,
;;;  1994.
;;;
;;;\bibitem{ansicl}
;;;  Paul Graham
;;;  \emph{ANSI Common Lisp},
;;;  Prentice Hall, New Jersey,
;;;  1996.
;;;
;;;\bibitem{taocp}
;;;  Donald E. Knuth
;;;  \emph{The Art Of Computer Programming, Volume 1},
;;;  Addison Wesley, Massachusetts,
;;;  Third Edition,
;;;  1997.
;;;
;;;\bibitem{hmu2001}
;;;  John E. Hopcroft, Rajeev Motwani, Jeffrey D. Ullman
;;;  \emph{Introduction to Automata Theory, Languages, and Computation},
;;;  Addison Wesley, Massachusetts,
;;;  Second Edition,
;;;  2001.
;;;
;;;\bibitem{ss}
;;;  Brian Harvey, Matthew Wright
;;;  \emph{Simply Scheme - Introducing Computer Science},
;;;  The MIT Press, Massachusetts,
;;;  Second Edition,
;;;  2001.
;;;\bibitem{sicp}
;;;  Harold Abelon, Gerald Jay Sussman, Julie Sussma
;;;  \emph{Structure and Interpretation of Computer Programs},
;;;  The MIT Press, Massachusetts,
;;;  Second Edition,
;;;  1996.
;;;\bibitem{schemeprogramminglanguage}
;;;  R. Kent Dybvig
;;;  \emph{The Scheme Programming Language},
;;;  The MIT Press, Massachusetts,
;;;  Third Edition,
;;;  2003.
;;;\bibitem{littleschemer}
;;;  Daniel P. Friedman, Matthias Felleisen
;;;  \emph{The Scheme Programming Language},
;;;  The MIT Press, Massachusetts,
;;;  Fourth Edition,
;;;  1996.
;;;\bibitem{calculi}
;;;  Alonzo Church
;;;  \emph{The Calculi of Lambda-Conversion},
;;;  Princeton University Press, New Jersey,
;;;  Second Printing,
;;;  1951.
;;;
;;;\bibitem{setf}
;;;  http://okmij.org/ftp/Scheme/setf.txt .
;;;
;;;\bibitem{evalduringmacroexpansion}
;;;  https://mercure.iro.umontreal.ca/pipermail/gambit-list/2012-April/005917.html

;;;\end{thebibliography}
;;; \printindex

;;;\end{document}  %End of document.
