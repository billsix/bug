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

(with-tests
 (define (filter p? lst)
   (define (filterPrime lst acc)
     (cond ((null? lst) acc)
	   (else (let ((head (car lst)))
		   (if (p? head)
		       (filterPrime (cdr lst) (cons head acc))
		       (filterPrime (cdr lst) acc))))))
   (reverse! (filterPrime lst '())))
 (equal? (filter (lambda (x) (not (= 4 (expt x 2))))
		 '(1 2 3 4 5 -2))
	 '(1 3 4 5))
 (equal? (filter (lambda (x) (= 4 (expt x 2)))
		 '(1 2 3 4 5 -2))
	 '(2 -2)))
 
(with-tests
 (define (foldl fn lst)
   (define (foldlPrime acc lst)
     (cond ((null? lst) acc)
	   (else (foldlPrime (fn acc (car lst))
			     (cdr lst)))))
   (cond ((null? lst) lst)
	 (else (foldlPrime (car lst) (cdr lst)))))
 (equal? (foldl + '())
	 '())
 (equal? (foldl + '(1))
	 1)
 (equal? (foldl + '(1 2))
	 3)
 (equal? (foldl + '(1 2 3 4 5 6))
	 21))


(with-test
 (define (foldr fn lst)
   (foldl (lambda (x acc) (fn acc x))
	  (reverse! lst)))
 (equal? (foldr - '(1 2 3 4))
	 -2))

