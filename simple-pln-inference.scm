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
(define mi 10000000)                      ; Maximum number of iterations
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

;; Load kbs
(define db-lst (load-kbs (list
                          ;; Obtained from running preprocess-kbs.scm
                          "results/preprocess-kbs-aging-rs=0-ss=1-mi=1000-cp=1.scm")
                         #:subsmp ss))

;; (cog-logger-debug "db-lst = ~a" db-lst)

;; Load PLN
(pln-load #:rule-base 'empty)
(pln-add-rule-by-name "intensional-similarity-direct-introduction-rule")

;; Add extra specialized rules
(pln-load-from-path "rules/similar-genes-relating-to-aging.scm")
(pln-add-rule-by-name "similar-genes-relating-to-aging-rule")
(pln-load-from-path "rules/transfer-intensional-similarity-to-member.scm")
(pln-add-rule-by-name "transfer-intensional-similarity-to-member-rule")
(pln-load-from-path "rules/transfer-relates-to-aging-to-member.scm")
(pln-add-rule-by-name "transfer-relates-to-aging-to-member-rule")

;; Define sources and run forward chainer on them
(define X (Variable "$X"))
(define Y (Variable "$Y"))
(define X-vardecl (TypedVariable X (Type 'ConceptNode)))
(define Y-vardecl (TypedVariable Y (Type 'ConceptNode)))
(define vardecl (VariableSet X-vardecl Y-vardecl))
(define sources X)
(define results (pln-fc sources
                        #:vardecl X-vardecl
                        #:maximum-iterations mi
                        #:complexity-penalty cp))

;; Write results in file
(define scm-filename (string-append "results/simple-pln-inference" param-str ".scm"))
(write-atoms-to-file scm-filename (cog-outgoing-set results))
