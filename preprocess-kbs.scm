;; Preprocess Kbs before running any reasoning.
;;
;; 1. Translate Inheritance to SubSet
;;
;; Inheritance
;;   A
;;   B
;; |-
;; SubSet
;;   A
;;   B
;;
;; where A and B are GO categories.
;;
;; 2. Infer closure of GO annotation
;;
;; Member
;;   A
;;   B
;; SubSet
;;   B
;;   C
;; |-
;; Member 
;;   A
;;   C
;;
;; 3. Add TVs to all
;;
;; Member (stv 1 1)
;;   A
;;   B
;;
;; where A is a Gene and B is a GO category.
;;
;; 4. Add TVs to all
;;
;; SubSet (stv 1 1)
;;   A
;;   B
;;
;; where A and B are GO categories.
;;
;; 5. Calculate TVs to all
;;
;; Concept A <strength=M/N, count=N>
;;
;; where A is a GO category, N is the total number of genes, and M is
;; the total number of members of A.
;;
;; 6. Infer inverse subset links, based on inversion
;;
;; Subset A B
;; |-
;; Subset B A

;; Parameters
(define rs 0)                           ; Random seed
(define ss 1)                         ; Subsampled portion of the KBs
(define mi 20)                      ; Maximum number of iterations
(define cp 10)                           ; Complexity penalty
(define fra #t)                          ; Whether rules are fully applied

;; Load modules
(use-modules (opencog randgen))
(use-modules (opencog logger))
(use-modules (opencog ure))
(use-modules (opencog pln))
(use-modules (opencog bioscience))
(load "bio-as-utils.scm")

;; Parameters string
(define param-str (string-append
                   "-rs=" (number->string rs)
                   "-ss=" (number->string ss)
                   "-mi=" (number->string mi)
                   "-cp=" (number->string cp)
                   "-fra=" (bool->string fra)))

(define log-filename (string-append "preprocess-kbs" param-str ".log"))

;; (cog-logger-set-timestamp! #f)
;; (cog-logger-set-sync! #t)
(cog-logger-set-level! "debug")
(cog-logger-set-filename! log-filename)
;; (ure-logger-set-timestamp! #f)
;; (ure-logger-set-sync! #t)
(ure-logger-set-level! "debug")
(ure-logger-set-filename! log-filename)

;; Load KBs to reason on
(define db-lst (load-kbs (list "kbs/GO.scm"
                               "kbs/GO_annotation.scm")
                         #:subsmp ss
                         #:filter-out (lambda (x)
                                        (or (GO_term? x)
                                            (inheritance-GO_term? x)))))

;; Helpers
(define ConceptT (Type "ConceptNode"))
(define GeneT (Type "GeneNode"))
(define X (Variable "$X"))
(define Y (Variable "$Y"))

;; Run FC to
;;
;; 1. Translate Inheritance to SubSet
;; 2. Infer closure of GO annotation

;; Load PLN
(pln-load #:rule-base 'empty)
(pln-load-from-path "rules/translation.scm")
(pln-load-from-path "rules/transitivity.scm")
(pln-add-rule-by-name "present-inheritance-to-subset-translation-rule")
(pln-add-rule-by-name "present-mixed-member-subset-transitivity-rule")

;; Run forward chainer
(define vardecl (VariableSet
                  (TypedVariable X ConceptT)
                  (TypedVariable Y ConceptT)))
(define source (Inheritance X Y))
(define results (pln-fc source
                        #:vardecl vardecl
                        #:maximum-iterations mi
                        #:complexity-penalty cp
                        #:fc-full-rule-application fra))

;; Add true TVs to all results (3. and 4.)
(define results-lst-with-tvs
  (map (lambda (x) (cog-set-tv! x (stv 1 1))) (cog-outgoing-set results)))

;; Run FC to
;;
;; 5. Calculate TVs to all GO categories
;; 6. Infer inverse subset links, based on inversion

;; Reload PLN with a different rule set
(pln-rm-all-rules)

;; TODO

;; Write results in file
(define scm-filename (string-append "results/preprocess-kbs" param-str ".scm"))
(write-atoms-to-file scm-filename results-lst-with-tvs)

