;; Set of utilities for filtering the dataset and the results

;; Load modules
(use-modules (srfi srfi-1))
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

(define (member? x)
  (cog-subtype? 'MemberLink (cog-type x)))

;; TODO: better use scheme basename function
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

(define (go? A)
  (and (eq? (cog-type A) 'ConceptNode)
       (string-starts-with? (cog-name A) "GO:")))

(define (get-smps)
  (filter smp? (cog-get-atoms 'ConceptNode)))

(define (number->hexstr n)
  (format #f "~x" n))

(define (get-pattern eval-pattern)
  (cog-outgoing-atom (gdr eval-pattern) 0))

(define (get-body pattern)
  (cog-outgoing-atom pattern 1))

(define (get-clauses body)
  (if (or (eq? (cog-type body) 'PresentLink)
          (eq? (cog-type body) 'AndLink))
      (cog-outgoing-set body)
      body))

(define (load-filter pred? filename)
"
  1. Load filename in an auxiliaury atomspace
  2. Grab all atoms
  3. Only retain the valid ones according to pred
  4. Copy the valid atoms in the current atomspace
  5. Return the list of the copied atoms
"
  (let* (;; Load file in a temporary atomspace
         (base-as (cog-push-atomspace))
         (dummy (load filename))

         ;; Filter in atoms satisfying pred
         (tmp-as (cog-atomspace))
         (atoms (filter pred? (cog-get-atoms 'Atom #t)))

         ;; Copy admissible atoms in the base atomspace
         (base-atoms (cog-cp base-as atoms))

         ;; Discard the temporary atomspace
         (dummy (cog-pop-atomspace)))
    base-atoms))

(define (load-kb subsmp kb-filename)
"
  1. Load the given dataset.
  2. Remove useless atoms for mining.
  3. Add useful atoms (such as SMP classes)
"
  (let* (;; Define filter for admissible atoms
         (rand-selected? (lambda (x) (<= (cog-randgen-randfloat) subsmp)))
         (eval-GO_namespace? (lambda (x) (eval-pred-name? "GO_namespace" x)))
         (admissible? (lambda (x) (and
                                    (rand-selected? x)
                                    (cog-link? x)
                                    (not (scope? x))
                                    (not (lst? x))
                                    (not (and? x))
                                    (not (present? x))
                                    (not (eval-GO_namespace? x))))))
    (load-filter admissible? kb-filename)))

(define (load-kbs subsmp . kbs-filenames)
  (concatenate (map (lambda (x) (load-kb subsmp x)) kbs-filenames)))

(define (add-extra-kb)
  ;; Small Molecule Pathway concept
  (let* ((smps (get-smps))
         (smp-cpt (Concept "SMP_term")))
    (map (lambda (x) (Inheritance x smp-cpt)) smps)))

(define (write-atoms-to-file filename a-lst)
"
  Write a list of atoms into filename.
"
  (let* ((port (open-file filename "w")))
    (for-each (lambda (x) (write x port)) a-lst)
    (close-port port))

  *unspecified*)

(define (load-pattern-evaluations filename)
"
  1. Load the given scheme file.
  2. Only retain pattern evaluations with
    2.1 non null surprisingness
    2.2 pairs of SMP and GO concept and gene variabale member
"
  (let* (;; Define filter for admissible atoms
         (surp-eval? (lambda (x) (or (eval-pred-name? "nisurp" x)
                                     (eval-pred-name? "jsdsurp" x))))
         (member-clauses? (lambda (x)
                            (let* ((body (get-body (get-pattern x)))
                                   (clauses (get-clauses body))
                                   (are-members (map member? clauses)))
                              (not (member #f are-members)))))
         (pos-mean? (lambda (x) (< 0 (cog-mean x))))
         (admissible? (lambda (x) (and
                                   (pos-mean? x)
                                   (surp-eval? x)
                                   (member-clauses? x)))))
    (load-filter admissible? filename)))

(define (extract-GO-SMP-pair pattern-eval)
  (let* ((body (get-body (get-pattern pattern-eval)))
         (clauses (get-clauses body))
         (cpts (map gdr clauses)))
    cpts))
