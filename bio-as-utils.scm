;; Set of utilities for filtering the dataset and the results

;; Load modules
(use-modules (srfi srfi-1))
(use-modules (opencog ure))
(use-modules (opencog logger))

;; Helpers
(define (fixed-false? x) #f)

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

(define (subset? x)
  (cog-subtype? 'SubsetLink (cog-type x)))

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

(define (GO_term? A)
  (and (eq? (cog-type A) 'ConceptNode)
       (equal? (cog-name A) "GO_term")))

(define (inheritance-GO_term? A)
  (and (eq? (cog-type A) 'InheritanceLink)
       (GO_term? (gdr A))))

(define (get-smps)
  (filter smp? (cog-get-atoms 'ConceptNode)))

(define (get-genes)
  (cog-get-atoms 'GeneNode))

(define (get-go-categories)
  (filter go? (cog-get-atoms 'ConceptNode)))

(define (go-subset? S)
  (and (subset? S) (go? (gar S)) (go? (gdr S))))

(define (get-go-subsets)
  (filter go-subset? (cog-get-atoms 'SubsetLink)))

(define (get-members C)
"
  Given a concept node C, return all its members
"
  (let* ((member-links (cog-filter 'MemberLink (cog-incoming-set C)))
         (member-of-C? (lambda (x) (equal? C (gdr x))))
         (members (map gar (filter member-of-C? member-links))))
    members))

(define (get-member-links EL-TYPE C-TYPE)
  (let* ((mbr-links (cog-get-atoms 'MemberLink #f))
         (valid-types? (lambda (x) (and (equal? (cog-type (gar x)) EL-TYPE)
                                        (equal? (cog-type (gdr x)) C-TYPE)))))
    (filter valid-types? mbr-links)))

(define (get-cardinality C)
"
  Giveb a concept node C, return its number of members
"
  (length (get-members C)))

(define (number->hexstr n)
  (format #f "~x" n))

(define (bool->string b)
  (if b "t" "f"))

(define (get-pattern eval-pattern)
  (cog-outgoing-atom (gdr eval-pattern) 0))

(define (get-body pattern)
  (cog-outgoing-atom pattern 1))

(define (get-clauses body)
  (if (or (eq? (cog-type body) 'PresentLink)
          (eq? (cog-type body) 'AndLink))
      (cog-outgoing-set body)
      body))

(define (mk-rand-selector prob)
"
  Return a random selector that is true with the given probability
"
  (lambda (x) (<= (cog-randgen-randfloat) prob)))

(define (load-filter-in pred? filename)
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

(define* (load-kb kb-filename
                  #:key
                  (subsmp 1)
                  (filter-out fixed-false?))
"
  1. Load the given dataset.
  2. Remove useless atoms for mining.
  3. Add useful atoms (such as SMP classes)

  An option predicate argument to filter out atoms satisfying that
  predicate.
"
  (let* (;; Define filter for admissible atoms
         (rand-selected? (mk-rand-selector subsmp))
         (eval-GO_namespace? (lambda (x) (eval-pred-name? "GO_namespace" x)))
         (admissible? (lambda (x) (and
                                    (rand-selected? x)
                                    (cog-link? x)
                                    (not (scope? x))
                                    (not (lst? x))
                                    (not (and? x))
                                    (not (present? x))
                                    (not (eval-GO_namespace? x))
                                    (not (filter-out x))))))
    (load-filter-in admissible? kb-filename)))

(define* (load-kbs kbs-filenames
                   #:key
                   (subsmp 1)
                   (filter-out fixed-false?))
  (concatenate (map (lambda (x) (load-kb x
                                         #:subsmp subsmp
                                         #:filter-out filter-out))
                    kbs-filenames)))

(define (add-extra-kb)
  ;; Small Molecule Pathway concept
  (let* ((smps (get-smps))
         (smp-cpt (Concept "SMP_term"))
         (gos (get-go-categories))
         (go-cpt (Concept "GO_term")))
    (append (map (lambda (x) (Inheritance x smp-cpt)) smps)
            (map (lambda (x) (Inheritance x go-cpt)) gos))))

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
    (load-filter-in admissible? filename)))

(define (extract-GO-SMP-pair pattern-eval)
  (let* ((body (get-body (get-pattern pattern-eval)))
         (clauses (get-clauses body))
         (cpts (map gdr clauses)))
    cpts))

(define (true-subset-inverse S)
"
  Given a subset with a true value

  Subset (stv 1 1)
    A <ATV>
    B <BTV>

  Return

  Subset <TV>
    B <BTV>
    A <ATV>

  where TV is calculated as follows

  TV.strength = (ATV.strength * ATV.count) / (BTV.strength * BTV.count)
  TV.count = (BTV.strength * BTV.count)

  Which is technically correct since (Subset A B) is true.
"
(let* ((A (gar S))
       (B (gdr S))
       (ATV (cog-tv A))
       (BTV (cog-tv B))
       (A-positive-count (* (cog-tv-mean ATV) (cog-tv-count ATV)))
       (B-positive-count (* (cog-tv-mean BTV) (cog-tv-count BTV)))
       (TV-strength (if (< 0 B-positive-count)
                        (exact->inexact (/ A-positive-count B-positive-count))
                        1))
       (TV-count B-positive-count)
       (TV-confidence (count->confidence TV-count))
       (TV (stv TV-strength TV-confidence)))
  (Subset TV B A)))

(define (gt-zero-confidence? A)
"
  Return #t iff A's confidence is greater than 0
"
  (> (cog-confidence A) 0))

(define (gt-zero-mean? A)
"
  Return #t iff A's mean is greater than 0
"
  (> (cog-mean A) 0))

(define (gt-zero-mean-and-confidence? A)
  (and (gt-zero-confidence? A) (gt-zero-mean? A)))
