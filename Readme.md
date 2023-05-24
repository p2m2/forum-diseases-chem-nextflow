# forum-diseases-chem-nextflow

```bash
./nextflow forum.nf -resume
```

## Configuration

``nextflow.config

- `TESTDEV` to false for a release production
- 

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