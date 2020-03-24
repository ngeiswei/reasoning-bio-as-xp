;; Simple intensional reasoning test

;; Parameters
(define rs 0)                           ; Random seed
(define ss 0.001)                         ; Subsampled portion of the KBs
(define mi 100)                      ; Maximum number of iterations
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
  (string-append "log/intentional-reasoning-test" param-str ".log"))

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
(pln-add-rule-by-name "intensional-inheritance-direct-introduction-rule")
(pln-add-rule-by-name "intensional-similarity-direct-introduction-rule")
(pln-add-rule-by-name "intensional-difference-direct-introduction-rule")

;; For now calculate the intensional inheritance between GO concepts
;; as a test.

;; Run backward chainer to produce intensional links.
(define X (Variable "$X"))
(define Y (Variable "$Y"))
;; (define target (IntensionalInheritance X Y))
;; (define target (IntensionalSimilarity X Y))
(define target (IntensionalDifference X Y))
(define results-iis (pln-bc target
                            #:maximum-iterations mi
                            #:complexity-penalty cp))

;; All results
(define results (cog-outgoing-set results-iis))

;; Write results in file
(define scm-filename
  (string-append "results/intentional-reasoning-test" param-str ".scm"))
(write-atoms-to-file scm-filename results)
