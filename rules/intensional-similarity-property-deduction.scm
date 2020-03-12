;; Rule expressing that if atom A and B are intensionally similar, and
;; A has some property P, and is P is cohesive then B is likely to
;; have property P.
;;
;; IntensionalSimilarity
;;   G
;;   H
;; Member
;;   G
;;   P
;; Evaluation
;;   Prediction "cohesive"
;;   P
;; |-
;; Member
;;   H
;;   P

(define intensional-similarity-property-deduction-rule
  (let* ((G (Variable "$G"))
         (H (Variable "$H"))
         (P (Variable "$P"))
         (GeneType (Type 'GeneNode))
         (ConceptType (Type 'ConceptNode)))
    (Bind
      (VariableSet
        (TypedVariable G GeneType)
        (TypedVariable H GeneType)
        (TypedVariable P ConceptType))
      (Present
        (IntensionalSimilarity
          G
          H)
        (Member
          G
          P)
        (Evaluation
          (Predicate "cohesive")
          P))
      (ExecutionOutputLink
        (GroundedSchema "scm: intensional-similarity-property-deduction")
        (List
          ;; Conclusion
          (Member
            H
            P)
          ;; Premises
          (IntensionalSimilarity
            G
            H)
          (Member
            G
            P)
          (Evaluation
            (Predicate "cohesive")
            P))))))

;; TODO: improve formula
(define (intensional-similarity-property-deduction conclusion . premises)
  ;; (cog-logger-debug "intensional-similarity-property-deduction conclusion=~a premises=~a"
  ;;                   conclusion premises)
  (if (= (length premises) 3)
      (let* ((ii (car premises))
             (mbr (cadr premises))
             (coh (caddr premises))
             (s (* (cog-mean ii) (cog-mean mbr)))
             (c (* (cog-confidence ii) (cog-confidence mbr) (cog-mean coh)))
             (tv (stv s c)))
        (cog-merge-hi-conf-tv! conclusion tv))))

(define intensional-similarity-property-deduction-rule-name
  (DefinedSchemaNode "intensional-similarity-property-deduction-rule"))
(DefineLink intensional-similarity-property-deduction-rule-name
  intensional-similarity-property-deduction-rule)
