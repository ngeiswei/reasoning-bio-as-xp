# Translating models obtained from data fitting to atomese

## Overview

This document describes how to turn learned models from data fitting
into atomese.

## Description

Let be a dataset relating predicates `p1,...,pn` over a domain of
instances `i1,...,im` to an output predicate `o`, and a model `M`
attempting to fit the dataset, as described by the following table:

```
+-----+------+-----+------+-----+-----+
|i    |p1    |...  |pn    |o    |M    |
+-----+------+-----+------+-----+-----+
|i1   |p1(i1)|...  |pn(i1)|o(i1)|M(i1)|
+-----+------+-----+------+-----+-----+
|...  |...   |...  |...   |...  |...  |
+-----+------+-----+------+-----+-----+
|im   |p1(im)|...  |pn(im)|o(im)|M(im)|
+-----+------+-----+------+-----+-----+
```

Let be the confusion matrix relating `o` and `M`

```
+------+-----+------+
|      |o    |neg(o)|
+------+-----+------+
|M     |TP   |FP    |
+------+-----+------+
|neg(M)|FN   |TN    |
+------+-----+------+
```

Let

```
P := TP+FN
N := FP+TN
m := P+N
```

Then, the following statistical measures (as defined in [Confusion
matrix](https://en.wikipedia.org/wiki/Confusion_matrix)) should be
translated in atomese as follows,

1. `Sensitivity := TP/P`

```
Implication <strength=TP/P, count=P>
  o
  M
```

2. `Specificity := TN/N`

```
Implication <strength=TN/N, count=N>
  Not o
  Not M
```

3. `Precision (positive predictive value) := TP/(TP+FP)`

```
Implication <strength=TP/(TP+FP), count=TP+FP>
  M
  o
```

4. `Negative predictive value := TN/(TN+FN)`

```
Implication <strength=TN/(TN+FN), count=TN+FN>
  Not M
  Not o
```

with the following TVs assigned to `o`, `M`, `Not o`, `Not M`

```
o <strength=P/m, count=m>
M <strength=(TP+FP)/m, count=m>
Not <strength=N/m, count=m>
  o
Not <strength=FN+TN/m, count=m>
  M
```

Note obviously that all implications here are extensional, not mixed.

## Train, test or both?

It's a tricky question, I would suggest both, keeping in mind that
such TVs, although technically correct, do not mean that such
implication links can be used to predict the outcome of new instances
`o(i)` with the level of confidence implied by their counts.  That is
because the prior probabilities of such implication links must be
taken into account.  To correctly predict one needs to consider a
large ensemble of models to ultimately approach a form of Solomonoff
induction.  In my opinion, methods such as cross-validation are ways
to obtain larger ensembles and better priors (the hardest part), and
likely can be understood within the framework of Solomonoff induction.

## Examples

Let be a model `M`

```
Or
  Predicate "p1"
  Predicate "p2"
```

and a dataset of 3 instances `i1` to `i3`

```
+-----+-----+-----+-----+-----+
|i    |p1   |p2   |o    |M    |
+-----+-----+-----+-----+-----+
|i1   |0    |0    |0    |0    |
+-----+-----+-----+-----+-----+
|i2   |0    |1    |1    |1    |
+-----+-----+-----+-----+-----+
|i3   |1    |1    |0    |1    |
+-----+-----+-----+-----+-----+
```

with confusion matrix

```
+------+-----+------+
|      |o    |neg(o)|
+------+-----+------+
|M     |1    |1     |
+------+-----+------+
|neg(M)|0    |1     |
+------+-----+------+
```

Then, using for instance the precision as statistical measure, yields
the following implication

```
Implication <strength=1/2, count=2>
  Or
    Predicate "p1"
    Predicate "p2"
  Predicate "o"
```
