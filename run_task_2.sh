#!/bin/bash
#SBATCH --job-name=gem5_task2_false_sharing
#SBATCH --output=results_task2_%j.log
#SBATCH --reservation=fri
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --time=02:00:00

cd "$SLURM_SUBMIT_DIR"

GEM5_WORKSPACE=/d/hpc/projects/FRI/GEM5/gem5_workspace
GEM5_ROOT=$GEM5_WORKSPACE/gem5
GEM5_OPT=$GEM5_ROOT/build/RISCV_ALL_RUBY/gem5.opt
SIF=$GEM5_WORKSPACE/gem5_rv.sif

srun apptainer exec "$SIF" make -C workload/parallel_prefix clean
srun apptainer exec "$SIF" make -C workload/parallel_prefix

for BIN in pprefix_falsesharing.bin pprefix_optimized.bin; do
    NAME="${BIN%.bin}"

    for NUM_CORES in 2 4 8 16; do
        OUTDIR="m5out_${NAME}_${NUM_CORES}cores"
        rm -rf "$OUTDIR"

        srun apptainer exec "$SIF" "$GEM5_OPT" \
            --outdir="$OUTDIR" \
            smp_ruby/ruby_benchmark.py \
            --num_cores="$NUM_CORES" \
            --l1_size="32KiB" \
            --l2_size="256KiB" \
            --binary="$SLURM_SUBMIT_DIR/workload/parallel_prefix/$BIN"
    done
done