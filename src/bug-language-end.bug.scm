;;; %Copyright 2014-2016 - William Emerison Six
;;; %All rights reserved
;;; %Distributed under LGPL 2.1 or Apache 2.0
;;;
;;;
;;; \setcounter{part}{2}
;;; \part{Finishing Compilation}
;;; \chapter{Closing Generated Files}
;;;  \label{sec:closefiles}
;;;
;;; The contents of this part are in ``src/bug-language-end.bug.scm''
;;;
;;; \begin{code}
;;;
(at-compile-time
 {begin
   (display
    "
     (##namespace (\"\"))"
    libbug-macros-file)})
;;;
;;;
(at-compile-time
 {begin
   (force-output libbug-headers-file)
   (close-output-port libbug-headers-file)
   (force-output libbug-macros-file)
   (close-output-port libbug-macros-file)})
;;;\end{code}
