#!/bin/bash

# Environment for python/proton/n/stuff
source ~/bin/dispatch-setup.sh
for i in {0..10}
do
    /home/chug/git/qpid-proton/build/examples/cpp/simple_recv -a amqp://127.0.0.1:5674/q1-balanced $1 &
    echo "Started receiver $i"
done
