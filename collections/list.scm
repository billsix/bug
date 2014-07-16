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


(define-macro (with-tests definition #!rest test)
  `(with-test ,definition (all? (list ,@test))))

(with-tests
 (define-macro (when bool statement)
   `(if ,bool
	,statement
	#f))
 (equal? (when 5 3) 3)
 (equal? (when #f 3) #f))

(with-tests
 (define (reverse! lst)
   (define (reversePrime! lst prev)
     (cond ((null? (cdr lst))
	    (set-cdr! lst prev)
	    lst)
	   (else
	    (let ((rest (cdr lst)))
	      (set-cdr! lst prev)
	      (reversePrime! rest lst)))))
   (cond ((null? lst) '())
	 (else (reversePrime! lst '()))))
 (equal? (reverse! '())
	 '())
 (equal? (reverse! '(1 2 3 4 5 6))
	 '(6 5 4 3 2 1)))
