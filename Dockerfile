FROM mambaorg/micromamba:1.5-jammy

# Activate micromamba each run command
ENV MAMBA_DOCKERFILE_ACTIVATE=1

# Create and activate environment with viralQC dependencies
RUN micromamba install -y -n base -c conda-forge -c bioconda \
    bash \
    "python>=3.8.0,<3.12.0" \
    "snakemake-minimal>=7.32.0,<7.33.0" \
    "blast>=2.16.0,<2.17.0" \
    "nextclade>=3.15.0,<3.16.0" \
    "seqtk>=1.5.0,<1.6.0" \
    "ncbi-datasets-cli>=18.9.0,<18.10.0" \
    "taxonkit>=0.20.0,<0.21.0" \
    && micromamba clean --all --yes

# Install viralQC via pip
RUN /opt/conda/bin/pip install --no-cache-dir viralQC==0.11.1

# Set working directory
WORKDIR /data

# Ensure vqc is in PATH
ENV PATH="/opt/conda/bin:$PATH"
