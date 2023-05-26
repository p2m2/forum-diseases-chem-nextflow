# forum-diseases-chem-nextflow

The workflow was built from the [manual](https://gist.github.com/ofilangi/9c026c7f1b9ff3b38de3ee6153f15326) construction notes of [FORUM](https://github.com/eMetaboHUB/Forum-DiseasesChem/)

## Configuration

``nextflow.config

- `TESTDEV` to false for a release production
- entrez

## Notes Genouest

### Conda env

```bash
. /local/env/envconda.sh
conda create -p ~/env-forum
conda create -p ~/env-forum openjdk
```

### Nextflow env

```bash
cd forum-diseases-chem-nextflow
# -p bigmem 3 To RAM
srun --cpus-per-task=8 --mem=50G --pty bash
conda activate ~/env-forum
alias ll='ls -ail'
curl -s https://get.nextflow.io | bash
```

## Build FORUM

```bash
export TESTDEV="true"
./nextflow run forum.nf -resume
```

### Genouest

#### script.sh

```bash
#!/bin/bash

. /local/env/envnextflow-22.10.4.sh
export NXF_EXECUTOR=slurm
export NXF_OPTS="-Xms500M -Xmx2G" 
nextflow run forum.nf
```

```sbatch script.sh```

## Dev

### test subworkflow (example with FORUM vocabularies)

```bash
./nextflow run forum-vocabularies.nf -entry forum_vocabularies -resume
```