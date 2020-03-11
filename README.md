# Reasoning Bio-AtomSpace Experiment 

## Prerequisites

1. Install the following projects

```
cogutil atomspace ure miner pln agi-bio
```

from the OpenCog github organization

```
https://github.com/opencog
```

To do that, for projects `cogutil`, `ure`, `miner` and `agi-bio` use
the master branches of the opencog repositories. That is type the
following:

```bash
git clone https://github.com/opencog/<PROJECT>.git
cd <PROJECT>
mkdir build
cd build
cmake ..
make -j4
sudo make install
sudo ldconfig /usr/local/lib/opencog
```

For `atomspace` use the branch `bio-as-xp` from `ngeiswei`
account. That is type the following:

```
git clone https://github.com/ngeiswei/pln.git
cd pln
git checkout bio-as-xp
```

then compile and install as usual.

For `pln` use the branch `fix-pln-api` from `ngeiswei` account. That
is type the following:

```
git@github.com:ngeiswei/pln.git
```

then compile and install as usual.

## Usage

### Prepare datasets

Download and unpack the datasets. From the root folder of that
project, type the following

```bash
cd kbs
wget https://mozi.ai/datasets/gene-level-dataset.tar.gz
tar xvzf gene-level-dataset.tar.gz
cd ..
```

### Run experiments

#### Pattern miner xp

```bash
guile --no-auto-compile -l mine-bio-as.scm
```

should output a scheme file

```
results/miner-bio-as-results-<PARAMETERS>.scm
```

containing mined patterns.

#### Turn patterns into relationships

```bash
guile --no-auto-compile -l pattern-to-relationship.scm
```

loads a file containing mined pattern (see previous step), and
produces a file

```
results/inheritance-links.scm
```

containing inheritance relationships gotten by applying PLN to
surprising patterns.

#### Preprocess KBs

```bash
guile --no-auto-compile -l preprocess-kbs.scm
```

which should create

```
results/preprocess-kbs-<PARAMETERS>.scm
```

#### Simple intensional reasoning example

```bash
guile --no-auto-compile -l intensional-reasoning-test.scm
```

which should create

```
results/intentional-reasoning-test-<PARAMETERS>.scm
```

### Simple PLN reasoning example

```bash
guile --no-auto-compile -l simple-pln-inference.scm
```

which should create

```
results/simple-pln-inference-<PARAMETERS>.scm
```

#### Run 2015 PLN with intensional reasoning

Warning: not working yet

```bash
guile --no-auto-compile -l 2015-pln-inference.scm
```

## Related work

https://gitlab.com/opencog-bio/pln_mozi
