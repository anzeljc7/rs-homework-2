#!/bin/bash
#SBATCH --job-name=gem5_task1_snooping
#SBATCH --output=results_task1_%j.log
#SBATCH --reservation=fri
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --time=01:00:00

cd $SLURM_SUBMIT_DIR

GEM5_WORKSPACE=/d/hpc/projects/FRI/GEM5/gem5_workspace
GEM5_OPT=$GEM5_WORKSPACE/gem5/build/RISCV/gem5.opt
SIF=$GEM5_WORKSPACE/gem5_rv.sif

# Zgradi workload
srun apptainer exec $SIF make -C workload/cholesky

for NUM_CORES in 2 4 8 16; do
    echo "Running Cholesky with ${NUM_CORES} cores..."
    srun apptainer exec $SIF $GEM5_OPT \
        --outdir=m5out_snooping_${NUM_CORES}cores \
        smp_classic/smp_benchmark.py \
        --num_cores=$NUM_CORES \
        --l1_size="32KiB" \
        --l2_size="256KiB" \
        --l3_size="2MiB"
    echo "Done with ${NUM_CORES} cores."
done

echo "All simulations complete."