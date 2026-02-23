#!/bin/bash

INPUT_FASTA=$1
PREFIX=$(basename "$INPUT_FASTA" | cut -d '.' -f 1)
OUTPUT_TSV="${PREFIX}_results.tsv"

echo -e "Configuration\tReplicate\tTraceFile" > "$OUTPUT_TSV"

# cpus : RAM (GB)
CONFIGS=("2:4" "4:8" "8:16" "16:32")


TOTAL_RUNS=$(( ${#CONFIGS[@]} * 3 ))
CURRENT_RUN=0

for config in "${CONFIGS[@]}"; do
    IFS=':' read -r cpus memory <<< "$config"
    CONFIG_NAME="${cpus}CPU_${memory}RAM"
    
    for rep in {1..3}; do
        CURRENT_RUN=$((CURRENT_RUN + 1))
        
        TRACE_FILE="trace-${PREFIX}_${CONFIG_NAME}_rep${rep}.txt"
        OUTDIR="${PREFIX}_${CONFIG_NAME}_rep${rep}"
        
        echo "Running Configuration: $CONFIG_NAME, Replicate: $rep"
        echo "CPUs: $cpus, Memory: $memory"

        ./nextflow run main.nf \
            --input "$INPUT_FASTA" \
            --datasets_dir datasets \
            --outdir "$OUTDIR" \
            --cpus "$cpus" \
            --memory "$memory" \
            -with-trace "$TRACE_FILE"
            
        # Check if execution was successful
        if [ $? -eq 0 ]; then
            echo "Run successful."
            awk -v cfg="$CONFIG_NAME" -v rep="$rep" '
            BEGIN {OFS="\t"} 
            NR==1 {print $0, "Configuration", "Replicate"} 
            NR>1 {print $0, cfg, rep}
            ' "$TRACE_FILE" > "${TRACE_FILE}.tmp"

            if [ "$CURRENT_RUN" -eq 1 ]; then
                 head -n 1 "${TRACE_FILE}.tmp" > "$OUTPUT_TSV"
            fi

            tail -n +2 "${TRACE_FILE}.tmp" >> "$OUTPUT_TSV"
            
            rm "${TRACE_FILE}.tmp"
            
        else
            echo "Run failed for $CONFIG_NAME Replicate $rep"
        fi

        if [ "$CURRENT_RUN" -lt "$TOTAL_RUNS" ]; then
            echo "Cleaning up output directory: $OUTDIR"
            rm -rf "$OUTDIR"
        else
            echo "Final run complete. Keeping output directory: $OUTDIR"
        fi
        
        echo "---------------------------------------------------"
    done
done

echo "Benchmark complete. Results in $OUTPUT_TSV"
