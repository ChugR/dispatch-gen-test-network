#!/bin/bash

# Run perf on each thread of qdrouterd process
#
# $1 is the dir to use for files
#
#  Perfs all run as subprocesses.
#  Keeps running until you press Enter
#  Generates perf call graph reports on each thread
#  Generates flamegraph (https://github.com/brendangregg/FlameGraph)
#   reports on threads, aggregated worker threads, aggregated router.
#  Aggregation plan:
#
#   core_thread -------------\
#   worker 1 \               | ROUTER
#   worker 2 |   AllWorkers  +----------
#   ,,,      +---------------/
#   worker N /

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

# Create empty all-workers stack-collapse
rm    ./ALL-STACKS.txt 2>/dev/null
touch ./ALL-STACKS.txt
        
# Generate call graph perf reports
ps -L --pid $ROUTERPID -o tid= |\
    while read tid
    do
        # Generate per-thread call graph as text file
        perf report -i ./A_perf_tid_$tid.data --header -g --call-graph --stdio > ./CALL-GRAPH.txt

        # Generate per-thread stack-collapse
        perf script -i ./A_perf_tid_$tid.data | stackcollapse-perf.pl > ./STACK-COLLAPSE.txt

        # Detect the core/worker threads. Concatenate all worker thread stacks
        if grep -q core_thread CALL-GRAPH.txt; then
            TYPE=core
        else
            TYPE=work
            cat ./STACK-COLLAPSE.txt >> ./ALL-STACKS.txt
        fi

        # Generate flamegraph
        title="$DIRECTORY - $TYPE thread $tid"
        flamegraph.pl  --title "${title}" --width 1800 ./STACK-COLLAPSE.txt >  ./FLAMEGRAPH.svg

        # Rename per-thread files to target
        mv CALL-GRAPH.txt     A-perf-call-graph-${tid}-${TYPE}.txt
        mv STACK-COLLAPSE.txt A-stack-collapse-${tid}-${TYPE}.txt
        mv FLAMEGRAPH.svg     A-perf-flamegraph-${tid}-${TYPE}.svg

        echo "Thread $tid reports saved in A-perf-call-graph-${tid}-${TYPE}.txt and A-perf-flamegraph-${tid}-${TYPE}.svg"
    done

# Generate all-worker flamegraph
title="$DIRECTORY - All worker threads"
flamegraph.pl           --title "${title}" --width 1800 ./ALL-STACKS.txt > ./ALL-WORKERS.svg
flamegraph.pl --reverse --title "${title}" --width 1800 ./ALL-STACKS.txt > ./ALL-WORKERS-reverse.svg

# Generate entire router flamegraph
title="$DIRECTORY - Whole router - all threads"
cat ALL-STACKS.txt A-stack-collapse*-core.txt > ROUTER-stack-collapse.txt
flamegraph.pl            --title "${title}" --width 1800 ROUTER-stack-collapse.txt > ROUTER.svg
flamegraph.pl --reverse  --title "${title}" --width 1800 ROUTER-stack-collapse.txt > ROUTER-reverse.svg

#
popd

exit 0
