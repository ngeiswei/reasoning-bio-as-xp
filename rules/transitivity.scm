;; Crisp rules about transitivity of predicates or inheritance links

(load-from-path "rules/rule-utils.scm")

;; Helpers
(define ConceptT (Type "ConceptNode"))
(define GeneT (Type "GeneNode"))

;; Inheritance transitivity (deduction) rule
(define present-inheritance-transitivity-rule
  (gen-present-link-transitivity-rule InheritanceLink ConceptT))
(define present-inheritance-transitivity-rule-name
  (DefinedSchemaNode "present-inheritance-transitivity-rule"))
(DefineLink present-inheritance-transitivity-rule-name
  present-inheritance-transitivity-rule)

;; Subset transitivity (deduction) rule
(define present-subset-transitivity-rule
  (gen-present-link-transitivity-rule SubsetLink ConceptT))
(define present-subset-transitivity-rule-name
  (DefinedSchemaNode "present-subset-transitivity-rule"))
(DefineLink present-subset-transitivity-rule-name
  present-subset-transitivity-rule)

;; Mixed (PredicateNode "GO_regulates") and Inheritance transitivity rules
(define present-mixed-GO_regulates-inheritance-transitivity-rule
  (gen-present-mixed-predicate-link-transitivity-rule (Predicate "GO_regulates")
                                                      InheritanceLink
                                                      ConceptT ConceptT))
(define present-mixed-GO_regulates-inheritance-transitivity-rule-name
  (DefinedSchemaNode "present-mixed-GO_regulates-inheritance-transitivity-rule"))
(DefineLink present-mixed-GO_regulates-inheritance-transitivity-rule-name
  present-mixed-GO_regulates-inheritance-transitivity-rule)

;; Mixed (Member A B), (Subset B C) |- (Member A C)
(define present-mixed-member-subset-transitivity-rule
  (gen-present-mixed-link-transitivity-rule MemberLink
                                            SubsetLink
                                            GeneT ConceptT ConceptT))
(define present-mixed-member-subset-transitivity-rule-name
  (DefinedSchemaNode "present-mixed-member-subset-transitivity-rule"))
(DefineLink present-mixed-member-subset-transitivity-rule-name
  present-mixed-member-subset-transitivity-rule)
