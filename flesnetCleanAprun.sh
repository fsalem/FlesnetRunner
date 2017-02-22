#!/bin/bash

p=$(ps aux | grep flesnet)
i=0
while [[ $p ]]
do
sleep 5
p=$(ps aux | grep flesnet)
i=$((i+1))
if (( $i == 15 )) ; then
break
fi
done

killall -9 flesnet
killall -9 tsclient
wait
