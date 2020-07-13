;; Reproduction of the 2015 inference example produced by Eddie
;; Monroe, see doc/bio_AI_nov_2015_v3.pdf.

;; Parameters
(define rs 0)                           ; Random seed
(define ss 0.001)                         ; Subsampled portion of the KBs
(define mi 100)                      ; Maximum number of iterations
(define cp 1)                           ; Complexity penalty

;; Load modules
(use-modules (opencog))
(use-modules (opencog exec))
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
  (string-append "log/2015-pln-xp" param-str ".log"))

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
                          "results/preprocess-kbs-rs=0-ss=1-mi=12-cp=10-fra=t.scm")
                         #:subsmp ss))

(cog-logger-debug "(length db-lst) = ~a" (length db-lst))

;; Load PLN
(pln-load 'empty)
(pln-add-rule 'subset-condition-negation)
(pln-add-rule 'subset-attraction-introduction)
(pln-add-rule 'intensional-inheritance-direct-introduction)
(pln-add-rule 'intensional-similarity-direct-introduction)

;; For now calculate the intensional inheritance between GO concepts
;; as a test.

;; Run backward chainer to produce attraction links.
(define X (Variable "$X"))
(define Y (Variable "$Y"))
(define CT (Type "ConceptNode"))
(define vardecl (VariableSet
                  (TypedVariable X CT)
                  (TypedVariable Y CT)))
(define target (Attraction X Y))
(define results-ats (pln-bc target
                            #:vardecl vardecl
                            #:maximum-iterations mi
                            #:complexity-penalty cp))

;; Run backward chainer to produce intensional inheritances.
;; (define target (IntensionalInheritance X Y))
(define target (IntensionalSimilarity X Y))
(define results-iis (pln-bc target
                            #:vardecl vardecl
                            #:maximum-iterations mi
                            #:complexity-penalty cp))

;; All results
(define results (append (cog-outgoing-set results-ats)
                        (cog-outgoing-set results-iis)))

;; Write results in file
(define scm-filename (string-append "results/2015-pln-xp" param-str ".scm"))
(write-atoms-to-file scm-filename results)
