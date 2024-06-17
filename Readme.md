# forum-diseases-chem-nextflow

The workflow was built from the [manual](https://gist.github.com/ofilangi/9c026c7f1b9ff3b38de3ee6153f15326) construction notes of [FORUM](https://github.com/eMetaboHUB/Forum-DiseasesChem/)

## pre-requisites

- [docker](https://docs.docker.com/engine/install/)
- conda
- bc 

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
. /local/env/envconda.sh
conda activate ~/env-forum
alias ll='ls -ail'
curl -s https://get.nextflow.io | bash
```

## Build FORUM

```bash
export TESTDEV="true"
./nextflow run forum.nf -resume
```

## Computation

```bash

```

### Genouest

#### script.sh

```bash
#!/bin/bash

. /local/env/envnextflow-22.10.4.sh
export NXF_EXECUTOR=slurm
export NXF_OPTS="-Xms500M -Xmx2G" 
nextflow run forum.nf --rdfoutdir /scratch/$USER/forum-data
```

```sbatch script.sh```

## Dev

### Running Subworkflow

#### Vocabularies

```bash
./nextflow run forum-vocabularies.nf -entry forum_vocabularies -bg
```

#### MeSH

```bash
./nextflow run forum-MeSH.nf -entry forum_mesh -bg
```

#### MetaNetX

```bash
./nextflow run forum-MetaNetX.nf -entry forum_MetaNetX -bg
```

#### PubChem min

```bash
./nextflow run forum-PubChem-min.nf -entry forum_PubChemMin -bg
```

#### PMID-CID

```bash
./nextflow run forum-PMID-CID.nf -entry forum_PMID_CID -bg
```

#### SBML Human

```bash
./nextflow run forum-SBML_Human.nf -entry forum_SBML_Human -bg
```

#### SBML Chemont

```bash
./nextflow run forum-chemont.nf -entry forum_Chemont -bg
```

#### History

##### 27/09/2023 

- 3d 17h 41m 56s nextflow run forum-PMID-CID.nf -entry forum_PMID_CID              
- 14d 5h 58m 56s nextflow run forum-chemont.nf -entry forum_Chemont 

##### 25/04/2024

- 2d 17h 14m 4s  nextflow run forum-PMID-CID.nf -entry forum_PMID_CID


#### TODO
- tweak forum_Chemont

## Computation

### test

```bash
# if the vocabularies workflow is not built.
./nextflow run forum-vocabularies.nf -entry forum_vocabularies
# and then...
./nextflow run forum-computation-test-virtuoso.nf -entry test_upload_vocab -c nextflow-test.config
```

## Computation

### docker command

```
docker logs forum_virtuoso_9980 -f
```

```
docker rm -f forum_virtuoso_9980
```


```bash
./nextflow run forum-computation-cid-mesh.nf -entry computation_cid_mesh
./nextflow run forum-computation-chebi-mesh.nf -entry computation_chebi_mesh
```

### tofix 2024 06

Workflow finnish with the ERR status :

```
Export Metadata ... 
  Export upload_file 
  Ok

Work dir:
  /home/ofilangi/forum-diseases-chem-nextflow/work/ad/a21c089519c76e350aa422c6614b33

Tip: when you have fixed the problem you can continue the execution adding the option `-resume` to the run command line
Jun-13 11:26:42.270 [Task monitor] DEBUG nextflow.Session - Session aborted -- Cause: Missing output file(s) `EnrichmentAnalysis/CHEBI_MESH` expected by process `computation_chebi_mesh:computation`
Jun-13 11:26:42.270 [main] DEBUG nextflow.Session - Session await > all processes finished
Jun-13 11:26:49.682 [main] DEBUG nextflow.Session - Session await > all barriers passed
Jun-13 11:26:49.701 [main] DEBUG nextflow.trace.WorkflowStatsObserver - Workflow completed > WorkflowStats[succeededCount=19; failedCount=1; ignoredCount=0; cachedCount=0; pendingCount=0; submittedCount=0; runningCount=0; retriesCount=0; abortedCount=0; succeedDuration=3h 42m 33s; failedDuration=13d 13h 36m 16s; cachedDuration=0ms;loadCpus=0; loadMemory=0; peakRunning=6; peakCpus=8; peakMemory=234 GB; ]
Jun-13 11:26:49.724 [main] DEBUG nextflow.cache.CacheDB - Closing CacheDB done
Jun-13 11:26:49.765 [main] DEBUG nextflow.script.ScriptRunner - > Execution complete -- Goodbye

```

the enrichment is computed but there a probleme when the directory move to production directory (`virtuoso`)
