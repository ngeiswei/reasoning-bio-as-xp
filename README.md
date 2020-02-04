# Reasoning Bio-AtomSpace Experiment 

## Prerequisites

1. Install the following projects

```
cogutil atomspace ure miner agi-bio
```

from the OpenCog github organization

```
https://github.com/opencog
```

To do that, for each project do as follows:

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
miner-results-<PARAMETERS>.scm
```

containing mined patterns.

#### Turn patterns into relationships

```bash
guile --no-auto-compile -l pattern-to-relationship.scm
```

loads a file containing mined pattern (see previous step), and
produces a file

```
inheritance-links.scm
```

containing inheritance relationships gotten by applying PLN to
surprising patterns.

#### Run PLN over the datasets

```bash
guile --no-auto-compile -l pln-bio-as.scm
```

will load the bio-as datasets, as well as `inheritance-links.scm`
generated above and apply PLN on the whole thing.

## Related work

https://gitlab.com/opencog-bio/pln_mozi
