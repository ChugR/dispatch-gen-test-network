dispatch-gen-test-network
=========================

Program to emit configs and scripts to effect:
- Create a test network of routers
- Launch a sender. You can run several of these
- Launch a receiver. You can run several of these

The routers are chained in a line with the sender sending
into the chain at one end and the receivers receiving at the other end.

There may be N routers in the chain

Routers listeners all "look left" for incoming connections.

The first, A:
- opens port 5672 for senders to fill
- opens connector to 21000 to next (B)

The second, B:
- opens interrouter listener on port 21000 for A's interrouter connection
- opens connector to 21002

The third, C:
- opens interrouter listener on port 21001 for B's interrouter connection
- opens connector to 21003

(and so on)

The last, N:
- opens interrouter listener on port 2100x for the interrouter connection
- opens user listener port 5674 for the receivers to drain

It's really convenient if all these ports are available when the scripts are started up, for sure.

Command line
============

python ./gen-test-network.py <number of routers to configure>

What happens
============

- A directory is created to hold all the files. The directory name is a timestamp followed by the number of routers in the chain.
- CD into that directory
- Run the routers: **./run-qdrs.sh**
- In another window run a sender: **./sender-balanced.sh "-m 1000000"**
- In another window run a receiver: **./receiver-balanced.sh "-m 1000000"**

Secret hard-coded names and constants
=====================================

- This code is meant to run on my workstation. It assumes that ports 5672 and 5674 are avauilable and not blocked by firewalls or anything.

- A script is avaliable to set up an environment to run the router code of interest. My development system has script **~/bin/dispatch-setup.sh** and a source code build at **{DEVROOT}/build/router**. You have to adjust these for your setup.

- Linux **perf** utility is installed

- [flamegraph](https://github.com/brendangregg/FlameGraph) is installed

- qpid-proton is installed and the C++ example code senders and receivers are available.

- and probably more
