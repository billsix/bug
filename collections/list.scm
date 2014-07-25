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


;; identity should be defined somewhere else, not in list.scm
(with-test
 (define (identity x) x)
 (equal? "foo" (identity "foo")))
;; thish should be defined somewhere else too
(with-test
 (define (noop ) 'noop)
 (equal? (noop) 'noop))


;; when
;;   when the bool value is non-false, return the value of statement.
;;   when the bool value is false, return false
;; TODO - statement needs to be wrapped in a begin
(with-tests
 (define-macro (when bool statement)
   `(if ,bool
	,statement
	#f))
 (equal? (when 5 3) 3)
 (equal? (when #f 3) #f))


;; reverse!
;;   reverse! :: [a] -> [a]
;;   reverses the list, possibly destructively.
(with-tests
 (define (reverse! lst)
   ;; reversePrime assumes that lst is not null
   (define (reversePrime! lst prev)
     (cond ((null? (cdr lst))
	    (set-cdr! lst prev)
	    lst)
	   (else
	    (let ((rest (cdr lst)))
	      (set-cdr! lst prev)
	      (reversePrime! rest lst)))))
   ;; ensure that reversePrime's constraints are preserved
   (if (null? lst) 
       '()
       (reversePrime! lst '())))
 (equal? (reverse! '())
	 '())
 (equal? (reverse! '(1 2 3 4 5 6))
	 '(6 5 4 3 2 1)))

;; first :: [a] -> Optional (() -> b) -> Either a b
;;   first returns the first element of the list, 'noop if the list is empty and no
;;   thunk is passed
(with-tests
 (define (first lst #!key (onNull noop))
   (if (null? lst) 
       (onNull)
       (car lst)))
 (equal? (first '())
	 'noop)
 (equal? (first '(1 2 3))
	 1)
 (equal? (first '(2 3 1 1 1))
	 2)
 (equal? (first '() onNull: (lambda () 5))
	 5)
 (equal? (first '(1 2 3) onNull: (lambda () 5))
	 1))

;; but-first :: [a] -> Optional (() -> b) -> Either [a] b
;;   but-first returns all of the elements of the list, except for the first
(with-tests
 (define (but-first lst #!key (onNull noop))
   (if (null? lst)
       (onNull)
       (cdr lst)))
 (equal? (but-first '()) 
	 'noop)
 (equal? (but-first '() onNull: (lambda () 5)) 
	 5)
 (equal? (but-first '( 1 2 3))
	 '(2 3)))

;;  last :: [a] -> Optional (() -> b) -> Either a b
;;    last returns the last element of the list
(with-tests
 (define (last lst #!key (onNull noop))
   (define (last-Prime lst)
     (if (null? (cdr lst)) 
	 (car lst)
	 (last (cdr lst))))
   (if (null? lst)
       (onNull)
       (last-Prime lst)))
 (equal? (last '()) 
	 'noop)
 (equal? (last '(1))
	 1)
 (equal? (last '(1 2))
	 2)
 (equal? (last '() onNull: (lambda () 5))
	 5)
 (equal? (last '(1) onNull: (lambda () 5))
	 1))

;; filter
;;   filter :: (a -> Bool) -> [a] -> [a]
;;   return a new list, consisting only the elements where the predicate p?
;;   returns true
(with-tests
 (define (filter p? lst)
   (define (filterPrime lst acc)
     (if (null? lst) 
	 acc
	 (let ((head (car lst)))
	   (filterPrime (cdr lst) (if (p? head)
				      (cons head acc)
				      acc)))))
   (reverse! (filterPrime lst '())))
 (equal? (filter (lambda (x) (not (= 4 (expt x 2))))
		 '(1 2 3 4 5 -2))
	 '(1 3 4 5))
 (equal? (filter (lambda (x) (= 4 (expt x 2)))
		 '(1 2 3 4 5 -2))
	 '(2 -2)))

;; remove
;;   remove :: a -> [a] -> [a]
;;   returns a new list with all occurances of x removed
(with-tests
 (define (remove x lst)
   (filter (lambda (y) (not (equal? x y)))
	   lst))
 (equal? (remove 5 '(1 5 2 5 3 5 4 5 5))
	 '(1 2 3 4)))


;; fold-left
;;    fold-left :: (a -> b -> a) -> a -> [b] -> a
;;    reduce the list to a scalar by applying the reducing function repeatedly,
;;    starting from the "left" side of the list
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

;; scan-left :: (a -> b -> a) -> a -> [b] -> [a]
;;   scan-left is like fold-left, but every intermediate value
;;   of fold-left's acculumalotr is put onto a list, which
;;   is the value of scan-left
(with-tests
 (define (scan-left fn initial lst)
   (define (scan-leftPrime acc-list lst)
     (if (null? lst)
	 (reverse! acc-list)
	 (let ((newacc (fn (first acc-list)
			   (car lst))))
	   (scan-leftPrime (cons newacc acc-list)
			   (cdr lst)))))
   (scan-leftPrime (list initial) lst))
 (equal? (scan-left + 0 '())
	 '(0))
 (equal? (scan-left + 0 '( 1 1 1 2 20 30))
	 '(0 1 2 3 5 25 55)))



;; fold-right
;;    fold-right :: (b -> a -> a) -> a -> [b] -> a
;;    reduce the list to a scalar by applying the reducing function repeatedly,
;;    starting from the "right" side of the list
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

;; flatmap
;;   flatmap :: (a -> [b]) -> [a] -> [b]
(with-tests
 (define (flatmap fn lst)
   (fold-left append '() (map fn lst)))
 (equal? (flatmap (lambda (x) (list x x x))
		  '(1 2 3 4 5))
	 '(1 1 1 2 2 2 3 3 3 4 4 4 5 5 5))
 (equal? (flatmap (lambda (x) (list x
				    (+ x 1)
				    (+ x 2)))
		  '(10 20 30 40))
	 '(10 11 12 20 21 22 30 31 32 40 41 42)))

;; enumerate-interval
;;   enumerate-interval :: (Num a) => a -> a -> Optional a -> a
(with-tests
 (define (enumerate-interval low high #!key (step 1))
   (if (> low high)
       '()
       (cons low (enumerate-interval (+ low step) high step: step))))
 (equal? (enumerate-interval 1 10) 
	 '(1 2 3 4 5 6 7 8 9 10))
 (equal? (enumerate-interval 1 10 step: 2) 
	 '(1 3 5 7 9)))

;; iota - from common lisp
;;   iota :: (Num a) => a -> Optional a -> Optional a -> a
(with-tests
 (define (iota n #!key (start 0) (step 1)) 
   (enumerate-interval start n step: step))
 (equal? (iota 5 start: 0)
	 '(0 1 2 3 4 5))
 (equal? (iota 5 start: 2 step: (/ 3 2))
	 '(2 7/2 5)))


;; permutations
;;   permutations :: [a] -> [[a]]
;;   returns all permutations of the list
(with-tests
 (define (permutations lst)
   (if (null? lst)
       (list '())
       (flatmap (lambda (x) 
		  (map (lambda (y) (cons x y))
		       (permutations (remove x lst))))
		lst)))
 (equal? (permutations '())
	 '(()))
 (equal? (permutations '(1))
	 '((1)))
 (equal? (permutations '(1 2))
	 '((1 2) (2 1)))
 (equal? (permutations '(1 2 3))
	 '((1 2 3) (1 3 2) (2 1 3) (2 3 1) (3 1 2) (3 2 1))))

;; sublists
;;   sublists :: [a] -> [[a]]
;;   Returns a list of every sub-list
(with-tests
 (define (sublists lst)
   (if (null? lst)
       '()
       (cons lst (sublists (cdr lst)))))
 (equal? (sublists '())
	 '())
 (equal? (sublists '(1))
	 '((1)))
 (equal? (sublists '(1 2))
	 '((1 2) (2)))
 (equal? (sublists '(1 2 3))
	 '((1 2 3) (2 3) (3))))
