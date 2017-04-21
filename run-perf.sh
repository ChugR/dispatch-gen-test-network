#!/bin/bash

# Run perf on each thread of qdrouterd process
#  Perfs all run as subprocesses.
#  Keeps running until you press Enter
#  Generates perf graph reports on each thread
#
# $1 is the dir to use for files

DIRECTORY=$1
ROUTERPID=$(pidof qdrouterd)

# Get into fresh working folder
if [ -d "$DIRECTORY" ]; then
    echo "Directory $DIRECTORY already exists. Sorry."
    exit 1
fi

mkdir $DIRECTORY
pushd $DIRECTORY

# General thread CPU usage at beginning
top -Hbn1 -p $ROUTERPID > top-beginning.txt

# Generate perf data files per thread
ps -L --pid $ROUTERPID -o tid= |\
    while read tid
    do
        perf record --tid=$tid --output=A_perf_tid_$tid.data -s -g --per-thread &
        echo "Started perf for thread $tid as process $!"
    done

#
read -p "Press enter to continue"

#
killall --wait perf

# General thread CPU usage at end
top -Hbn1 -p $ROUTERPID > top-end.txt

# Analyze data files into text
ps -L --pid $ROUTERPID -o tid= |\
    while read tid
    do
        perf report -g --call-graph --stdio -i A_perf_tid_$tid.data --header > A-perf-graph-tid-$tid.txt
        echo "Thread report saved in A-perf-graph-tid-$tid.txt"
    done

#
popd
