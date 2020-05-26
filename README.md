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

To do that, for projects `cogutil`, `atomspace`, `ure`, `miner`, `pln`
and `agi-bio` use the master branches of the opencog
repositories. That is type the following:

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

## Usage

### Prepare datasets

Download and unpack the datasets. From the root folder of that
project, type the following

```bash
cd kbs
wget https://mozi.ai/datasets/gene-level-dataset_2020-04-03.tar.gz
tar xvzf gene-level-dataset_2020-04-03.tar.gz
cd ..
```

### Run experiments

#### Pattern miner xp

```bash
guile -l mine-bio-as.scm
```

should output a scheme file

```
results/miner-bio-as-results-<PARAMETERS>.scm
```

containing mined patterns.

#### Turn patterns into relationships

```bash
guile -l pattern-to-relationship.scm
```

loads a file containing mined pattern (see previous step), and
produces a file

```
results/subset-links.scm
```

containing inheritance relationships gotten by applying PLN to
surprising patterns.

#### Preprocess KBs

```bash
guile -l preprocess-kbs.scm
```

which should create

```
results/preprocess-kbs-<PARAMETERS>.scm
```

#### Simple intensional reasoning example

```bash
guile -l intensional-reasoning-test.scm
```

which should create

```
results/intentional-reasoning-test-<PARAMETERS>.scm
```

#### Simple PLN reasoning example

A simple reasoning example to infer that some genes likely relate to
aging due being intensionally similar to other genes that are known to
relate to aging.

```bash
guile -l simple-pln-inference.scm
```

which should create

```
results/simple-pln-inference-<PARAMETERS>.scm
```

#### Complex (or rather less simple) PLN reasoning example

Like above but replace "relate to aging" by gene increase or decrease
with aging.

```bash
guile -l complex-pln-inference.scm
```

which should create

```
results/complex-pln-inference-<PARAMETERS>.scm
```

## More information on the broader project

https://docs.google.com/document/d/16zfY7OZtHO66mfujLdZ0-3VALXUTvxeeo4dW2ASBiNs/edit

## Related work

https://gitlab.com/opencog-bio/pln_mozi
