#!/bin/bash
#PBS -N mcs_tracker_v1
#PBS -A UMCP0056
#PBS -q main
#PBS -l select=1:ncpus=16:ngpus=1
#PBS -l walltime=06:00:00
#PBS -j oe
#PBS -o mcs_tracker_v1.log

# Training job for the v1 probabilistic tracker on Derecho GPU.
#
# Submit from the repo's ML-extremes-mcs/ directory:
#   qsub jobs/train_derecho_gpu.sh
#
# Smoke test first (10 steps, ~minutes, verifies env/paths/GPU before
# committing hours):
#   qsub -v SMOKE=1 -l walltime=00:20:00 jobs/train_derecho_gpu.sh
#
# Set MEAN/STD from the one-time stats run:
#   python train_tracker.py --compute-stats --mask-root $MASK_ROOT --era5 $ERA5

module load conda
conda activate /glade/work/sbhatta/conda-envs/mcs

cd "$PBS_O_WORKDIR" || exit 1

MASK_ROOT=/glade/derecho/scratch/molina/cesm_mcs/mcs_flextrkr_era5/mcstracking_3pctl
ERA5=/glade/campaign/collections/rda/data/d633000/e5.oper.fc.sfc.accumu
OUT=/glade/work/sbhatta/mcs_runs/v1

MEAN=${MEAN:-0}
STD=${STD:-0}
NORM_ARGS=""
if [ "$MEAN" != "0" ] && [ "$STD" != "0" ]; then
    NORM_ARGS="--mean $MEAN --std $STD"
fi

if [ -n "$SMOKE" ]; then
    python train_tracker.py --smoke \
        --mask-root "$MASK_ROOT" --era5 "$ERA5" --out "$OUT" \
        --train-years 2004 --valid-years 2005 --workers 4 $NORM_ARGS
else
    python train_tracker.py \
        --mask-root "$MASK_ROOT" --era5 "$ERA5" --out "$OUT" \
        --train-years 2004-2015 --valid-years 2016-2017 \
        --epochs 10 --workers 8 $NORM_ARGS
fi
