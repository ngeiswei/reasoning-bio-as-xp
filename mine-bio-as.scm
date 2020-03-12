;; Pattern mining experiment over the bio-atomspace.
;;
;; Attempt to discover patterns relating SMPDB and GO, then create
;; Implication, Equivalence, Inheritance or Similarity links and use
;; these to help reason about biology.

;; Parameters
(define jb 1)                           ; Number of jobs for the task
(define rs 0)                           ; Random seed
(define ss 1)                         ; Subsampled portion of the KBs
(define ms 100)                           ; Minimum support (ignored if mf is positive)
(define mf 0.01)                          ; Minimum frequency (ignored if negative)
(define mi 1000)                          ; Maximum number of iterations
(define mc 4)                           ; Maximum number of conjuncts
(define mv 3)                           ; Maximum number of variables
(define su 'nisurp)                       ; Surprisingness measure

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

;; Parameters string
(define param-str (string-append "-jb=" (number->string jb)
                                 "-rs=" (number->string rs)
                                 "-ss=" (number->string ss)
                                 (if (< 0 mf)
                                     (string-append "-mf=" (number->string mf))
                                     (string-append "-ms=" (number->string ms)))
                                 "-mi=" (number->string mi)
                                 "-mc=" (number->string mc)
                                 "-mv=" (number->string mv)
                                 "-su=" (symbol->string su)
                                 "-ip=" (number->hexstr (cog-handle ip))))

;; Set loggers
(define log-filename (string-append "log/mine-bio-as" param-str ".log"))

;; (cog-logger-set-timestamp! #f)
;; (cog-logger-set-sync! #t)
(cog-logger-set-level! "debug")
(cog-logger-set-filename! log-filename)
;; (ure-logger-set-timestamp! #f)
;; (ure-logger-set-sync! #t)
(ure-logger-set-level! "debug")
(ure-logger-set-filename! log-filename)

;; ;; Load preprocessed KBs, get the list of trees to mine
;; (define db-lst (load-kbs (list "kbs/smpdb_gene.scm"
;;                                "kbs/GO.scm"
;;                                "kbs/GO_annotation.scm")
;;                          #:subsmp ss))

;; Load preprocessed KBs, get the list of trees to mine
;; (define db-lst (load-kbs (list "kbs/agingSwitchSymbols2/biogrid.scm"
;;                                ;; "kbs/agingSwitchSymbols2/gene-go.scm"
;;                                ;; "kbs/agingSwitchSymbols2/gene-pathway.scm"
;;                                ;; "kbs/agingSwitchSymbols2/main.scm"
;;                                ;; "kbs/agingSwitchSymbols2/mainRNA.scm")
;;                                )
;;                          #:subsmp ss))

(define db-lst (load-kb
                ;; "kbs/agingSwitchSymbols2/biogrid.scm"
                ;; "kbs/agingSwitchSymbols2/gene-go.scm"
                ;; "kbs/agingSwitchSymbols2/gene-pathway.scm"
                ;; "kbs/agingSwitchSymbols2/main.scm"
                "kbs/agingSwitchSymbols2/mainRNA.scm"
                #:subsmp ss))

;; Post-process by adding extra knowledge
(define db-lst (append db-lst (add-extra-kb)))

;; ;; Debug: log BD
;; (cog-logger-debug "db-lst:\n~a" db-lst)

;; Call pattern miner
(define results (cog-mine db-lst
                          #:jobs jb
                          #:minimum-support ms
                          #:minimum-frequency mf
                          #:maximum-iterations mi
                          #:conjunction-expansion #f
                          #:maximum-conjuncts mc
                          #:maximum-variables mv
                          #:maximum-spcial-conjuncts 4
                          #:surprisingness su
                          #:initial-pattern ip))

(cog-logger-debug "Final results:\n~a" results)

;; Write results in a file
(define miner-results-filename (string-append "results/mine-bio-as-results" param-str ".scm"))
(write-atoms-to-file miner-results-filename results)
