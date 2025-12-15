
## Install viralqc

```bash
micromamba install \
  -c conda-forge \
  -c bioconda \
  "python>=3.8.0,<3.12.0" \
  "snakemake-minimal>=7.32.0,<7.33.0" \
  "blast>=2.16.0,<2.17.0" \
  "nextclade>=3.15.0,<3.16.0" \
  "seqtk>=1.5.0,<1.6.0" \
  "ncbi-datasets-cli>=18.9.0,<18.10.0" \
  "taxonkit>=0.20.0,<0.21.0"

pip install viralQC
```

### Configure datasets

```bash
vqc get-nextclade-datasets
```

```bash
vqc get-blast-database --release-date "2025-12-15"
```

#### NCBI Datasets

Download virus genomes of different datasets

```bash
export NCBI_EMAIL="your-email"
export NCBI_API_KEY="your-api-key"
```

### Virus from animals excluding human as host and SARS-CoV-2

```bash
python download_sequences.py \
  -i ncbi_data/animal_non_human_exclude_sars-cov-2.txt \
  -o animal_non_human.fasta  \
  --email $NCBI_EMAIL \
  --api-key $NCBI_API_KEY
```

### Virus from human excluding SARS-CoV-2

```bash
python download_sequences.py \
  -i ncbi_data/human_exclude_sars-cov-2.txt \
  -o human.fasta  \
  --email $NCBI_EMAIL \
  --api-key $NCBI_API_KEY
```


### Only SARS-CoV-2

```bash
python download_sequences.py \
  -i ncbi_data/sars-cov-2.txt \
  -o sars-cov-2.fasta  \
  --email $NCBI_EMAIL \
  --api-key $NCBI_API_KEY
```

## Run Benchmark with Docker + Nextflow

### Build Docker image

```bash
docker build -t viralqc:latest .
```

### Configure datasets (outside Docker)

Before running, ensure datasets are configured. Ignore if you already had configured the vqc datasets.

```bash
vqc get-nextclade-datasets
vqc get-blast-database --release-date "2025-12-15"
```

### Example Run Nextflow workflow

Here just an example of how to run the workflow. You can run in batch using the shell scripts `benchmark_viralqc.sh` and `benchmark_viralqc_meta.sh`.

```bash
nextflow run main.nf \
    --input animal_no_human.fasta \
    --datasets_dir datasets \
    --outdir animal_no_human \
    --cpus 1 \
    --memory 2 \
    -with-trace trace-animal_no_human_1_2.csv
```

#### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--input` | Path to input FASTA file | Required |
| `--datasets_dir` | Path to viralQC datasets directory | Required |
| `--outdir` | Output directory | `results` |
| `--cpus` | Number of CPU cores | `1` |
| `--memory` | Memory in GB | `2` |

## Run batch with default values

```bash
bash benchmark_viralqc.sh animal_non_human.fasta
bash benchmark_viralqc.sh human.fasta
bash benchmark_viralqc.sh sars-cov-2.fasta
```

## Run batch with custom parameters for metagenomics

```bash
bash benchmark_viralqc_meta.sh animal_non_human.fasta
bash benchmark_viralqc_meta.sh human.fasta
```
