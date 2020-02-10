;; Reproduction of the 2015 inference example produced by Eddie
;; Monroe, see doc/bio_AI_nov_2015_v3.pdf.

;; Parameters
(define rs 0)                           ; Random seed
(define ss 1)                         ; Subsampled portion of the KBs
(define mi 1000)                      ; Maximum number of iterations
(define cp 10)                           ; Complexity penalty

;; Load modules
(use-modules (opencog randgen))
(use-modules (opencog logger))
(use-modules (opencog ure))
(use-modules (opencog pln))
(use-modules (opencog bioscience))
(load "bio-as-utils.scm")

(define log-filename
  (string-append "2015-pln-xp"
                 "-rs=" (number->string rs)
                 "-ss=" (number->string ss)
                 "-cp=" (number->string cp)
                 ".log"))

;; (cog-logger-set-timestamp! #f)
;; (cog-logger-set-sync! #t)
(cog-logger-set-level! "debug")
(cog-logger-set-filename! log-filename)
;; (ure-logger-set-timestamp! #f)
;; (ure-logger-set-sync! #t)
(ure-logger-set-level! "debug")
(ure-logger-set-filename! log-filename)

;; Load kbs
(define db-lst (load-kbs ss
                         "kbs/GO.scm"
                         "kbs/GO_annotation.scm"
                         "kbs/2015-completion.scm"))

;; Load PLN
(pln-load #:rule-base 'empty)

;; ;; Run forward chainer
;; (define vardecl (VariableSet (TypedVariable X ConceptT) (TypedVariable Y ConceptT)))
;; (define source (Inheritance X Y))
;; (define results (pln-fc source
;;                         #:vardecl vardecl
;;                         #:maximum-iterations mi
;;                         #:complexity-penalty cp))

;; For now apply the following rules in a determined order



;; Conclusion


;; Write results in file
(define scm-filename
  (string-append "2015-pln-xp"
                 "-rs=" (number->string rs)
                 "-ss=" (number->string ss)
                 "-cp=" (number->string cp)
                 ".scm"))
(write-atoms-to-file scm-filename (cog-outgoing-set results))
