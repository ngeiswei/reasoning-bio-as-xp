;; Useful rule generators

;;;;;;;;;;;;;;;;;
;; Translation ;;
;;;;;;;;;;;;;;;;;

;; Rule generator for the translation of LINK-TYPE-1 to LINK-TYPE-2
;;
;; (LINK-TYPE-1 X Y)
;; |-
;; (LINK-TYPE-2 X Y)
(define (gen-present-link-translation-rule LINK-TYPE-1 LINK-TYPE-2 VAR-TYPE)
  (let* ((X (Variable "$X"))
         (Y (Variable "$Y"))
         (XY-1 (LINK-TYPE-1 X Y))
         (XY-2 (LINK-TYPE-2 X Y)))
    (Bind
      (VariableList
        (TypedVariable X VAR-TYPE)
        (TypedVariable Y VAR-TYPE))
      (Present
        XY-1)
      XY-2)))

;;;;;;;;;;;;;;;;;;
;; Transitivity ;;
;;;;;;;;;;;;;;;;;;

;; Rule generator for the transitivity of LINK-TYPE (equivalent to a
;; crisp deduction rule).
;;
;; (LINK-TYPE X Y)
;; (LINK-TYPE Y Z)
;; |-
;; (LINK-TYPE X Z)
(define (gen-present-link-transitivity-rule LINK-TYPE VAR-TYPE)
  (let* ((X (Variable "$X"))
         (Y (Variable "$Y"))
         (Z (Variable "$Z"))
         (XY (LINK-TYPE X Y))
         (YZ (LINK-TYPE Y Z))
         (XZ (LINK-TYPE X Z)))
    (Bind
      (VariableList
        (TypedVariable X VAR-TYPE)
        (TypedVariable Y VAR-TYPE)
        (TypedVariable Z VAR-TYPE))
      (And
        (Present
          XY
          YZ)
        (Not (Identical X Z)))
      XZ)))

;; Rule generator for the transitivity of some link type via some
;; other link type. Specifically
;;
;; (LINK-TYPE-1 X Y)
;; (LINK-TYPE-2 Y Z)
;; |-
;; (LINK-TYPE-1 X Z)
(define (gen-present-mixed-link-transitivity-rule LINK-TYPE-1 LINK-TYPE-2
                                                  X-TYPE Y-TYPE Z-TYPE)
  (let* ((X (Variable "$X"))
         (Y (Variable "$Y"))
         (Z (Variable "$Z"))
         (XY (LINK-TYPE-1 X Y))
         (YZ (LINK-TYPE-2 Y Z))
         (XZ (LINK-TYPE-1 X Z)))
    (Bind
      (VariableList
        (TypedVariable X X-TYPE)
        (TypedVariable Y Y-TYPE)
        (TypedVariable Z Z-TYPE))
      (And
        (Present
          XY
          YZ)
        (Not (Identical X Z)))
      XZ)))

;; Rule generator for the transitivity of predicate PRED.
;;
;; (Evaluation PRED (List X Y))
;; (Evaluation PRED (List Y Z))
;; |-
;; (Evaluation PRED (List X Z))
(define (gen-present-predicate-transitivity-rule PRED VAR-TYPE)
  (let* ((X (Variable "$X"))
         (Y (Variable "$Y"))
         (Z (Variable "$Z"))
         (XY (Evaluation PRED (List X Y)))
         (YZ (Evaluation PRED (List Y Z)))
         (XZ (Evaluation PRED (List X Z))))
    (Bind
      (VariableList
        (TypedVariable X VAR-TYPE)
        (TypedVariable Y VAR-TYPE)
        (TypedVariable Z VAR-TYPE))
      (And
        (Present
          XY
          YZ)
        (Not (Identical X Z)))
      XZ)))

;; Rule generator for the transitivity of predicate PRED up to some
;; link type. Specifically
;;
;; (Evaluation PRED (List X Y))
;; (LINK-TYPE Y Z)
;; |-
;; (Evaluation PRED (List X Z))
(define (gen-present-mixed-predicate-link-transitivity-rule PRED LINK-TYPE X-TYPE YZ-TYPE)
  (let* ((X (Variable "$X"))
         (Y (Variable "$Y"))
         (Z (Variable "$Z"))
         (XY (Evaluation PRED (List X Y)))
         (YZ (LINK-TYPE Y Z))
         (XZ (Evaluation PRED (List X Z))))
    (Bind
      (VariableList
        (TypedVariable X X-TYPE)
        (TypedVariable Y YZ-TYPE)
        (TypedVariable Z YZ-TYPE))
      (And
        (Present
          XY
          YZ)
        (Not (Identical X Z)))
      XZ)))

;;;;;;;;;;;;;;
;; Symmetry ;;
;;;;;;;;;;;;;;

;; Rule generator for the symmetry of link LINK-TYPE.
(define (gen-present-link-symmetry-rule LINK-TYPE VAR-TYPE)
  (let* ((X (Variable "$X"))
         (Y (Variable "$Y"))
         (XY (LINK-TYPE X Y))
         (YZ (LINK-TYPE Y Z)))
    (Bind
      (VariableList
        (TypedVariable X VAR-TYPE)
        (TypedVariable Y VAR-TYPE))
      (Present XY)
      YX)))

;; Rule generator for the symmetry of predicate PRED.
(define (gen-present-predicate-symmetry-rule PRED VAR-TYPE)
  (let* ((X (Variable "$X"))
         (Y (Variable "$Y"))
         (XY (Evaluation PRED (List X Y)))
         (YX (Evaluation PRED (List Y X))))
    (Bind
      (VariableList
        (TypedVariable X VAR-TYPE)
        (TypedVariable Y VAR-TYPE))
      (Present XY)
      YX)))
