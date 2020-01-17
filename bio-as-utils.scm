;; Set of utilities for filtering the dataset and the results

;; Load modules
(use-modules (srfi srfi-1))
(use-modules (opencog miner))
(use-modules (opencog logger))

;; Helpers
(define (scope? x)
  (cog-subtype? 'ScopeLink (cog-type x)))

(define (lst? x)
  (cog-subtype? 'ListLink (cog-type x)))

(define (and? x)
  (cog-subtype? 'AndLink (cog-type x)))

(define (present? x)
  (cog-subtype? 'PresentLink (cog-type x)))

(define (eval? x)
  (cog-subtype? 'EvaluationLink (cog-type x)))

(define (eval-pred-name? name x)
  (and (eval? x)
       (equal? (cog-name (gar x)) name)))

(define (rm-extension fn ext)
  (if (string-suffix? (string-append "." ext) fn)
      (substring fn 0 (- (string-length fn) 4))
      fn))

(define (string-starts-with? str prefix)
  (let* ((start 0)
         (end (string-length prefix))
         (str-prefix (substring str start end)))
    (equal? str-prefix prefix)))

(define (smp? A)
  (and (eq? (cog-type A) 'ConceptNode)
       (string-starts-with? (cog-name A) "SMP0")))

(define (get-smps)
  (filter smp? (cog-get-atoms 'ConceptNode)))

(define (number->hexstr n)
  (format #f "~x" n))

(define (load-kbs . kbs-filenames)
  (concatenate (map load-kb kbs-filenames)))

(define (load-kb kb-filename)
"
  1. Load the given dataset.
  2. Remove useless atoms for mining.
  3. Add useful atoms (such as SMP classes)
"
  (let* (;; Load the corpus in a separate atomspace
         (base-as (cog-push-atomspace))
         (dummy (load kb-filename))

         ;; Construct corpus to mine.
         (db-as (cog-atomspace))
         (db-lst (get-db-lst db-as))

         ;; Filter in admissible types from db-lst
         (eval-GO_namespace? (lambda (x) (eval-pred-name? "GO_namespace" x)))
         (admissible? (lambda (x) (and
                                    (cog-link? x)
                                    (not (scope? x))
                                    (not (lst? x))
                                    (not (and? x))
                                    (not (present? x))
                                    (not (eval-GO_namespace? x)))))
         (db-in-lst (filter admissible? db-lst))

         ;; ;; TMP log pre-processed DB
         ;; (msg (cog-logger-debug "db-in-lst:\n~a" db-in-lst))

         ;; Copy admissible atoms in the base atomspace
         (base-db-in-lst (cog-cp base-as db-in-lst))

         ;; Discard the db atomspace
         (dummy (cog-pop-atomspace)))
    base-db-in-lst))

(define (add-extra-kb)
  ;; Small Molecule Pathway concept
  (let* ((smps (get-smps))
         (smp-cpt (Concept "SMP_term")))
    (map (lambda (x) (Inheritance x smp-cpt)) smps)))
