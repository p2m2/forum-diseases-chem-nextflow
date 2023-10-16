# forum-diseases-chem-nextflow

The workflow was built from the [manual](https://gist.github.com/ofilangi/9c026c7f1b9ff3b38de3ee6153f15326) construction notes of [FORUM](https://github.com/eMetaboHUB/Forum-DiseasesChem/)

## pre-requisites

- [docker](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)
- conda 

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
./nextflow run forum-vocabularies.nf -entry forum_vocabularies -resume
```

#### MeSH

```bash
./nextflow run forum-MeSH.nf -entry forum_mesh
```

#### MetaNetX

```bash
./nextflow run forum-MetaNetX.nf -entry forum_MetaNetX
```

#### PubChem min

```bash
./nextflow run forum-PubChem-min.nf -entry forum_PubChemMin
```

#### PMID-CID

```bash
./nextflow run forum-PMID-CID.nf -entry forum_PMID_CID
```

#### SBML Human

```bash
./nextflow run forum-SBML_Human.nf -entry forum_SBML_Human
```

#### SBML Chemont

```bash
./nextflow run forum-chemont.nf -entry forum_Chemont
```

#### History

##### 27/09/2023 

- 3d 17h 41m 56s	nextflow run forum-PMID-CID.nf -entry forum_PMID_CID              
- 14d 5h 58m 56s nextflow run forum-chemont.nf -entry forum_Chemont 

#### TODO
- tweak forum_Chemont

## Testing Computation

```bash
./nextflow run forum-computation-virtuoso.nf -entry test_virtuoso -resume
```

## Virtuoso

### workflow to load a virtuoso database

create a file `start_virtuoso.nf`

```rb
include { start_virtuoso } from './forum-computation-virtuoso'

workflow load() {

listScripts = Channel.fromList([
        "${params.rdfoutdir}/upload.sh",
        "${params.rdfoutdir}/upload_PMID_CID.sh",
        "${params.rdfoutdir}/upload_MeSH.sh",
        "${params.rdfoutdir}/upload_PubChem_minimal.sh"
    ])
    
listScripts.view()

start_virtuoso(listScripts) 
}
```
### run 

```bash
./nextflow run start_virtuoso.nf -entry load
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