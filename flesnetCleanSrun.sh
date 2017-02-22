#!/bin/bash

p=$(srun -N $SLURM_JOB_NUM_NODES -l ps aux | grep flesnet)
i=0
while [[ $p ]]
do
sleep 5
p=$(srun -N $SLURM_JOB_NUM_NODES -l ps aux | grep flesnet)
i=$((i+1))
if (( $i == 15 )) ; then
break
fi
done

srun -N $SLURM_JOB_NUM_NODES killall -9 flesnet
wait
srun -N $SLURM_JOB_NUM_NODES killall -9 tsclient
wait
srun -N $SLURM_JOB_NUM_NODES rm -Rf /run/shm/*flesnet*
wait
srun -N $SLURM_JOB_NUM_NODES rm -Rf /run/shm/*tsclient*
wait
#srun -N $SLURM_JOB_NUM_NODES killall -9 -u bzcsalem
#wait
srun -N $SLURM_JOB_NUM_NODES find /run/shm/bzcsalem -delete
wait
