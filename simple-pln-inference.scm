;; Simple PLN inference, from Ben's slack message:
;;
;; Simple initial inferences, not needing expression data:
;; e.g. Variant v1 and variant V2 imply longevity; v1 pertains to gene
;; G1 and V2 pertains to gene G2; G1 is in GO category GO7 and G2 is
;; in Go category GO9 ; GO7 intersects a lot with GO15 and GO9
;; intersects a lot with GO22; GO15 and Go22 are known to imply
;; longevity.

;; Parameters
(define rs 0)                           ; Random seed
(define ss 1)                         ; Subsampled portion of the KBs
(define mi 100000)                      ; Maximum number of iterations
(define cp 1)                           ; Complexity penalty

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
                   "-cp=" (number->string cp)))

(define log-filename
  (string-append "log/simple-pln-inference" param-str ".log"))

;; (cog-logger-set-timestamp! #f)
;; (cog-logger-set-sync! #t)
(cog-logger-set-level! "debug")
(cog-logger-set-filename! log-filename)
;; (ure-logger-set-timestamp! #f)
;; (ure-logger-set-sync! #t)
(ure-logger-set-level! "debug")
(ure-logger-set-filename! log-filename)

;; Use GO namespace as extra pattern for intensional reasoning
;;
;; New interaction evaluation base on intensiona similarity

;; Load kb restricted to aging
(define aging-db (load-kbs (list
                            ;; Obtained from running preprocess-kbs.scm
                            "results/preprocess-kbs-aging-rs=0-ss=1-mi=1000-cp=1.scm")))
;; (cog-logger-debug "aging-db = ~a" aging-db)

;; Load empty PLN
(pln-load 'empty)

;; Definitions
(define X (Variable "$X"))
(define GT (Type 'GeneNode))
(define CT (Type 'ConceptNode))

;; 1. Infer all the genes that relate to aging
(pln-load-from-path "rules/transfer-relates-to-aging-to-member.scm")
(pln-add-rule-by-name "transfer-relates-to-aging-to-member-rule")
(define source (Evaluation (Predicate "relates-to-aging") X))
(define vardecl (TypedVariable X CT))
(define gra-results (pln-fc source
                            #:vardecl vardecl
                            #:maximum-iterations mi
                            #:complexity-penalty cp))
(cog-logger-debug "gra-results = ~a" gra-results)

;; Write results in file (so we don't need to recompute it next time
(define scm-filename (string-append "results/genes-related-to-aging" param-str ".scm"))
(write-atoms-to-file scm-filename (cog-outgoing-set gra-results))

;; 2. Infer that if some gene relates to aging and is similar to
;;    another gene, then that one relates to aging too.

;; Load extra rules
(pln-add-rule-by-name "intensional-similarity-direct-introduction-rule")
(pln-load-from-path "rules/similar-genes-relating-to-aging.scm")
(pln-add-rule-by-name "similar-genes-relating-to-aging-rule")
(pln-load-from-path "rules/intensional-similarity-to-member.scm")
(pln-add-rule-by-name "intensional-similarity-to-member-rule")

;; Load full kb in order to infer new genes related to aging
(define full-db (load-kbs (list
                           "results/preprocess-kbs-rs=0-ss=1-mi=12-cp=10-fra=t.scm")
                          #:subsmp ss))

;; Fetch all GO categories related to aging, with strength above zero,
;; to use them as sources
(define relates-to-aging-facts (load-kb "facts/relates-to-aging.scm"))
(define go-categories-related-to-aging (filter (lambda (x) (not (null-mean? x)))
                                               (map gdr relates-to-aging-facts)))
;; (cog-logger-debug "go-categories-related-to-aging = ~a" go-categories-related-to-aging)
(define trace-as (cog-new-atomspace))
(define sources (Set go-categories-related-to-aging))
(define final-results (pln-fc sources
                              #:maximum-iterations mi
                              #:complexity-penalty cp
                              #:trace-as trace-as))

(cog-logger-debug "final-results = ~a" final-results)

;; Write results in file
(define scm-fn (string-append "results/simple-pln-inference" param-str ".scm"))
(write-atoms-to-file scm-fn (cog-outgoing-set final-results))

;; Write trace in file
(cog-set-atomspace! trace-as)
(define scm-trace-fn (string-append "results/simple-pln-inference-trace" param-str ".scm"))
(write-atoms-to-file scm-trace-fn (cog-get-all-roots))
