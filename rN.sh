#!/bin/bash
#
# $1 - one of balanced closest multicast
# $2 - number of instances to start
# $3 - command arg to simple_recv
#
# ./rN.sh balanced 5 "-m 1000000"

for ((i=0;i<$2;i++))
do
    ./receiver-$1.sh "$3" &
    echo "Started receiver-$1 $i"
done
