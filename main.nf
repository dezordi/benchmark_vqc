#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
 * ViralQC Benchmark Workflow
 * 
 * A simple workflow to run viralQC for benchmarking purposes.
 * Accepts input FASTA, output directory, and passes CPU cores to vqc.
 */

// Validate required parameters
if (!params.input) {
    error "Error: --input parameter is required. Please provide a FASTA file."
}

if (!params.datasets_dir) {
    error "Error: --datasets_dir parameter is required. Please provide path to viralQC datasets."
}

// Log parameters
log.info """
    ViralQC Benchmark Pipeline
    ==========================
    input       : ${params.input}
    outdir      : ${params.outdir}
    datasets_dir: ${params.datasets_dir}
    viralqc {
        blast_task = ${params.viralqc.blast_task}
        blast_qcov = ${params.viralqc.blast_qcov}
        blast_pid = ${params.viralqc.blast_pid}
    }
    cpus        : ${params.cpus}
    memory      : ${params.memory} GB
    """
    .stripIndent()

/*
 * Process: Run viralQC
 */
process VIRALQC {
    cpus params.cpus
    memory "${params.memory} GB"
    // Stop whole pipeline if this process fails
    errorStrategy 'terminate'
    maxRetries 0
 
    publishDir params.outdir, mode: 'copy'
    
    input:
    path fasta
    path datasets_dir
    
    output:
    path "results", emit: results
    path "results/results.tsv", emit: results_tsv
    
    script:
    """
    set -euo pipefail

    vqc run \
        --input ${fasta} \
        --output-dir results \
        --datasets-dir ${datasets_dir} \
        --cores ${task.cpus} \
        --blast-task ${params.viralqc.blast_task} \
        --blast-qcov ${params.viralqc.blast_qcov} \
        --blast-pident ${params.viralqc.blast_pid} -v
    """
}

/*
 * Workflow
 */
workflow {
    // Create input channels
    fasta_ch = Channel.fromPath(params.input, checkIfExists: true)
    datasets_ch = Channel.fromPath(params.datasets_dir, checkIfExists: true)
    
    // Run viralQC
    VIRALQC(fasta_ch, datasets_ch)
}

workflow.onComplete {
    log.info """
    Pipeline completed!
    ====================
    Status   : ${workflow.success ? 'SUCCESS' : 'FAILED'}
    Duration : ${workflow.duration}
    Output   : ${params.outdir}
    """
    .stripIndent()
}
