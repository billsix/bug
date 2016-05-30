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
