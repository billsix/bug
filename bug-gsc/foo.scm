(define foo
  [(+ 1 2)])

(define bar
  {+ 1 2})

(define baz
  [|a b| (+ a b)])

(define aoeu
  [|x|
   [|y z|
    (- y z x)]])


(define (while thunk body)
  (if (thunk)
      (begin
	(body)
	(while thunk body))
      #f))


(define a 5)

(while {< a 10}
       [(pp a)
	(set! a (+ a 1))])
