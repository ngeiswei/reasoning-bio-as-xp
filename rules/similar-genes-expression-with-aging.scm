;; Rule to expressing that if gene expression of G increase
;; (resp. decrease) with aging and gene H is intensionally similar to
;; G, then gene expression of H also increase (resp. decrease) with
;; aging.
;;
;; Member
;;   G
;;   <expression-with-aging>
;; IntensionalSimilarity
;;   G
;;   H
;; |-
;; Evaluation
;;   H
;;   <expression-with-aging>
;;
;; where <expression-with-aging> is a concept containing genes such
;; that their expression increases (resp. decreases) with aging.

(define (gen-similar-genes-expression-with-aging-rule expression-with-aging-cpt)
  (Bind
    (VariableSet
      (TypedVariable
        (Variable "$g")
        (Type 'GeneNode))
      (TypedVariable
        (Variable "$h")
        (Type 'GeneNode)))
    (Present
      (Member
        (Variable "$g")
        expression-with-aging-cpt)
      (IntensionalSimilarity
        (Variable "$g")
        (Variable "$h")))
    (ExecutionOutputLink
      (GroundedSchema "scm: similar-genes-expression-with-aging")
      (List
        ;; Conclusion
        (Member
          (Variable "$h")
          expression-with-aging-cpt)
        ;; Premises
        (Member
          (Variable "$g")
          expression-with-aging-cpt)
        (IntensionalSimilarity
          (Variable "$g")
          (Variable "$h"))))))

;; TODO: improve formula
(define (similar-genes-expression-with-aging conclusion . premises)
  ;; (cog-logger-debug "similar-genes-expression-with-aging conclusion=~a premises=~a"
  ;;                   conclusion premises)
  (if (= (length premises) 2)
      (cog-merge-hi-conf-tv! conclusion (stv 0.55 0.55))))

(define similar-genes-increase-expression-with-aging-rule-name
  (DefinedSchemaNode "similar-genes-increase-expression-with-aging-rule"))
(DefineLink similar-genes-increase-expression-with-aging-rule-name
  (gen-similar-genes-expression-with-aging-rule
    (ConceptNode "HAGR increased expression-with-aging GeneSet")))

(define similar-genes-decrease-expression-with-aging-rule-name
  (DefinedSchemaNode "similar-genes-decrease-expression-with-aging-rule"))
(DefineLink similar-genes-decrease-expression-with-aging-rule-name
  (gen-similar-genes-expression-with-aging-rule
    (ConceptNode "HAGR decreased expression-with-aging GeneSet")))
