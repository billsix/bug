;; Copyright 2014 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.0 or Apache 2.0


;; with-test
;;   Collocates a definiton with a test.  The test is run at compile-time.
(define-macro (with-test definition test)
  ;; only executed at compile time
  (eval `(begin
	   ,definition
	   (if (eval ,test)
	       'no-op
	       (begin
		 (pp "Test Failed")
		 (pp (quote ,test))
		 (pp (quote ,definition))
		 (error "Test Failed")))))
  ;;the actual macro expansion is just the definition
  definition)


;; all?
;;   all? :: [a] -> Bool
;;   Tests if all the elements in a list are non-false
(with-test
 (define (all? lst)
   (cond ((null? lst) #t)
	 ((not (car lst)) #f)
	 (else (all? (cdr lst)))))
 (all? ;; yes I am applying all? to test the definition of all?
  (list
   (all? (list))
   (not (all? (list #f)))
   (not (all? (list #t #f #t)))
   (all? (list #t #t #t)))))


;; with-tests
;;   Collocates a definition with a collection of tests.  Tests are
;;   run sequentially, and are expected to return true or false
(define-macro (with-tests definition #!rest test)
  `(with-test ,definition (all? (list ,@test))))

;; ;; showing off the unit test framework
;; (with-tests
;;  ;; this definition happens at compile-time and runtime
;;  (define foobarbaz 5) 
;;  ;; the following lines only happen at compile time.
;;  ;; therefore, any mutations to foobarbaz are not reflected in runtime
;;  (equal? (* 2 foobarbaz) 10)
;;  (begin
;;    (set! foobarbaz 20)
;;    (equal? (* 2 foobarbaz) 40))
;;  (equal? foobarbaz 20))
;; ;; if the following line were uncommented, it would print 5
;; ;;(pp foobarbaz)
