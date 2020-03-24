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
;;
;; 7. Infer all attraction links, with their TVs
;;
;; Attraction
;;   <GO-category-A>
;;   <GO-category-A>
;;
;; The reason attraction links are pre-inferred is because in order to
;; carry out intensional reasoning attraction links must be fully
;; populated.

;; Parameters
(define rs 0)                           ; Random seed
(define ss 1)                         ; Subsampled portion of the KBs
(define mi 12)                      ; Maximum number of iterations
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

(define log-filename (string-append "log/preprocess-kbs" param-str ".log"))

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
(pln-load 'empty)
(pln-load-from-path "rules/translation.scm")
(pln-load-from-path "rules/transitivity.scm")
(pln-add-rule-by-name "present-inheritance-to-subset-translation-rule")
(pln-add-rule-by-name "present-subset-transitivity-rule")
(pln-add-rule-by-name "present-mixed-member-subset-transitivity-rule")

;; Run forward chainer
(define vardecl (VariableSet
                  (TypedVariable X ConceptT)
                  (TypedVariable Y ConceptT)))
(define source (Inheritance X Y))
(define results-mbrs (pln-fc source
                             #:vardecl vardecl
                             #:maximum-iterations mi
                             #:complexity-penalty cp
                             #:fc-full-rule-application fra))

;; Get old + newly inferred members
(define all-mbrs
  (append (cog-outgoing-set results-mbrs)
          (get-member-links 'GeneNode 'ConceptNode)))

;; Add true TVs to all results (3. and 4.)
(define results-lst-with-tvs
  (map (lambda (x) (cog-set-tv! x (stv 1 1))) all-mbrs))

;; 5. Calculate TVs of all GO categories
(define genes (get-genes))
(define go-categories (get-go-categories))
(define usize (length genes))           ; universe size
(define (concept-mean x) (exact->inexact (/ (get-cardinality x) usize)))
(define (concept-tv x) (stv (concept-mean x) (count->confidence usize)))
(define go-categories-with-tvs
  (map (lambda (x) (cog-set-tv! x (concept-tv x))) go-categories))

;; 6. Infer inverse subset links, based on inversion
(define go-subsets (get-go-subsets))
(define inversed-go-subsets (map true-subset-inverse go-subsets))
(define inversed-go-subsets-with-pos-tvs
  (filter gt-zero-mean-and-confidence? inversed-go-subsets))

;; 7. Infer all attraction links, with their TVs

;; Add required PLN rules
(pln-add-rule-by-name "subset-condition-negation-rule")
(pln-add-rule-by-name "subset-attraction-introduction-rule")

;; Run backward chainer to produce attraction links.
(define vardecl (VariableSet
                  (TypedVariable X ConceptT)
                  (TypedVariable Y ConceptT)))
(define target (Attraction X Y))
(define results-ats (pln-bc target
                            #:vardecl vardecl
                            #:maximum-iterations mi
                            #:complexity-penalty cp))

;; 8. Filter out relationships involving GO concepts with null mean
(define non-null-go-categories-with-tvs
  (filter non-null-mean? go-categories-with-tvs))
(define non-null-results-lst-with-tvs
  (filter all-nodes-non-null-mean? results-lst-with-tvs))
(define non-null-inversed-go-subsets-with-pos-tvs
  (filter all-nodes-non-null-mean? inversed-go-subsets-with-pos-tvs))
(define non-null-attractions
  (filter all-nodes-non-null-mean? (cog-outgoing-set results-ats)))

;; Write results in file
(define all-results (append non-null-go-categories-with-tvs
                            non-null-results-lst-with-tvs
                            non-null-inversed-go-subsets-with-pos-tvs
                            non-null-attractions))
(define scm-filename (string-append "results/preprocess-kbs" param-str ".scm"))
(write-atoms-to-file scm-filename all-results)
