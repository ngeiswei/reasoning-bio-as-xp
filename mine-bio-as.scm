;; Pattern mining experiment over the bio-atomspace.
;;
;; Attempt to discover patterns relating SMPDB and GO, then create
;; Implication, Equivalence, Inheritance or Similarity links and use
;; these to help reason about biology.

;; Parameters
;; (define ms 10)                       ; Minimum support
(define mf 0.01)                        ; Minimum frequency
(define mi 10)                         ; Maximum number of iterations
(define mc 4)                           ; Maximum number of conjunctions
(define mv 3)                           ; Maximum number of variables
(define su 'nisurp)                       ; Surprisingness measure
(define rs 0)                           ; Random seed

;; Define initial pattern. Look for SMP and GO classes that have
;; surprisingly common genes.
(define ip (Lambda
             (VariableSet
               (Variable "$Gene")
               (Variable "$SMP")
               (Variable "$GO"))
             (Present
               (Member (Variable "$Gene") (Variable "$SMP"))
               (Member (Variable "$Gene") (Variable "$GO"))
               (Inheritance (Variable "$SMP") (Concept "SMP_term"))
               (Inheritance (Variable "$GO") (Concept "GO_term")))))

;; (define ip (Lambda
;;              (VariableSet
;;                (Variable "$Gene")
;;                (Variable "$SMP"))
;;              (Present
;;                (Member (Variable "$Gene") (Variable "$SMP"))
;;                (Member (Variable "$Gene") (ConceptNode "GO:0002161"))
;;                (Inheritance (Variable "$SMP") (Concept "SMP_term"))
;;                (Inheritance (ConceptNode "GO:0002161") (Concept "GO_term")))))

;; (define ip (Lambda
;;              (VariableSet
;;                (Variable "$Gene"))
;;              (Present
;;                (Member (Variable "$Gene") (ConceptNode "SMP0000055"))
;;                (Member (Variable "$Gene") (ConceptNode "GO:0002161"))
;;                (Inheritance (ConceptNode "SMP0000055") (Concept "SMP_term"))
;;                (Inheritance (ConceptNode "GO:0002161") (Concept "GO_term")))))

;; Load modules & utils
(use-modules (srfi srfi-1))
(use-modules (opencog randgen))
(use-modules (opencog logger))
(use-modules (opencog ure))
(use-modules (opencog miner))
(use-modules (opencog bioscience))
(load "bio-as-utils.scm")

;; Set random seed
(cog-randgen-set-seed! rs)

;; Set loggers
(define log-filename (string-append
                      "opencog"
                      "-rs=" (number->string rs)
                      "-mf=" (number->string mf)
                      "-mi=" (number->string mi)
                      "-mc=" (number->string mc)
                      "-mv=" (number->string mv)
                      "-su=" (symbol->string su)
                      "-ip=" (number->hexstr (cog-handle ip))
                      ".log"))

;; (cog-logger-set-timestamp! #f)
;; (cog-logger-set-sync! #t)
(cog-logger-set-level! "debug")
(cog-logger-set-filename! log-filename)
;; (ure-logger-set-timestamp! #f)
;; (ure-logger-set-sync! #t)
(ure-logger-set-level! "debug")
(ure-logger-set-filename! log-filename)

;; Load preprocessed KBs, get the list of trees to mine
(define db-lst (load-kbs "kbs/smpdb_gene.scm"
                         "kbs/GO.scm"
                         "kbs/GO_annotation.scm"))

;; Post-process by adding extra knowledge
(define db-lst (append db-lst (add-extra-kb)))

;; ;; Debug: log BD
;; (cog-logger-debug "db-lst:\n~a" db-lst)

;; Call pattern miner
(define results (cog-mine db-lst
                          #:minimum-frequency mf
                          #:maximum-iterations mi
                          #:conjunction-expansion #f
                          #:maximum-conjuncts mc
                          #:maximum-variables mv
                          #:maximum-spcial-conjuncts 4
                          #:surprisingness su
                          #:initial-pattern ip))
