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

```
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

```
cd kbs
wget https://mozi.ai/datasets/gene-level-dataset.tar.gz
tar xvzf gene-level-dataset.tar.gz
cd ..
```

### Run experiments

#### Pattern miner xp

```
guile --no-auto-compile -l mine-bio-as.scm
```
