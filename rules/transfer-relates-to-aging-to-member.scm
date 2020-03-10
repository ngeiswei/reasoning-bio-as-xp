;; Rule to transfer relates-to-aging relation over concepts to their
;; members.
;;
;; Evaluation
;;   Predicate "relates-to-aging"
;;   C
;; Member
;;   E
;;   C
;; |-
;; Evaluation
;;   Predicate "relates-to-aging"
;;   E

(define transfer-relates-to-aging-to-member-rule
  (let* ((relates-to-aging (Predicate "relates-to-aging"))
         (C (Variable "$C"))
         (E (Variable "$E")))
    (Bind
      (VariableSet
        (TypedVariable
          C
          (Type 'ConceptNode))
        (TypedVariable
          E
          (Type 'GeneNode)))
      (Present
        (Evaluation relates-to-aging C)
        (Member E C))
      (ExecutionOutputLink
        (GroundedSchema "scm: transfer-relates-to-aging-to-member")
        (List
          ;; Conclusion
          (Evaluation relates-to-aging E)
          ;; Premises
          (Evaluation relates-to-aging C)
          (Member E C))))))

(define (transfer-relates-to-aging-to-member conclusion . premises)
  ;; (cog-logger-debug "transfer-relates-to-aging-to-member conclusion=~a . premises=~a"
  ;;                   conclusion premises)
  (if (= (length premises) 2)
      (cog-merge-hi-conf-tv! conclusion (cog-tv (car premises)))))

(define transfer-relates-to-aging-to-member-rule-name
  (DefinedSchemaNode "transfer-relates-to-aging-to-member-rule"))
(DefineLink transfer-relates-to-aging-to-member-rule-name
  transfer-relates-to-aging-to-member-rule)
