#!/bin/bash
#MSUB -e job$MOAB_JOBID.err
#MSUB -o job$MOAB_JOBID.out
#MSUB -l walltime=00:10:00
#MSUB -F exclusive

source env_variables.sh

if [ -z "$COMPUTE" ]; then
	INPUT=$((PBS_NUM_NODES/2))
	COMPUTE=$((PBS_NUM_NODES - INPUT))
fi

mkdir "jobs/$MOAB_JOBID"

echo "COMPUTE=$COMPUTE, INPUT=$INPUT"
echo "Generating the Config file"
hostnames=$(aprun -N1 -n$PBS_NUM_NODES ./flesnetMsubHosts.sh | sort -k1 -n | awk '{ print $2}')
#echo "hostnames=$hostnames"
I=0
FILENAME="flesnet.cfg"
echo -e "\n# The list of participating compute nodes." > $FILENAME

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
    if [ "$I" -le "$COMPUTE" ]; then
    	echo "compute-nodes = $NODE_ADDR" >> $FILENAME
	else
		echo "input-nodes = $NODE_ADDR" >> $FILENAME
	fi
	
	if [ "$I" -eq "$COMPUTE" ]; then
		echo -e "\n# The list of participating input nodes." >> $FILENAME
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
echo "HUGE_PAGES=$HUGE_PAGES"
COMPUTE=$COMPUTE SRUN=0 JOB_ID=$MOAB_JOBID HUGE_PAGES=$HUGE_PAGES aprun -N1 -n$PBS_NUM_NODES -F exclusive ./flesnetRun.sh # > output.out 2>&1
wait

aprun -N1 -n$PBS_NUM_NODES -F exclusive ./flesnetCleanAprun.sh
wait

