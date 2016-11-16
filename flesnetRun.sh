#!/bin/bash

FI_LOG_LEVEL=Debug
PROCID=-1
export HUGETLB_VERBOSE=2
if [ "$SRUN" -eq "1" ]; then
	PROCID=$SLURM_PROCID
else
	module load craype-hugepages$HUGE_PAGES
	PE_VAR=$(env|grep "ALPS_APP_PE")
	PROC_STR=(${PE_VAR//=/ })
	PROCID=${PROC_STR[1]}
fi
if [ $PROCID -lt $COMPUTE ]; then
	./flesnet -c $PROCID &> jobs/$JOB_ID/$PROCID.compute.out
else 
	INPUT_ID=$((PROCID - COMPUTE))
	./flesnet -i $INPUT_ID &> jobs/$JOB_ID/$INPUT_ID.input.out
fi
