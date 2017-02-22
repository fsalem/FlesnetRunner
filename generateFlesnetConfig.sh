FILENAME=$1 # filename of the config file
##echo "2 = $2" 
#IFS=' ' read -ra NODES <<< "$2"
NODES=(${2//;/ }) # name of hosts
#echo "NODES = $NODES"
NINPUT=$4 # number of input nodes
NCOMP=$3 # number of output nodes
BASE_PORT=$5 # base port to start with
USE_VERBS=$6
#echo "NIMPUTS = $NINPUT, NCOMP = $NCOMP"
I=0
echo -e "\n# The list of participating input nodes." > $FILENAME

for NODE in "${NODES[@]}"
do
	#echo "currentnode = $NODE"
	NODE_ADDR=$(host $NODE | awk '/has address/ { print $4 }')
	if [[ "1" -eq $USE_VERBS ]]; then
		NODE_ADDR=$NODE
	fi
	echo "NODE_ADDR=$NODE_ADDR"
	I=$((I+1))
	if [ "$I" -le "$NINPUT" ]; then
		echo "input-nodes = $NODE_ADDR" >> $FILENAME
	else
		echo "compute-nodes = $NODE_ADDR" >> $FILENAME
	fi
	
	if [ "$I" -eq "$NINPUT" ]; then
		echo -e "\n# The list of participating compute nodes." >> $FILENAME
	fi
done
echo -e "\n\n" >> $FILENAME
echo -e "base-port = $BASE_PORT\n\n" >> $FILENAME
cat flesnet.cfg.template >> $FILENAME
