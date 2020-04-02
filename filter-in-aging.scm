;; Script to filter in only data related to aging

;; Parameters
(define rs 0)                           ; Random seed
(define ss 1)                         ; Subsampled portion of the KBs
(define mi 1000)                      ; Maximum number of iterations
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
  (string-append "log/filter-in-aging" param-str ".log"))

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

;; Write results in file
(define scm-filename (string-append "results/preprocess-kbs-aging" param-str ".scm"))
(write-atoms-to-file scm-filename db-lst)
