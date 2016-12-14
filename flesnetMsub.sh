#!/bin/bash
#MSUB -e job$MOAB_JOBID.err
#MSUB -o job$MOAB_JOBID.out
#MSUB -l walltime=00:10:00
#MSUB -q mpp1testq

source env_variables.sh

if [ -z "$COMPUTE" ]; then
	INPUT=$((PBS_NUM_NODES/2))
	COMPUTE=$((PBS_NUM_NODES - INPUT))
fi

mkdir "jobs/$MOAB_JOBID"
PES_PER_NODE=$((INPUT + COMPUTE))
PES_COUNT=$((PES_PER_NODE * PBS_NUM_NODES))
echo "COMPUTE=$COMPUTE, INPUT=$INPUT"
echo "Generating the Config file"
hostnames=$(aprun -N1 -n$PBS_NUM_NODES ./flesnetMsubHosts.sh | sort -k1 -n | awk '{ print $2}')
#echo "hostnames=$hostnames"
I=0
FILENAME="flesnet.cfg"
echo -e "\n# The list of participating compute and Input nodes." > $FILENAME

for hostname in $hostnames
do
	if [[ $hostname != nid* ]]; then
		#echo "cur HOST=$hostname"
		continue
	fi
	if [ "$I" -eq "$PBS_NUM_NODES" ]; then
		break
	fi
    grepRes=$(grep $hostname /etc/hosts)
    NODE_ADDR=""
    for ip in $grepRes
    do
    	NODE_ADDR=$ip
    	break
    done
    I=$((I+1))
    if [ "1" -eq "$MULTI" ]; then
    	for com in `seq 1 $COMPUTE`
    	do
    		echo "compute-nodes = $NODE_ADDR" >> $FILENAME
    	done
    	for in in `seq 1 $INPUT`
    	do
    		echo "input-nodes = $NODE_ADDR" >> $FILENAME
    	done
    else
    	if [ "$I" -le "$INPUT" ]; then
    		echo "input-nodes = $NODE_ADDR" >> $FILENAME
		else
			echo "compute-nodes = $NODE_ADDR" >> $FILENAME
		fi
	fi
done

echo -e "\n\n" >> $FILENAME

echo -e "base-port = $BASE_PORT \n\n" >> $FILENAME

echo -e "# The global timeslice size in number of MCs.\n" >> $FILENAME
echo -e "timeslice-size = $TIMESLICE_SIZE\n\n" >> $FILENAME


echo -e "# input node buffer size\n" >> $FILENAME
echo -e "in-data-buffer-size-exp = $IN_BUF_SIZE\n\n" >> $FILENAME

echo -e "# Compute node buffer size\n" >> $FILENAME
echo -e "cn-data-buffer-size-exp = $CN_BUF_SIZE\n\n" >> $FILENAME
cat flesnet.cfg.template >> $FILENAME

echo "flesnet.cfg is generated"

if [ "1" -eq "$MULTI" ]; then
	MULTI=$MULTI COMPUTE=$COMPUTE INPUT=$INPUT SRUN=0 JOB_ID=$MOAB_JOBID HUGE_PAGES=$HUGE_PAGES aprun -N$PES_PER_NODE -n$PES_COUNT -F exclusive -d 3 ./flesnetRun.sh # > output.out 2>&1
else
	MULTI=$MULTI COMPUTE=$COMPUTE INPUT=$INPUT SRUN=0 JOB_ID=$MOAB_JOBID HUGE_PAGES=$HUGE_PAGES aprun -N1 -n$PBS_NUM_NODES -F exclusive -d 3 ./flesnetRun.sh # > output.out 2>&1
fi
wait

aprun -N1 -n$PBS_NUM_NODES -F exclusive ./flesnetCleanAprun.sh
wait

