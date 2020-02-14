;; Crisp rules about translating a link into another link

(load-from-path "rules/rule-utils.scm")

;; Helpers
(define ConceptT (Type "ConceptNode"))
(define GeneT (Type "GeneNode"))

;; Inheritance to Subset
(define present-inheritance-to-subset-translation-rule
  (gen-present-link-translation-rule InheritanceLink SubsetLink ConceptT))
(define present-inheritance-to-subset-translation-rule-name
  (DefinedSchemaNode "present-inheritance-to-subset-translation-rule"))
(DefineLink present-inheritance-to-subset-translation-rule-name
  present-inheritance-to-subset-translation-rule)
