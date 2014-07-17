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

;; showing off the unit test framework
(with-tests
 ;; this definition happens at compile-time and runtime
 (define foobarbaz 5) 
 ;; the following lines only happen at compile time.
 ;; therefore, any mutations to foobarbaz are not reflected in runtime
 (equal? (* 2 foobarbaz) 10)
 (begin
   (set! foobarbaz 20)
   (equal? (* 2 foobarbaz) 40))
 (equal? foobarbaz 20))
;; if the following line were uncommented, it would print 5
;;(pp foobarbaz)




(with-tests
 (define-macro (when bool statement)
   `(if ,bool
	,statement
	#f))
 (equal? (when 5 3) 3)
 (equal? (when #f 3) #f))


;; list functions

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

(with-tests
 (define (filter p? lst)
   (define (filterPrime lst acc)
     (cond ((null? lst) acc)
	   (else (let ((head (car lst)))
		       (filterPrime (cdr lst) (if (p? head)
						  (cons head acc)
						  acc))))))
   (reverse! (filterPrime lst '())))
 (equal? (filter (lambda (x) (not (= 4 (expt x 2))))
		 '(1 2 3 4 5 -2))
	 '(1 3 4 5))
 (equal? (filter (lambda (x) (= 4 (expt x 2)))
		 '(1 2 3 4 5 -2))
	 '(2 -2)))
 
(with-tests
 (define (fold-left fn initial lst)
   (define (fold-leftPrime acc lst)
     (if (null? lst) 
	 acc
	 (fold-leftPrime (fn acc 
			     (car lst))
			 (cdr lst))))
   (fold-leftPrime initial lst))
 (equal? (fold-left + 0 '())
 	 0)
 (equal? (fold-left + 0 '(1))
 	 1)
 (equal? (fold-left + 0 '(1 2))
 	 3)
 (equal? (fold-left + 0 '(1 2 3 4 5 6))
	 21))


(with-tests
 (define (fold-right fn initial lst)
   (define (fold-rightPrime acc lst)
     (if (null? lst)
	 acc
	 (fn (car lst)
	     (fold-rightPrime acc (cdr lst)))))
   (fold-rightPrime initial lst))
 (equal? (fold-right - 0 '())
	 0)
 (equal? (fold-right - 0 '(1 2 3 4))
	 -2)
 (equal? (fold-right - 0 '(2 2 5 4))
 	 1))

