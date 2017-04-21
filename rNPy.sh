#!/bin/bash
#
# $1 - one of balanced closest multicast
# $2 - number of instances to start
# $3 - command arg to simple_recv
#
# ./rN.sh balanced 5 "-m 1000000"
source ~/bin/dispatch-setup.sh

for ((i=0;i<$2;i++))
do
    python /home/chug/git/qpid-proton/examples/python/simple_recv.py -a 127.0.0.1:5674/q1-$1 "$3" &
    echo "Started python receiver-$1 $i"
done
