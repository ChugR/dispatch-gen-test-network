#!/bin/bash

# Run perf on each thread of qdrouterd process
#  Perfs all run as subprocesses.
#  Keeps running until you press Enter
#  Generates perf graph reports on each thread
#
# $1 is the dir to use for files

# set -x

if [ $# -eq 0 ]; then
    echo "Usage: ./run-perf.sh directoryName"
    exit 1
fi

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
top -Hbn1 -p $ROUTERPID > at-begin-top.txt
qdstat -l               > at-begin-qdstat-l.txt
qdstat -a               > at-begin-qdstat-a.txt
qdstat -m               > at-begin-qdstat-m.txt

# Generate perf data files per thread
ps -L --pid $ROUTERPID -o tid= |\
    while read tid
    do
        perf record --tid=$tid --output=A_perf_tid_$tid.data -s -g --per-thread &
        echo "Started perf for thread $tid as process $!"
    done

#
read -p "Perf is collecting data. Press Enter to stop collecting."

#
killall --wait perf

# General thread CPU usage at end
top -Hbn1 -p $ROUTERPID > at-end-top.txt
qdstat -l               > at-end-qdstat-l.txt
qdstat -a               > at-end-qdstat-a.txt
qdstat -m               > at-end-qdstat-m.txt

# Generate call graph perf reports
ps -L --pid $ROUTERPID -o tid= |\
    while read tid
    do
        perf report -g --call-graph --stdio -i A_perf_tid_$tid.data --header > A-perf-graph-tid-$tid.txt
        # A-perf-graph-tid-$tid.txt
        perf report -g --call-graph --stdio -i A_perf_tid_$tid.data --header > TEMP.txt
        # Detect the core/worker threads and name reports separately
        TYPE=work
        if grep -q core_thread TEMP.txt; then
            TYPE=core
        fi
        # Generate flamegraph
        mv TEMP.txt A-perf-graph-$tid-$TYPE.txt
        perf script -i A_perf_tid_$tid.data | stackcollapse-perf.pl > A_stackcollapse-perf_$tid_$TYPE.tmp
        flamegraph.pl  A_stackcollapse-perf_$tid_$TYPE.tmp >  A_flamegraph_$tid_$TYPE.svg
        
        echo "Thread reports saved in A-perf-graph-tid-$tid.txt and A_flamegraph_$tid_$TYPE.svg"
    done

#
popd

exit 0
