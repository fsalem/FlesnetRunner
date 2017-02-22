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

LOG_FILE="tmp.log.out"
echo -e "PROCID=$PROCID" >> $LOG_FILE 2>&1

if [ "1" -eq "$MULTI" ]; then
	total=$((COMPUTE + INPUT))
	remainder=$((PROCID % total))
	iteration=$((PROCID / total))
	echo "remainder=$remainder, total = $total, iteration = $iteration"
	if [ $remainder -lt $INPUT ]; then
		sleep 10s
		INPUT_ID=$(((iteration * INPUT) + remainder))
		./flesnet -i $INPUT_ID >> jobs/$JOB_ID/$INPUT_ID.input.out 2>&1
	else 
		COMPUTE_ID=$(((iteration * COMPUTE) + (remainder-INPUT)))
		./flesnet -c $COMPUTE_ID >> jobs/$JOB_ID/$COMPUTE_ID.compute.out 2>&1
	fi
else
	#echo -e "PROCID=$PROCID MULTI=0 INPUT=$INPUT" >> $LOG_FILE 2>&1
	if [ $PROCID -lt $INPUT ]; then
		sleep 10s
		INPUT_MULTI_ID=$((PROCID / 2))
		if [[ $(( PROCID % 2 ))  == "0" ]]; then
			./flesnet -i $INPUT_MULTI_ID -f $FILE2 >> jobs/$JOB_ID/$INPUT_MULTI_ID.input2.out 2>&1
			
		else
			./flesnet -i $INPUT_MULTI_ID -f $FILE1 >> jobs/$JOB_ID/$INPUT_MULTI_ID.input1.out 2>&1
		fi
	else 
		if [[ $(( PROCID % 2 ))  == "0" ]]; then
			
		fi
		COMP_ID=$((PROCID - INPUT))
		COMP_MULTI_ID=$((COMP_ID / 2))
		echo -e "PROCID=$PROCID, COMP_MULTI_ID=$COMP_MULTI_ID, COMP_ID=$COMP_ID" >> $LOG_FILE 2>&1
		if [ $INPUT -lt $PROCID ]; then
			COMP_MULTI_ID=$((COMP_MULTI_ID - 1))
			echo -e "!!! PROCID=$PROCID, COMP_MULTI_ID=$COMP_MULTI_ID, COMP_ID=$COMP_ID" >> $LOG_FILE 2>&1
		fi
		if [[ $(( COMP_ID % 2 ))  == "0" ]]; then
			if [[ $(( COMP_ID % 4 ))  == "0" ]]; then
				./flesnet -c $COMP_MULTI_ID -f $FILE2 >> jobs/$JOB_ID/$COMP_MULTI_ID.compute2.out 2>&1
			else
				./flesnet -c $COMP_MULTI_ID -f $FILE1 >> jobs/$JOB_ID/$COMP_MULTI_ID.compute1.out 2>&1
			fi
		fi
	fi
fi
wait