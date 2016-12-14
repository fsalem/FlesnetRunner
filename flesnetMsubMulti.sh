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
FILENAME1="flesnet1.cfg"
FILENAME2="flesnet2.cfg"
echo -e "\n# The list of participating compute and Input nodes." > $FILENAME1
echo -e "\n# The list of participating compute and Input nodes." > $FILENAME2

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
    		echo "compute-nodes = $NODE_ADDR" >> $FILENAME1
    	done
    	for in in `seq 1 $INPUT`
    	do
    		echo "input-nodes = $NODE_ADDR" >> $FILENAME1
    	done
    else
    	if [ "$I" -le "$INPUT" ]; then
    		echo "input-nodes = $NODE_ADDR" >> $FILENAME1
    		echo "input-nodes = $NODE_ADDR" >> $FILENAME2
		else
			echo "I=$I, INPUT=$INPUT"
			if [[ $(( ( I - INPUT ) % 2 )) == "0" ]]; then
				echo "COMP FILE1"
				echo "compute-nodes = $NODE_ADDR" >> $FILENAME1	
			else
				echo "COMP FILE2"
				echo "compute-nodes = $NODE_ADDR" >> $FILENAME2	
			fi
		fi
	fi
done

echo -e "\n\n" >> $FILENAME1
echo -e "\n\n" >> $FILENAME2

echo -e "base-port = $BASE_PORT \n\n" >> $FILENAME1
echo -e "base-port = $(($BASE_PORT + $INPUT + 1)) \n\n" >> $FILENAME2

echo -e "# The global timeslice size in number of MCs.\n" >> $FILENAME1
echo -e "# The global timeslice size in number of MCs.\n" >> $FILENAME2

echo -e "timeslice-size = $TIMESLICE_SIZE\n\n" >> $FILENAME1
echo -e "timeslice-size = $TIMESLICE_SIZE\n\n" >> $FILENAME2


echo -e "# input node buffer size\n" >> $FILENAME1
echo -e "# input node buffer size\n" >> $FILENAME2

echo -e "in-data-buffer-size-exp = $IN_BUF_SIZE\n\n" >> $FILENAME1
echo -e "in-data-buffer-size-exp = $IN_BUF_SIZE\n\n" >> $FILENAME2

echo -e "# Compute node buffer size\n" >> $FILENAME1
echo -e "# Compute node buffer size\n" >> $FILENAME2

echo -e "cn-data-buffer-size-exp = $CN_BUF_SIZE\n\n" >> $FILENAME1
echo -e "cn-data-buffer-size-exp = $CN_BUF_SIZE\n\n" >> $FILENAME2

cat flesnet.cfg.template >> $FILENAME1
cat flesnet.cfg.template >> $FILENAME2

echo "flesnet.cfg is generated"

if [ "1" -eq "$MULTI" ]; then
	MULTI=$MULTI COMPUTE=$COMPUTE INPUT=$INPUT SRUN=0 JOB_ID=$MOAB_JOBID HUGE_PAGES=$HUGE_PAGES aprun -N$PES_PER_NODE -n$PES_COUNT -F exclusive -d 3 ./flesnetRun.sh # > output.out 2>&1
else
	FILE1=$FILENAME1 FILE2=$FILENAME2 MULTI=$MULTI COMPUTE=$COMPUTE INPUT=$INPUT SRUN=0 JOB_ID=$MOAB_JOBID HUGE_PAGES=$HUGE_PAGES aprun -N1 -n$PBS_NUM_NODES -F exclusive -d 5 ./flesnetRunMulti.sh
fi
wait

aprun -N1 -n$PBS_NUM_NODES -F exclusive ./flesnetCleanAprun.sh
wait

