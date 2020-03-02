;; Facts about (Predicate "interacts_with")
;;
;; Note: actually wrap these facts into rules (in the rules folder),
;; for better inference traceability.

(define G (Variable "$G"))
(define H (Variable "$H"))
(define GeneT (Type "GeneNode"))

(define (interacts_with-eval X Y)
  (Evaluation
    (Predicate "interacts_with")
    (List X Y)))

;; interacts_with is symmetric
(define interacts_with_symmetric
  (ImplicationScope (stv 1 1)
    (VariableList
      (TypedVariable G GeneT)
      (TypedVariable H GeneT))
    (interacts_with-eval G H)
    (interacts_with-eval H G)))
