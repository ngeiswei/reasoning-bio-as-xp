;; Complex PLN inference, based on simple-pln-inference.scm but takes
;; into account gene expression, as well as promotes longevity, as
;; opposed to just relates to aging.

;; Parameters
(define rs 0)                           ; Random seed
(define ss 0.01)                         ; Subsampled portion of the KBs
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
  (string-append "log/complex-pln-inference" param-str ".log"))

;; (cog-logger-set-timestamp! #f)
;; (cog-logger-set-sync! #t)
(cog-logger-set-level! "debug")
(cog-logger-set-filename! log-filename)
;; (ure-logger-set-timestamp! #f)
;; (ure-logger-set-sync! #t)
(ure-logger-set-level! "debug")
(ure-logger-set-filename! log-filename)

;; Load kb restricted to aging
(define hagr-facts (load-kb "facts/hagr.scm"))
(define default-mbr-tv (stv 0.95 0.7654321))
(map (lambda (x) (cog-set-tv! x default-mbr-tv)) hagr-facts)

(cog-logger-debug "hagr-facts = ~a" hagr-facts)

;; 1. Get all genes related to aging according to hagr
(define hagr-genes (filter gene? (map gar hagr-facts)))

(cog-logger-debug "hagr-genes = ~a" hagr-genes)

;; 2. Get all GO categories these genes belong to

;; Load full kb in order to infer new genes related to aging
(define pp-db (load-kbs (list
                         "results/preprocess-kbs-rs=0-ss=1-mi=12-cp=10-fra=t-old.scm")
                        #:subsmp ss))

;; TODO
(define (hagr-gene? x) (member x hagr-genes))
(define (member-hagr-go? x) (and ;; x is a MemberLink
                                 (member? x)
                                 ;; its first argument is a hagr gene
                                 (hagr-gene? (gar x))
                                 ;; its second argument is a GO category
                                 (go? (gdr x))))
(define hagr-go-categories (map gdr (filter member-hagr-go? pp-db)))

(cog-logger-debug "hagr-go-categories = ~a" hagr-go-categories)

;; 3. Infer that if some gene relates to aging and is similar to
;;    another gene, then that one relates to aging too.

;; Load empty PLN 
(pln-load #:rule-base 'empty)

;; Definitions
(define X (Variable "$X"))
(define GT (Type 'GeneNode))
(define CT (Type 'ConceptNode))

;; 4. Infer that if some gene expression increase or decrease with
;;    aging and is similar to another gene, then that one also
;;    increase or decrease with aging.

;; Load extra rules
(pln-add-rule-by-name "intensional-similarity-direct-introduction-rule")
(pln-load-from-path "rules/similar-genes-expression-with-aging.scm")
(pln-add-rule-by-name "similar-genes-increase-expression-with-aging-rule")
(pln-add-rule-by-name "similar-genes-decrease-expression-with-aging-rule")
(pln-load-from-path "rules/transfer-intensional-similarity-to-member.scm")
(pln-add-rule-by-name "transfer-intensional-similarity-to-member-rule")

(define trace-as (cog-new-atomspace))
(define sources (Set hagr-go-categories))
(define final-results (pln-fc sources
                              #:maximum-iterations mi
                              #:complexity-penalty cp
                              #:trace-as trace-as))

(cog-logger-debug "final-results = ~a" final-results)

;; Write results in file
(define scm-filename (string-append "results/complex-pln-inference" param-str ".scm"))
(write-atoms-to-file scm-filename (cog-outgoing-set final-results))

;; Write trace in file
(cog-set-atomspace! trace-as)
(define scm-trace-filename (string-append "results/complex-pln-inference-trace" param-str ".scm"))
(write-atoms-to-file scm-trace-filename (cog-get-all-roots))
