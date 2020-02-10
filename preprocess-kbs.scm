;; Preprocess Kbs before running any reasoning.
;;
;; 1. Populate all SubSet with truth values
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
;; 2. Infer closure of GO annotation, based on rule
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
  (string-append "preprocess-kbs"
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

;; Load KBs to reason on
(define db-lst (load-kbs ss
                         "kbs/GO.scm"
                         "kbs/GO_annotation.scm"))

;; Load PLN
(pln-load #:rule-base 'empty)
(pln-load-from-path "rules/translation.scm")
(pln-add-rule-by-name "present-inheritance-to-subset-translation-rule")

;; Run forward chainer
(define X (Variable "$X"))
(define Y (Variable "$Y"))
(define ConceptT (Type "ConceptNode"))
(define GeneT (Type "GeneNode"))
(define vardecl (VariableSet
                  (TypedVariable X GeneT)
                  (TypedVariable Y ConceptT)))
(define source (Member X Y))
(define results (pln-fc source
                        #:vardecl vardecl
                        #:maximum-iteration mi
                        #:complexity-penalty cp))

;; Write results in file
(define scm-filename
  (string-append "results/preprocess-kbs"
                 "-rs=" (number->string rs)
                 "-ss=" (number->string ss)
                 "-cp=" (number->string cp)
                 ".scm"))
(write-atoms-to-file scm-filename (cog-outgoing-set results))
