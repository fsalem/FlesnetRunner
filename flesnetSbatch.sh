#!/bin/bash
#BATCH -A <account>
#SBATCH --exclusive
#SBATCH --time=00:10:00
#SBATCH --error=job%J.err
#SBATCH --output=job%J.out

source env_variables.sh

# Get the addresses on the nodes
ADR=""
if [[ "1" -eq $USE_VERBS ]]; then
	ADR=$(srun -N $SLURM_JOB_NUM_NODES flesnetIBHosts.sh)
    ADR=($(sort <<<"${ADR[*]}"))
    ADR=$( IFS=$'\n'; echo "${ADR[*]}" )
else
	ADR=$(scontrol show hostnames)
fi
mkdir "jobs/$SLURM_JOB_ID"

if [ -z "$COMPUTE" ]; then
	INPUT=$((SLURM_JOB_NUM_NODES/2))
	COMPUTE=$((SLURM_JOB_NUM_NODES - INPUT))
fi

echo "COMPUTE=$COMPUTE, INPUT=$INPUT"
echo "Generating the Config file"
echo $(./generateFlesnetConfig.sh flesnet.cfg "$ADR" $COMPUTE $INPUT $BASE_PORT $USE_VERBS)
echo "flesnet.cfg is generated"

MULTI=$MULTI COMPUTE=$COMPUTE INPUT=$INPUT SRUN=1 JOB_ID=$SLURM_JOB_ID HUGE_PAGES=$HUGE_PAGES srun -N $SLURM_JOB_NUM_NODES ./flesnetRun.sh
wait

srun -N $SLURM_JOB_NUM_NODES ./flesnetCleanSrun.sh
wait

