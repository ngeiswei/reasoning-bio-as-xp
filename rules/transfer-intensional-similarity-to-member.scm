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

(define transfer-intensional-similarity-to-member-rule
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
        (GroundedSchema "scm: transfer-intensional-similarity-to-member")
        (List
          ;; Conclusion
          (IntensionalSimilarity E F)
          ;; Premises
          (IntensionalSimilarity A B)
          (Member E A)
          (Member F B))))))

(define (transfer-intensional-similarity-to-member conclusion . premises)
  ;; (cog-logger-debug "transfer-intensional-similarity-to-member conclusion=~a . premises=~a"
  ;;                   conclusion premises)
  (if (= (length premises) 3)
      (cog-merge-hi-conf-tv! conclusion (cog-tv (car premises)))))

(define transfer-intensional-similarity-to-member-rule-name
  (DefinedSchemaNode "transfer-intensional-similarity-to-member-rule"))
(DefineLink transfer-intensional-similarity-to-member-rule-name
  transfer-intensional-similarity-to-member-rule)
