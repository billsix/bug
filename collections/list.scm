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
