#!/bin/bash
#SBATCH --job-name=gem5_task3_network
#SBATCH --output=results_task3_%j.log
#SBATCH --reservation=fri
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --time=03:00:00

cd $SLURM_SUBMIT_DIR

GEM5_WORKSPACE=/d/hpc/projects/FRI/GEM5/gem5_workspace
GEM5_OPT=$GEM5_WORKSPACE/gem5/build/RISCV_ALL_RUBY/gem5.opt
SIF=$GEM5_WORKSPACE/gem5_rv.sif

# build workload only
srun apptainer exec $SIF make -C workload/stream

for NUM_CORES in 2 4 8 16; do
    for NET in pt2pt circle crossbar; do
        echo "Running ${NUM_CORES} cores on ${NET}"

        srun apptainer exec $SIF $GEM5_OPT \
            --outdir=m5out_network_${NET}_${NUM_CORES}cores \
            network/network_benchmark.py \
            --num_cores=$NUM_CORES \
            --l1_size=32KiB \
            --l2_size=256KiB \
            --network=$NET

        echo "Done ${NUM_CORES} ${NET}"
    done
done

echo "ALL DONE"