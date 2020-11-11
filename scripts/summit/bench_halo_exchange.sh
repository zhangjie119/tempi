#!/bin/bash
#BSUB -P csc362
#BSUB -J bench_halo_exchange 
#BSUB -o bench_halo_exchange.o%J
#BSUB -e bench_halo_exchange.e%J
#BSUB -W 02:00
#BSUB -nnodes 32

set -eou pipefail

module reset
module unload darshan-runtime
module load gcc/7.4.0
module load cuda/11.1.0
module load nsight-systems/2020.3.1.71

SCRATCH=/gpfs/alpine/scratch/cpearson/csc362/tempi_results
OUT=$SCRATCH/bench_halo_exchange.csv

set -x

mkdir -p $SCRATCH

echo "" > $OUT

for nodes in 2 4; do
  for rpn in 2 6; do
    let n=$nodes*$rpn

    if   [ $n ==   1 ]; then X=512
    elif [ $n ==   2 ]; then X=645
    elif [ $n ==   4 ]; then X=813
    elif [ $n ==   6 ]; then X=930
    elif [ $n ==  12 ]; then X=1172
    elif [ $n ==  24 ]; then X=1477
    elif [ $n ==  48 ]; then X=1861
    elif [ $n ==  96 ]; then X=2344
    elif [ $n == 192 ]; then X=2954
    fi

    echo "${nodes}nodes,${rpn}rankspernode,tempi" >> $OUT
    export TEMPI_PLACEMENT_KAHIP=""
    jsrun --smpiargs="-gpu" -n $n -r $rpn -a 1 -g 1 -c 7 -b rs ../../build/bin/bench-halo-exchange $X | tee -a $OUT
    unset TEMPI_PLACEMENT_KAHIP

    echo "${nodes}nodes,${rpn}rankspernode,notempi" >> $OUT
    export TEMPI_DISABLE=""
    jsrun --smpiargs="-gpu" -n $n -r $rpn -a 1 -g 1 -c 7 -b rs ../../build/bin/bench-halo-exchange $X | tee -a $OUT
    unset TEMPI_DISABLE
  done
done

