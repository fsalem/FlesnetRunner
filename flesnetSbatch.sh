#!/bin/bash
#BATCH -A <account>
#SBATCH --exclusive
#SBATCH --time=00:10:00
#SBATCH --error=job%J.err
#SBATCH --output=job%J.out

# Get the addresses on the nodes
ADR=$(scontrol show hostnames)

mkdir "jobs/$SLURM_JOB_ID"

if [ -z "$COMPUTE" ]; then
	INPUT=$((SLURM_JOB_NUM_NODES/2))
	COMPUTE=$((SLURM_JOB_NUM_NODES - INPUT))
fi

echo "COMPUTE=$COMPUTE, INPUT=$INPUT"
echo "Generating the Config file"
echo $(./generateFlesnetConfig.sh flesnet.cfg "$ADR" $COMPUTE $INPUT $BASE_PORT)
echo "flesnet.cfg is generated"

SRUN=1 JOB_ID=$SLURM_JOB_ID srun -N $SLURM_JOB_NUM_NODES ./flesnetRun.sh
wait

srun -N $SLURM_JOB_NUM_NODES ./flesnetClean.sh
wait

