;; Given files with mined patterns (conjunctions), reason to turn them
;; into Similarity or Inheritance relationships.

;; Parameters
(define rs 0)                           ; Random seed
(define ss 1)                         ; Subsampled portion of the KBs

;; Filename containing the mined patterns
(define mp-filename "results/miner-results-all.scm")

;; Load modules & utils
(use-modules (srfi srfi-1))
(use-modules (opencog randgen))
(use-modules (opencog logger))
(use-modules (opencog ure))
(use-modules (opencog miner))
(use-modules (opencog bioscience))
(use-modules (opencog pln))
(load "bio-as-utils.scm")

(define log-filename
  (string-append "opencog-pattern-to-relationship"
                 "-rs=" (number->string rs)
                 "-ss=" (number->string ss)
                 "-mp-filename=" (basename mp-filename ".scm")
                 ".log"))

;; (cog-logger-set-timestamp! #f)
;; (cog-logger-set-sync! #t)
(cog-logger-set-level! "debug")
(cog-logger-set-filename! log-filename)
;; (ure-logger-set-timestamp! #f)
;; (ure-logger-set-sync! #t)
(ure-logger-set-level! "debug")
(ure-logger-set-filename! log-filename)

;; Load KBs to reason on
(define db-lst (load-kbs (list "kbs/smpdb_gene.scm"
                               "kbs/GO.scm"
                               "kbs/GO_annotation.scm")
                         #:subsmp ss))

(cog-logger-debug "db-lst:\n~a" db-lst)

;; Load patterns
(define pattern-evaluations
  (load-pattern-evaluations mp-filename))

;; Extract GO and SMP concept pairs from the pattern evaluations
(define cps (map extract-GO-SMP-pair pattern-evaluations))

;; Create inheritance links for each pair and their reverse
(define (inh-from-pair p) (Inheritance (car p) (cadr p)))
(define (rev-inh-from-pair p) (Inheritance (cadr p) (car p)))
(define inhs (map inh-from-pair cps))
(define rev-inhs (map rev-inh-from-pair cps))
(define all-inhs (append inhs rev-inhs))

;; Load pln rules of interest
(pln-load #:rule-base 'empty)
(pln-add-rule-by-name "inheritance-direct-introduction-rule")

;; For each pair infer their inheritances
(cog-logger-debug "main (cog-atomspace) = ~a" (cog-atomspace))
(define all-inhs-tv (map gar (map pln-bc all-inhs)))

(write-atoms-to-file "inheritance-links.scm" all-inhs-tv)

;; Get strengths (useful for looking at their distribution, see
;; histogram-inheritance-strengths.gp)
(define strengths (map cog-mean all-inhs-tv))
