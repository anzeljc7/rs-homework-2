#!/bin/bash
#SBATCH --job-name=gem5_task2_false_sharing
#SBATCH --output=results_task2_%j.log
#SBATCH --reservation=fri
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --time=02:00:00

set -uo pipefail

cd "$SLURM_SUBMIT_DIR"

GEM5_WORKSPACE=/d/hpc/projects/FRI/GEM5/gem5_workspace
GEM5_ROOT=$GEM5_WORKSPACE/gem5
GEM5_OPT=$GEM5_ROOT/build/RISCV_ALL_RUBY/gem5.opt
SIF=$GEM5_WORKSPACE/gem5_rv.sif

SUMMARY_FILE="$SLURM_SUBMIT_DIR/run_summary.txt"

echo "Using gem5 binary: $GEM5_OPT"
echo "Working directory: $SLURM_SUBMIT_DIR"

# Inicializacija summary datoteke
{
    echo "Run summary"
    echo "==========="
    echo "Date: $(date)"
    echo "Job ID: ${SLURM_JOB_ID:-N/A}"
    echo "Workdir: $SLURM_SUBMIT_DIR"
    echo "gem5: $GEM5_OPT"
    echo
    echo "status,binary,cores,outdir,stats_exists"
} > "$SUMMARY_FILE"

# Prevod workloadov
srun apptainer exec "$SIF" make -C workload/parallel_prefix clean
srun apptainer exec "$SIF" make -C workload/parallel_prefix

FAILED_RUNS=0
SUCCESS_RUNS=0

for BIN in pprefix_falsesharing.bin pprefix_optimized.bin; do
    NAME="${BIN%.bin}"

    for NUM_CORES in 2 4 8 16; do
        OUTDIR="m5out_${NAME}_${NUM_CORES}cores"

        echo "========================================"
        echo "Running $NAME with ${NUM_CORES} cores..."
        echo "Outdir: $OUTDIR"
        rm -rf "$OUTDIR"

        if srun apptainer exec "$SIF" "$GEM5_OPT" \
            --outdir="$OUTDIR" \
            smp_ruby/ruby_benchmark.py \
            --num_cores="$NUM_CORES" \
            --l1_size="32KiB" \
            --l2_size="256KiB" \
            --binary="$SLURM_SUBMIT_DIR/workload/parallel_prefix/$BIN"
        then
            echo "SUCCESS: $NAME / ${NUM_CORES} cores"

            if [ -f "$OUTDIR/stats.txt" ]; then
                echo "stats.txt exists: $OUTDIR/stats.txt"
                echo "SUCCESS,$NAME,$NUM_CORES,$OUTDIR,YES" >> "$SUMMARY_FILE"
            else
                echo "WARNING: run finished but stats.txt is missing in $OUTDIR"
                echo "SUCCESS_NO_STATS,$NAME,$NUM_CORES,$OUTDIR,NO" >> "$SUMMARY_FILE"
            fi

            SUCCESS_RUNS=$((SUCCESS_RUNS + 1))
        else
            EXIT_CODE=$?
            echo "FAILED: $NAME / ${NUM_CORES} cores (exit code: $EXIT_CODE)"
            echo "FAILED,$NAME,$NUM_CORES,$OUTDIR,NO" >> "$SUMMARY_FILE"
            FAILED_RUNS=$((FAILED_RUNS + 1))
            continue
        fi
    done
done

{
    echo
    echo "Totals"
    echo "------"
    echo "Successful runs: $SUCCESS_RUNS"
    echo "Failed runs: $FAILED_RUNS"
} >> "$SUMMARY_FILE"

echo "========================================"
echo "All runs processed."
echo "Successful runs: $SUCCESS_RUNS"
echo "Failed runs: $FAILED_RUNS"
echo "Summary written to: $SUMMARY_FILE"