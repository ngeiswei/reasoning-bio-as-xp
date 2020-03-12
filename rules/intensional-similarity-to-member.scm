;; Rule to transfer intensional similarity between concepts to their
;; members
;;
;; IntensionalSimilarity
;;   A
;;   B
;; Member
;;   E
;;   A
;; Member
;;   F
;;   B
;; |-
;; IntensionalSimilarity
;;   E
;;   F

(define intensional-similarity-to-member-rule
  (let* ((A (Variable "$A"))
         (B (Variable "$B"))
         (E (Variable "$E"))
         (F (Variable "$F")))
    (Bind
      (VariableSet A B E F)
      (Present
        (IntensionalSimilarity A B)
        (Member E A)
        (Member F B))
      (ExecutionOutputLink
        (GroundedSchema "scm: intensional-similarity-to-member")
        (List
          ;; Conclusion
          (IntensionalSimilarity E F)
          ;; Premises
          (IntensionalSimilarity A B)
          (Set                          ; Wrap in set because the order does not matter
            (Member E A)
            (Member F B)))))))

(define (intensional-similarity-to-member conclusion . premises)
  ;; (cog-logger-debug "intensional-similarity-to-member conclusion=~a . premises=~a"
  ;;                   conclusion premises)
  (if (= (length premises) 2)
      (let* ((ii (car premises))
             (s (cog-mean ii))
             (c (* 0.2 (cog-confidence ii)))
             (tv (stv s c)))
      (cog-merge-hi-conf-tv! conclusion tv))))

(define intensional-similarity-to-member-rule-name
  (DefinedSchemaNode "intensional-similarity-to-member-rule"))
(DefineLink intensional-similarity-to-member-rule-name
  intensional-similarity-to-member-rule)
