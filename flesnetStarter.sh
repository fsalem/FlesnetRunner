#!/bin/bash


FILENAME="env_variables.sh"

echo -e "\n# The list of used enviromental variables.\n" > $FILENAME
echo "NODES=$NODES" >> $FILENAME
echo "INPUT=$INPUT" >> $FILENAME
echo "COMPUTE=$COMPUTE" >> $FILENAME
echo "BASE_PORT=$BASE_PORT" >> $FILENAME
echo "TIMESLICE_SIZE=$TIMESLICE_SIZE" >> $FILENAME
echo "IN_BUF_SIZE=$IN_BUF_SIZE" >> $FILENAME
echo "CN_BUF_SIZE=$CN_BUF_SIZE" >> $FILENAME
echo "HUGE_PAGES=$HUGE_PAGES" >> $FILENAME
echo "MULTI=$MULTI" >> $FILENAME

res=0

if [ "$SRUN" -eq "1" ]; then
	res=1
else
	res=$(msub -l nodes=$NODES -E flesnetMsub.sh)
fi

echo $res