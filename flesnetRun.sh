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

if [ "1" -eq "$MULTI" ]; then
	total=$((COMPUTE + INPUT))
	remainder=$((PROCID % total))
	iteration=$((PROCID / total))
	echo "remainder=$remainder, total = $total, iteration = $iteration"
	if [ $remainder -lt $INPUT ]; then
		sleep 10s
		INPUT_ID=$(((iteration * INPUT) + remainder))
		./flesnet -i $INPUT_ID &> jobs/$JOB_ID/$INPUT_ID.input.out
	else 
		COMPUTE_ID=$(((iteration * COMPUTE) + (remainder-INPUT)))
		./flesnet -c $COMPUTE_ID &> jobs/$JOB_ID/$COMPUTE_ID.compute.out
	fi
else
	if [ $PROCID -lt $INPUT ]; then
		sleep 10s
		./flesnet -i $PROCID &> jobs/$JOB_ID/$PROCID.input.out
	else 
		COMP_ID=$((PROCID - INPUT))
		./flesnet -c $COMP_ID &> jobs/$JOB_ID/$COMP_ID.compute.out
	fi
fi