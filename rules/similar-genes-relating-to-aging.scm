;; Mock up rule to test that if gene g relates to aging and gene h is
;; intensionally similar to g, then h relates to again too.
;;
;; Evaluation
;;   <pred>
;;   G
;; IntensionalSimilarity
;;   G
;;   H
;; |-
;; Evaluation
;;   <pred>
;;   H
;;
;; where <pred> can be any predicate expressing relation to aging.

(define (gen-similar-genes-relating-to-aging-rule pred)
  (Bind
    (VariableSet
      (TypedVariable
        (Variable "$g")
        (Type 'GeneNode))
      (TypedVariable
        (Variable "$h")
        (Type 'GeneNode)))
    (Present
      (Evaluation
        pred
        (Variable "$g"))
      (IntensionalSimilarity
        (Variable "$g")
        (Variable "$h")))
    (ExecutionOutputLink
      (GroundedSchema "scm: similar-genes-relating-to-aging")
      (List
        ;; Conclusion
        (Evaluation
          pred
          (Variable "$h"))
        ;; Premises
        (Evaluation
          pred
          (Variable "$g"))
        (IntensionalSimilarity
          (Variable "$g")
          (Variable "$h"))))))

;; TODO
(define (similar-genes-relating-to-aging conclusion . premises)
  ;; (cog-logger-debug "similar-genes-relating-to-aging conclusion=~a premises=~a"
  ;;                   conclusion premises)
  (if (= (length premises) 2)
      (cog-merge-hi-conf-tv! conclusion (stv 0.55 0.55))))

(define similar-genes-relating-to-aging-rule-name
  (DefinedSchemaNode "similar-genes-relating-to-aging-rule"))
(DefineLink similar-genes-relating-to-aging-rule-name
  (gen-similar-genes-relating-to-aging-rule (Predicate "relates-to-aging")))
