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
(define ss 0.01)                         ; Subsampled portion of the KBs
(define mi 1000)                      ; Maximum number of iterations
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

;; Add Mike's GO aging extract
(define relates-to-aging-facts (load-kb "facts/relates-to-aging.scm"))

(cog-logger-debug "relates-to-aging-facts = ~a" relates-to-aging-facts)

;; Create filter to discard facts not related to aging.
;;
;; TODO: consider mixed transitive closure.
(define go-categories-related-to-aging (map gdr relates-to-aging-facts))
(define (not-related-to-aging? x)
  (let* ((nodes (cog-get-all-nodes x))
         (nodes-related-to-aging (lset-intersection equal?
                                                    nodes
                                                    go-categories-related-to-aging)))
    (null? nodes-related-to-aging)))

;; Load kbs
(define db-lst (load-kbs (list
                          ;; Obtained from running preprocess-kbs.scm
                          "results/preprocess-kbs-rs=0-ss=1-mi=12-cp=10-fra=t.scm")
                         #:subsmp ss
                         #:filter-out not-related-to-aging?))

(cog-logger-debug "db-lst = ~a" db-lst)

;; ;; Load PLN
;; (pln-load #:rule-base 'empty)
;; (pln-add-rule-by-name "intensional-similarity-direct-introduction-rule")

;; ;; 1. Produce intensional similarity links between GO concepts.

;; ;; Run backward chainer to produce intensional similarity links.
;; (define X (Variable "$X"))
;; (define Y (Variable "$Y"))
;; (define target (IntensionalSimilarity X Y))
;; (define results-iss (pln-bc target
;;                             #:vardecl vardecl
;;                             #:maximum-iterations mi
;;                             #:complexity-penalty cp))

;; (cog-logger-debug "results-iss = ~a" results-iss)

;; ;; 2. Find similar genes that relates to aging by intensional
;; ;; similarity of other genes retating to aging.

;; ;; Add extra specialized rules
;; (pln-load-from-path "rules/similar-genes-relating-to-aging.scm")
;; (pln-add-rule-by-name "similar-genes-relating-to-aging-rule")
;; (pln-load-from-path "rules/transfer-intensional-similarity-to-member.scm")
;; (pln-add-rule-by-name "transfer-intensional-similarity-to-member-rule")
;; (pln-load-from-path "rules/transfer-relates-to-aging-to-member.scm")
;; (pln-add-rule-by-name "transfer-relates-to-aging-to-member-rule")

;; ;; 3. Run backward chainer on relates-to-aging query
;; (define GT (Type 'GeneNode))
;; (define vardecl (TypedVariable X GT))
;; (define (mk-relates-to-aging x) (Evaluation (Predicate "relates-to-aging") x))
;; (define target (mk-relates-to-aging X))
;; (define results-rta (pln-bc target
;;                             #:vardecl vardecl
;;                             #:maximum-iterations mi
;;                             #:complexity-penalty cp))

;; (cog-logger-debug "results-rta = ~a" results-rta)
